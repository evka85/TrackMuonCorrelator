------------------------------------------------------------------------------------------------------------------------------------------------------
-- Company: TAMU
-- Engineer: Evaldas Juska (evaldas.juska@cern.ch, evka85@gmail.com)
-- 
-- Create Date:    02:35 2016-05-31
-- Module Name:    link_gbt_rx
-- Description:    this module provides GBT RX link encoding
------------------------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.gem_pkg.all;

entity link_gbt_tx is
port(

    ttc_clk_40_i            : in std_logic;    
    reset_i                 : in std_logic;    
    
    vfat2_t1_i              : in t_t1;
    
    req_en_o                : out std_logic;
    req_valid_i             : in std_logic;
    req_data_i              : in std_logic_vector(64 downto 0);
    
    gbt_tx_data_o           : out std_logic_vector(83 downto 0);
    gbt_tx_sync_pattern_i   : in std_logic_vector(15 downto 0);
    gbt_rx_sync_done_i      : in std_logic
    
);
end link_gbt_tx;

architecture link_gbt_tx_arch of link_gbt_tx is    

    type state_t is (SYNC, SYNC_DONE, FRAME_BEGIN, ADDR_1, ADDR_2, DATA_0, DATA_1, DATA_2, FRAME_END);
    
    signal state        : state_t;
    
    signal req_valid    : std_logic;
    signal req_data     : std_logic_vector(64 downto 0);

begin  

    --== STATE ==--

    process(ttc_clk_40_i)
        variable sync_done_cnt : integer range 0 to 10 := 0;
    begin
        if (rising_edge(ttc_clk_40_i)) then
            if (reset_i = '1') then
                state <= SYNC;
                sync_done_cnt := 0;
            else
                if (gbt_rx_sync_done_i = '0') then
                    state <= SYNC; -- go to sync state if rx is not synced (e.g. if we lost connection)
                    sync_done_cnt := 0;
                else
                    case state is
                        when SYNC        => state <= SYNC_DONE;
                        when SYNC_DONE   =>
                            -- keep it in SYNC_DONE for 5 clock cycles
                            if sync_done_cnt >= 5 then
                                state <= FRAME_BEGIN;
                            else
                                state <= SYNC_DONE;
                                sync_done_cnt := sync_done_cnt + 1;
                            end if;
                        when FRAME_BEGIN => state <= ADDR_1;
                        when ADDR_1      => state <= ADDR_2;
                        when ADDR_2      => state <= DATA_0;
                        when DATA_0      => state <= DATA_1;
                        when DATA_1      => state <= DATA_2;
                        when DATA_2      => state <= FRAME_END;
                        when FRAME_END   => state <= FRAME_BEGIN;
                        when others      => state <= FRAME_BEGIN;
                    end case;
                end if;
            end if;
        end if;
    end process;

    --== REQUEST ==--

    -- pop the request from the fifo
    process(ttc_clk_40_i)
    begin
        if (rising_edge(ttc_clk_40_i)) then
            if (reset_i = '1') then
                req_en_o <= '0';
                req_valid <= '0';
                req_data <= (others => '0');
            else
                case state is   
                    when FRAME_END => 
                        req_en_o <= '0';
                        req_valid <= req_valid_i;
                        req_data <= req_data_i;
                    when DATA_1 => req_en_o <= '1';
                    when others => req_en_o <= '0';
                end case;
            end if;
        end if;
    end process; 
        
    --== SEND ==--    
    
    process(ttc_clk_40_i)
    begin
        if (rising_edge(ttc_clk_40_i)) then
            if (reset_i = '1') then
                gbt_tx_data_o <= (others => '0');
            else
                
                -- whatever the state, the top 4 bits of elink 1 are reserved for TTC
                gbt_tx_data_o(47 downto 44) <= vfat2_t1_i.lv1a & vfat2_t1_i.bc0 & vfat2_t1_i.resync & vfat2_t1_i.calpulse;
                
                case state is
                    when SYNC =>
                        -- note that this also overrides the TTC bits
                        gbt_tx_data_o(47 downto 32) <= gbt_tx_sync_pattern_i;
                    when SYNC_DONE =>
                        gbt_tx_data_o(47 downto 32) <= not gbt_tx_sync_pattern_i;
                    when FRAME_BEGIN => 
                        gbt_tx_data_o(43 downto 40) <= req_valid & req_data(64) & "00";
                        gbt_tx_data_o(39 downto 32) <= req_data(63 downto 56);
                    when ADDR_1 =>  
                        gbt_tx_data_o(43 downto 32) <= req_data(55 downto 44);
                    when ADDR_2 => 
                        gbt_tx_data_o(43 downto 32) <= req_data(43 downto 32);
                    when DATA_0 => 
                        gbt_tx_data_o(43 downto 40) <= "0000";
                        gbt_tx_data_o(39 downto 32) <= req_data(31 downto 24);
                    when DATA_1 => 
                        gbt_tx_data_o(43 downto 32) <= req_data(23 downto 12);
                    when DATA_2 => 
                        gbt_tx_data_o(43 downto 32) <= req_data(11 downto 0);
                    when FRAME_END =>
                        gbt_tx_data_o(43 downto 32) <= x"ABC";
                    when others => 
                        gbt_tx_data_o(43 downto 32) <= x"000";
                end case;
            end if;
        end if;
    end process;   
    
end link_gbt_tx_arch;
