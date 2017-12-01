------------------------------------------------------------------------------------------------------------------------------------------------------
-- Company: TAMU
-- Engineer: Evaldas Juska (evaldas.juska@cern.ch, evka85@gmail.com)
-- 
-- Create Date:    00:01 2016-05-10
-- Module Name:    link_rx_trigger
-- Description:    This module takes two GTX/GTH trigger RX links and outputs sbit cluster data synchronous to the TTC clk  
------------------------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.gem_pkg.all;

entity link_rx_trigger is
port(
    ttc_clk_i           : in  std_logic;
    reset_i             : in  std_logic;
    
    gt_rx_trig_usrclk_i : in  std_logic;
    rx_kchar_i          : in std_logic_vector(1 downto 0);
    rx_data_i           : in std_logic_vector(15 downto 0);
    
    sbit_cluster0_o     : out t_sbit_cluster;
    sbit_cluster1_o     : out t_sbit_cluster;
    sbit_cluster2_o     : out t_sbit_cluster;
    sbit_cluster3_o     : out t_sbit_cluster;
    link_status_o       : out t_sbit_link_status
);
end link_rx_trigger;

architecture Behavioral of link_rx_trigger is    

    component sbit_cluster_fifo is
        port(
            rst         : IN  STD_LOGIC;
            wr_clk      : IN  STD_LOGIC;
            rd_clk      : IN  STD_LOGIC;
            din         : IN  STD_LOGIC_VECTOR(58 DOWNTO 0);
            wr_en       : IN  STD_LOGIC;
            rd_en       : IN  STD_LOGIC;
            dout        : OUT STD_LOGIC_VECTOR(58 DOWNTO 0);
            full        : OUT STD_LOGIC;
            almost_full : OUT STD_LOGIC;
            empty       : OUT STD_LOGIC;
            valid       : OUT STD_LOGIC;
            underflow   : OUT STD_LOGIC
        );
    end component sbit_cluster_fifo;

    type state_t is (COMMA, DATA_0, DATA_1, DATA_2);    
    
    signal state                : state_t := COMMA;
    signal reset_done           : std_logic := '0'; -- asserted after the first comma after the reset    
    signal missed_comma_err     : std_logic := '0'; -- asserted if a comma character is not found when FSM is in COMMA state

    signal fifo_we              : std_logic := '0';
    signal fifo_re              : std_logic := '0';
    signal fifo_din             : std_logic_vector(58 downto 0) := (others => '0');
    signal fifo_dout            : std_logic_vector(58 downto 0);
    signal fifo_almost_full     : std_logic;

begin  

    --== FSM STATE ==--

    process(gt_rx_trig_usrclk_i)
    begin
        if (rising_edge(gt_rx_trig_usrclk_i)) then
            if (reset_i = '1') then
                state <= COMMA;
            else
                case state is
                    when COMMA =>
                        if (rx_kchar_i(1 downto 0) = "01" and rx_data_i(7 downto 0) = x"BC") then
                            state <= DATA_0;
                        end if;
                    when DATA_0 => state <= DATA_1;
                    when DATA_1 => state <= DATA_2;
                    when DATA_2 => state <= COMMA;
                    when others => state <= COMMA;
                end case;
            end if;
        end if;
    end process;
    
    --== FSM LOGIC ==--

    process(gt_rx_trig_usrclk_i)
    begin
        if (rising_edge(gt_rx_trig_usrclk_i)) then
            if (reset_i = '1') then
                reset_done <= '0';
                missed_comma_err <= '0';
                fifo_re <= '0';
            else
                case state is
                    when COMMA =>
                        fifo_we <= '0';
                        if (rx_kchar_i(1 downto 0) = "01" and rx_data_i(7 downto 0) = x"BC") then
                            reset_done <= '1';
                            if (fifo_we = '1') then
                                missed_comma_err <= '0'; -- deassert it only if it's the first clock we're in the COMMA state
                            end if;
                            fifo_din(7 downto 0) <= rx_data_i(15 downto 8);
                        elsif (reset_done = '1') then
                            missed_comma_err <= '1';
                        end if;
                    when DATA_0 =>
                        fifo_din(23 downto 8) <= rx_data_i(15 downto 0);
                    when DATA_1 =>
                        fifo_din(39 downto 24) <= rx_data_i(15 downto 0);
                    when DATA_2 =>
                        fifo_we <= '1';
                        fifo_re <= '1';
                        fifo_din(55 downto 40) <= rx_data_i(15 downto 0);
                        fifo_din(56) <= missed_comma_err;
                        fifo_din(57) <= fifo_almost_full;
                        fifo_din(58) <= '0'; -- will be used for sync character
                    when others =>
                        fifo_we <= '0';
                end case;
            end if;
        end if;
    end process;

    --== Sync FIFO ==--
    
    i_sync_fifo : component sbit_cluster_fifo
        port map(
            rst         => reset_i,
            wr_clk      => gt_rx_trig_usrclk_i,
            rd_clk      => ttc_clk_i,
            din         => fifo_din,
            wr_en       => fifo_we,
            rd_en       => fifo_re,
            dout        => fifo_dout,
            full        => open,
            almost_full => fifo_almost_full,
            empty       => open,
            valid       => link_status_o.valid,
            underflow   => link_status_o.underflow
        );
    
    link_status_o.missed_comma  <= fifo_dout(56);
    link_status_o.overflow      <= fifo_dout(57);
    link_status_o.sync_word     <= fifo_dout(58);
    
    sbit_cluster0_o.size     <= fifo_dout(13 downto 11);
    sbit_cluster0_o.address  <= fifo_dout(10 downto  0);
    sbit_cluster1_o.size     <= fifo_dout(27 downto 25);
    sbit_cluster1_o.address  <= fifo_dout(24 downto 14);
    sbit_cluster2_o.size     <= fifo_dout(41 downto 39);
    sbit_cluster2_o.address  <= fifo_dout(38 downto 28);
    sbit_cluster3_o.size     <= fifo_dout(55 downto 53);
    sbit_cluster3_o.address  <= fifo_dout(52 downto 42);
    
end Behavioral;
