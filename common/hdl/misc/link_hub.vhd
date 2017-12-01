------------------------------------------------------------------------------------------------------------------------------------------------------
-- Company: TAMU
-- Engineer: Evaldas Juska (evaldas.juska@cern.ch, evka85@gmail.com)
-- 
-- Create Date:    13:45:00 2016-09-21
-- Module Name:    LINK_HUB
-- Description:    This module is used to synchronize the 8b10b links to TTC clock and direct them to either to the OH modules (standard operation) or to the GEM_TESTS module  
------------------------------------------------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ttc_pkg.all;
use work.gem_pkg.all;

entity link_hub is
    generic(
        g_NUM_OF_OHs    : integer;
        g_USE_GBT       : boolean := true  -- if this is true, GBT links will be used for communicationa with OH, if false 3.2Gbs 8b10b links will be used instead (remember to instanciate the correct links!)
    );
    port(
        -- Resets
        reset_i                     : in std_logic;
                
        -- clocks
        ttc_clks_i                  : in  t_ttc_clks;

        gt_8b10b_rx_usrclk_i        : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gt_8b10b_tx_usrclk_i        : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gt_trig0_rx_usrclk_i        : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gt_trig1_rx_usrclk_i        : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        
        -- links
        gt_8b10b_rx_data_arr_i      : in  t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        gt_8b10b_tx_data_arr_o      : out t_gt_8b10b_tx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        gt_trig0_rx_data_arr_i      : in  t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        gt_trig1_rx_data_arr_i      : in  t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        
        -- from OHv2
        oh_link_tk_error_arr_i      : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        oh_link_evt_rcvd_arr_i      : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        
        -- status
        link_status_arr_o           : out t_oh_link_status_arr(g_NUM_OF_OHs - 1 downto 0);
                
        -- configuration
        daq_link_test_mode_i        : in std_logic;
        trig_link_test_mode_i       : in std_logic;
        
        -- to OHv2
        oh_8b10b_rx_data_arr_o      : out t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        oh_8b10b_tx_data_arr_i      : in  t_gt_8b10b_tx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        oh_trig0_rx_data_arr_o      : out t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        oh_trig1_rx_data_arr_o      : out t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        
        -- to tests module
        tst_8b10b_rx_data_arr_o     : out t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        tst_8b10b_tx_data_arr_i     : in  t_gt_8b10b_tx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        tst_trig0_rx_data_arr_o     : out t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        tst_trig1_rx_data_arr_o     : out t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0)
    );
end link_hub;

architecture Behavioral of link_hub is

    COMPONENT sync_fifo_8b10b_16
        PORT(
            rst       : IN  STD_LOGIC;
            wr_clk    : IN  STD_LOGIC;
            rd_clk    : IN  STD_LOGIC;
            din       : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
            wr_en     : IN  STD_LOGIC;
            rd_en     : IN  STD_LOGIC;
            dout      : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
            full      : OUT STD_LOGIC;
            overflow  : OUT STD_LOGIC;
            empty     : OUT STD_LOGIC;
            valid     : OUT STD_LOGIC;
            underflow : OUT STD_LOGIC
        );
    END COMPONENT;

    --== Tracking sync FIFOs ==--

    signal sync_tk_rx_din_arr   : t_std24_array(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tk_rx_dout_arr  : t_std24_array(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tk_rx_ovf_arr   : std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tk_rx_unf_arr   : std_logic_vector(g_NUM_OF_OHs - 1 downto 0);

    signal sync_tk_tx_din_arr   : t_std24_array(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tk_tx_dout_arr  : t_std24_array(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tk_tx_ovf_arr   : std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tk_tx_unf_arr   : std_logic_vector(g_NUM_OF_OHs - 1 downto 0);

    --== Trigger RX sync FIFOs ==--

    signal sync_tr0_rx_din_arr  : t_std24_array(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tr0_rx_dout_arr : t_std24_array(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tr0_rx_ovf_arr  : std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tr0_rx_unf_arr  : std_logic_vector(g_NUM_OF_OHs - 1 downto 0);

    signal sync_tr1_rx_din_arr  : t_std24_array(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tr1_rx_dout_arr : t_std24_array(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tr1_rx_ovf_arr  : std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
    signal sync_tr1_rx_unf_arr  : std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
    
    --== Other ==--
    signal gt_8b10b_tx_data_arr : t_gt_8b10b_tx_data_arr(g_NUM_OF_OHs - 1 downto 0);
    signal link_status_arr      : t_oh_link_status_arr(g_NUM_OF_OHs - 1 downto 0);
    signal tied_to_ground       : std_logic;

begin

    gt_8b10b_tx_data_arr_o <= gt_8b10b_tx_data_arr;
    --link_status_arr_o <= link_status_arr;
    tied_to_ground <= '0';

    --==== Transfet to TTC clock domain (sync fifos) ====--

    g_sync_fifos : for i in 0 to g_NUM_OF_OHs - 1 generate

        g_8b10b_link_option : if not g_USE_GBT generate
            
            --- Tracking / Control RX link
            sync_tk_rx_din_arr(i) <= gt_8b10b_rx_data_arr_i(i).rxdisperr(1 downto 0) & gt_8b10b_rx_data_arr_i(i).rxnotintable(1 downto 0) & gt_8b10b_rx_data_arr_i(i).rxchariscomma(1 downto 0) & gt_8b10b_rx_data_arr_i(i).rxcharisk(1 downto 0) & gt_8b10b_rx_data_arr_i(i).rxdata(15 downto 0);
            i_sync_rx_tracking : component sync_fifo_8b10b_16
                port map(
                    rst       => reset_i,
                    wr_clk    => gt_8b10b_rx_usrclk_i(i),
                    rd_clk    => ttc_clks_i.clk_160,
                    din       => sync_tk_rx_din_arr(i),
                    wr_en     => '1',
                    rd_en     => '1',
                    dout      => sync_tk_rx_dout_arr(i),
                    full      => open,
                    overflow  => sync_tk_rx_ovf_arr(i),
                    empty     => open,
                    valid     => open,
                    underflow => sync_tk_rx_unf_arr(i)
                );
        
            ---==== Tracking / Control TX link ====---
            i_sync_tx_tracking : component sync_fifo_8b10b_16
                port map(
                    rst       => reset_i,
                    wr_clk    => ttc_clks_i.clk_160,
                    rd_clk    => gt_8b10b_tx_usrclk_i(i),
                    din       => sync_tk_tx_din_arr(i),
                    wr_en     => '1',
                    rd_en     => '1',
                    dout      => sync_tk_tx_dout_arr(i),
                    full      => open,
                    overflow  => sync_tk_tx_ovf_arr(i),
                    empty     => open,
                    valid     => open,
                    underflow => sync_tk_tx_unf_arr(i)
                );
                
            gt_8b10b_tx_data_arr(i).txdata(15 downto 0) <= sync_tk_tx_dout_arr(i)(15 downto 0);
            gt_8b10b_tx_data_arr(i).txcharisk(1 downto 0) <= sync_tk_tx_dout_arr(i)(17 downto 16);
            
            -- Link status    
            link_status_arr_o(i).tk_tx_sync_status.ovf <= sync_tk_tx_ovf_arr(i);
            link_status_arr_o(i).tk_tx_sync_status.unf <= sync_tk_tx_unf_arr(i);
            link_status_arr_o(i).tk_rx_sync_status.ovf <= sync_tk_rx_ovf_arr(i);
            link_status_arr_o(i).tk_rx_sync_status.unf <= sync_tk_rx_unf_arr(i);
        
            link_status_arr_o(i).tk_rx_gt_status.not_in_table  <= sync_tk_rx_dout_arr(i)(21)  or sync_tk_rx_dout_arr(i)(20);
            link_status_arr_o(i).tk_rx_gt_status.disperr       <= sync_tk_rx_dout_arr(i)(23)  or sync_tk_rx_dout_arr(i)(22);
        
            -- MUX
            oh_8b10b_rx_data_arr_o(i).rxdata(15 downto 0) <= sync_tk_rx_dout_arr(i)(15 downto 0) when daq_link_test_mode_i = '0' else (others => '0');
            oh_8b10b_rx_data_arr_o(i).rxcharisk(1 downto 0) <= sync_tk_rx_dout_arr(i)(17 downto 16) when daq_link_test_mode_i = '0' else (others => '0');
            oh_8b10b_rx_data_arr_o(i).rxchariscomma(1 downto 0) <= sync_tk_rx_dout_arr(i)(19 downto 18) when daq_link_test_mode_i = '0' else (others => '0');
            tst_8b10b_rx_data_arr_o(i).rxdata(15 downto 0) <= sync_tk_rx_dout_arr(i)(15 downto 0) when daq_link_test_mode_i = '1' else (others => '0');
            tst_8b10b_rx_data_arr_o(i).rxcharisk(1 downto 0) <= sync_tk_rx_dout_arr(i)(17 downto 16) when daq_link_test_mode_i = '1' else (others => '0');
            tst_8b10b_rx_data_arr_o(i).rxchariscomma(1 downto 0) <= sync_tk_rx_dout_arr(i)(19 downto 18) when daq_link_test_mode_i = '1' else (others => '0');
        
            sync_tk_tx_din_arr(i) <= "000000" & oh_8b10b_tx_data_arr_i(i).txcharisk(1 downto 0) & oh_8b10b_tx_data_arr_i(i).txdata(15 downto 0)
                                      when daq_link_test_mode_i = '0'
                                      else "000000" & tst_8b10b_tx_data_arr_i(i).txcharisk(1 downto 0) & tst_8b10b_tx_data_arr_i(i).txdata(15 downto 0);
                            
        end generate;
        
        g_gbt_link_option : if g_USE_GBT generate

            oh_8b10b_rx_data_arr_o(i).rxdata(15 downto 0) <= (others => '0');
            oh_8b10b_rx_data_arr_o(i).rxcharisk(1 downto 0) <= (others => '0');
            oh_8b10b_rx_data_arr_o(i).rxchariscomma(1 downto 0) <= (others => '0');
            tst_8b10b_rx_data_arr_o(i).rxdata(15 downto 0) <= (others => '0');
            tst_8b10b_rx_data_arr_o(i).rxcharisk(1 downto 0) <= (others => '0');
            tst_8b10b_rx_data_arr_o(i).rxchariscomma(1 downto 0) <= (others => '0');

            gt_8b10b_tx_data_arr(i).txdata(15 downto 0) <= (others => '0');
            gt_8b10b_tx_data_arr(i).txcharisk(1 downto 0) <= (others => '0');

            link_status_arr_o(i).tk_tx_sync_status.ovf <= tied_to_ground;
            link_status_arr_o(i).tk_tx_sync_status.unf <= tied_to_ground;
            link_status_arr_o(i).tk_rx_sync_status.ovf <= tied_to_ground;
            link_status_arr_o(i).tk_rx_sync_status.unf <= tied_to_ground;
        
            link_status_arr_o(i).tk_rx_gt_status.not_in_table  <= tied_to_ground;
            link_status_arr_o(i).tk_rx_gt_status.disperr       <= tied_to_ground;
                        
        end generate;
        
        ---==== Trigger link 0 ====---
        sync_tr0_rx_din_arr(i) <= gt_trig0_rx_data_arr_i(i).rxdisperr(1 downto 0) & gt_trig0_rx_data_arr_i(i).rxnotintable(1 downto 0) & gt_trig0_rx_data_arr_i(i).rxchariscomma(1 downto 0) & gt_trig0_rx_data_arr_i(i).rxcharisk(1 downto 0) & gt_trig0_rx_data_arr_i(i).rxdata(15 downto 0);
        i_sync_rx_trig0 : component sync_fifo_8b10b_16
            port map(
                rst       => reset_i,
                wr_clk    => gt_trig0_rx_usrclk_i(i),
                rd_clk    => ttc_clks_i.clk_160,
                din       => sync_tr0_rx_din_arr(i),
                wr_en     => '1',
                rd_en     => '1',
                dout      => sync_tr0_rx_dout_arr(i),
                full      => open,
                overflow  => sync_tr0_rx_ovf_arr(i),
                empty     => open,
                valid     => open,
                underflow => sync_tr0_rx_unf_arr(i)
            );
    
        ---==== Trigger link 1 ====---
        sync_tr1_rx_din_arr(i) <= gt_trig1_rx_data_arr_i(i).rxdisperr(1 downto 0) & gt_trig1_rx_data_arr_i(i).rxnotintable(1 downto 0) & gt_trig1_rx_data_arr_i(i).rxchariscomma(1 downto 0) & gt_trig1_rx_data_arr_i(i).rxcharisk(1 downto 0) & gt_trig1_rx_data_arr_i(i).rxdata(15 downto 0);
        i_sync_rx_trig1 : component sync_fifo_8b10b_16
            port map(
                rst       => reset_i,
                wr_clk    => gt_trig1_rx_usrclk_i(i),
                rd_clk    => ttc_clks_i.clk_160,
                din       => sync_tr1_rx_din_arr(i),
                wr_en     => '1',
                rd_en     => '1',
                dout      => sync_tr1_rx_dout_arr(i),
                full      => open,
                overflow  => sync_tr1_rx_ovf_arr(i),
                empty     => open,
                valid     => open,
                underflow => sync_tr1_rx_unf_arr(i)
            );
        
        link_status_arr_o(i).tr0_rx_sync_status.ovf <= sync_tr0_rx_ovf_arr(i);
        link_status_arr_o(i).tr0_rx_sync_status.unf <= sync_tr0_rx_unf_arr(i);
        link_status_arr_o(i).tr1_rx_sync_status.ovf <= sync_tr1_rx_ovf_arr(i);
        link_status_arr_o(i).tr1_rx_sync_status.unf <= sync_tr1_rx_unf_arr(i);
        link_status_arr_o(i).tr0_rx_gt_status.not_in_table <= sync_tr0_rx_dout_arr(i)(21) or sync_tr0_rx_dout_arr(i)(20);
        link_status_arr_o(i).tr0_rx_gt_status.disperr      <= sync_tr0_rx_dout_arr(i)(23) or sync_tr0_rx_dout_arr(i)(22);
        link_status_arr_o(i).tr1_rx_gt_status.not_in_table <= sync_tr1_rx_dout_arr(i)(21) or sync_tr1_rx_dout_arr(i)(20);
        link_status_arr_o(i).tr1_rx_gt_status.disperr      <= sync_tr1_rx_dout_arr(i)(23) or sync_tr1_rx_dout_arr(i)(22);
        
        link_status_arr_o(i).tk_error <= oh_link_tk_error_arr_i(i) when daq_link_test_mode_i = '0' else '0';
        link_status_arr_o(i).evt_rcvd <= oh_link_evt_rcvd_arr_i(i) when daq_link_test_mode_i = '0' else '0';
        
        oh_trig0_rx_data_arr_o(i).rxdata(15 downto 0) <= sync_tr0_rx_dout_arr(i)(15 downto 0) when trig_link_test_mode_i = '0' else (others => '0');
        oh_trig0_rx_data_arr_o(i).rxcharisk(1 downto 0) <= sync_tr0_rx_dout_arr(i)(17 downto 16) when trig_link_test_mode_i = '0' else (others => '0');
        oh_trig0_rx_data_arr_o(i).rxchariscomma(1 downto 0) <= sync_tr0_rx_dout_arr(i)(19 downto 18) when trig_link_test_mode_i = '0' else (others => '0');
        oh_trig1_rx_data_arr_o(i).rxdata(15 downto 0) <= sync_tr1_rx_dout_arr(i)(15 downto 0) when trig_link_test_mode_i = '0' else (others => '0');
        oh_trig1_rx_data_arr_o(i).rxcharisk(1 downto 0) <= sync_tr1_rx_dout_arr(i)(17 downto 16) when trig_link_test_mode_i = '0' else (others => '0');
        oh_trig1_rx_data_arr_o(i).rxchariscomma(1 downto 0) <= sync_tr1_rx_dout_arr(i)(19 downto 18) when trig_link_test_mode_i = '0' else (others => '0');

        tst_trig0_rx_data_arr_o(i).rxdata(15 downto 0) <= sync_tr0_rx_dout_arr(i)(15 downto 0) when trig_link_test_mode_i = '1' else (others => '0');
        tst_trig0_rx_data_arr_o(i).rxcharisk(1 downto 0) <= sync_tr0_rx_dout_arr(i)(17 downto 16) when trig_link_test_mode_i = '1' else (others => '0');
        tst_trig0_rx_data_arr_o(i).rxchariscomma(1 downto 0) <= sync_tr0_rx_dout_arr(i)(19 downto 18) when trig_link_test_mode_i = '1' else (others => '0');
        tst_trig1_rx_data_arr_o(i).rxdata(15 downto 0) <= sync_tr1_rx_dout_arr(i)(15 downto 0) when trig_link_test_mode_i = '1' else (others => '0');
        tst_trig1_rx_data_arr_o(i).rxcharisk(1 downto 0) <= sync_tr1_rx_dout_arr(i)(17 downto 16) when trig_link_test_mode_i = '1' else (others => '0');
        tst_trig1_rx_data_arr_o(i).rxchariscomma(1 downto 0) <= sync_tr1_rx_dout_arr(i)(19 downto 18) when trig_link_test_mode_i = '1' else (others => '0');
        
    end generate;

end Behavioral;
