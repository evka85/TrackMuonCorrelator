----------------------------------------------------------------------------------
-- Company: Warsaw University of Technology
-- Engineer: Adrian Byszuk
-- 
-- Create Date: 24.09.2014 15:30:56
-- Design Name: 
-- Module Name: axi_to_ipbus - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: AXI Slave to IPbus Master bridge
-- 
-- Dependencies: IPbus package library
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ipbus.all;

entity axi_to_ipbus is
    Port (
    -- Slave AXI peripheral ports
        s_aclk : IN STD_LOGIC;
        s_aresetn : IN STD_LOGIC;
        s_axi_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_awvalid : IN STD_LOGIC;
        s_axi_awready : OUT STD_LOGIC;
        s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        s_axi_wlast : IN STD_LOGIC;
        s_axi_wvalid : IN STD_LOGIC;
        s_axi_wready : OUT STD_LOGIC;
        s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_bvalid : OUT STD_LOGIC;
        s_axi_bready : IN STD_LOGIC;
        s_axi_araddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s_axi_arvalid : IN STD_LOGIC;
        s_axi_arready : OUT STD_LOGIC;
        s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s_axi_rlast : OUT STD_LOGIC;
        s_axi_rvalid : OUT STD_LOGIC;
        s_axi_rready : IN STD_LOGIC;
    -- Master IPbus ports
        ipb_clk: out std_logic; -- IPbus clock
        rst_ipb: in std_logic; -- IPbus clock domain sync reset
        ipb_out: out ipb_wbus := IPB_WBUS_NULL; -- IPbus bus signals
        ipb_in: in ipb_rbus
     );
end axi_to_ipbus;

architecture Behavioral of axi_to_ipbus is

attribute mark_debug: string;

signal reset : std_logic;

type bus_state_t is (IDLE, WRITE, READ, WR_ACK);
signal bus_state : bus_state_t := IDLE;

signal addr : unsigned(31 downto 0);
signal rd_cnt : unsigned(7 downto 0);

begin

ipb_clk <= s_aclk;
reset <= not(s_aresetn) or rst_ipb;

process(s_aclk)
begin
    if rising_edge(s_aclk) then
        if reset = '1' then
            s_axi_awready <= '0';
            s_axi_bresp <= "00";
            s_axi_bvalid <= '0';
            s_axi_rresp <= "00";
            s_axi_arready <= '0';
            bus_state <= IDLE;
        else
            s_axi_awready <= '0';
            s_axi_bresp <= "00";
            s_axi_bvalid <= '0';
            s_axi_rresp <= "00";
            s_axi_arready <= '0';
            --This bridge doesn't support error handling yet!!!
            case bus_state is
            when IDLE =>
                s_axi_awready <= '1';
                s_axi_arready <= '1';
                if s_axi_awvalid = '1' then
                    s_axi_awready <= '0';
                    s_axi_arready <= '0';
                    addr <= unsigned(s_axi_awaddr);
                    bus_state <= WRITE;
                elsif s_axi_arvalid = '1' then
                    s_axi_awready <= '0';
                    s_axi_arready <= '0';
                    addr <= unsigned(s_axi_araddr);
                    rd_cnt <= unsigned(s_axi_arlen);
                    bus_state <= READ;
                end if;
            when WRITE =>
                if s_axi_wvalid = '1' and ipb_in.ipb_ack = '1' then
                    addr <= addr + 1;
                    if s_axi_wlast = '1' then
                        bus_state <= WR_ACK;
                    end if;
                end if;              
            when READ =>
                if s_axi_rready = '1' and ipb_in.ipb_ack = '1' then
                    rd_cnt <= rd_cnt - 1;
                    addr <= addr + 1;
                    if rd_cnt = 0 then
                        s_axi_rresp <= "00"; --OK
                        bus_state <= IDLE;
                    end if;
                end if;
            when WR_ACK =>
                s_axi_bresp <= "00";
                s_axi_bvalid <= '1';
                bus_state <= IDLE;
            end case;
        end if;
    end if;
end process;

ipb_out.ipb_wdata <= s_axi_wdata;
ipb_out.ipb_addr <= std_logic_vector(addr);
ipb_out.ipb_strobe <= s_axi_wvalid when (bus_state = WRITE) else
                s_axi_rready when (bus_state = READ) else
                '0';
ipb_out.ipb_write <= '1' when (bus_state = WRITE) else '0';
s_axi_wready <= ipb_in.ipb_ack when (bus_state = WRITE) else '0';

s_axi_rdata <= ipb_in.ipb_rdata;
s_axi_rvalid <= ipb_in.ipb_ack when (bus_state = READ) else '0';
s_axi_rlast <= ipb_in.ipb_ack when (bus_state = READ and rd_cnt = 0) else '0';

end Behavioral;
