------------------------------------------------------------------------------------------------------------------------------------------------------
-- Company: TAMU
-- Engineer: Evaldas Juska (evaldas.juska@cern.ch, evka85@gmail.com)
-- 
-- Create Date:    23:45:21 2016-04-20
-- Module Name:    GEM_AMC 
-- Description:    This is the top module of all the common GEM AMC logic. It is board-agnostic and can be used in different FPGA / board designs 
------------------------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.gem_pkg.all;
use work.board_config_package.all;
use work.ipb_addr_decode.all;
use work.ipbus.all;
use work.ttc_pkg.all;
use work.vendor_specific_gbt_bank_package.all;

entity gem_amc is
    generic(
        g_NUM_OF_OHs         : integer;
        g_USE_GBT            : boolean := true;  -- if this is true, GBT links will be used for communicationa with OH, if false 3.2Gbs 8b10b links will be used instead (remember to instanciate the correct links!)
        g_USE_3x_GBTs        : boolean := false; -- if this is true, each OH will use 3 GBT links - this will be default in the future with OH v3, but for now it's a good test
        g_USE_TRIG_LINKS     : boolean := true;  -- this should be TRUE by default, but could be set to false for tests or quicker compilation if not needed
        
        g_NUM_IPB_SLAVES     : integer;
        g_DAQ_CLK_FREQ       : integer
    );
    port(
        reset_i                 : in   std_logic;
        reset_pwrup_o           : out  std_logic;

        -- TTC
        ttc_clocks_i            : in t_ttc_clks;
        ttc_clocks_locked_i     : in  std_logic;
        ttc_data_p_i            : in  std_logic;      -- TTC protocol backplane signals
        ttc_data_n_i            : in  std_logic;
        
        -- 8b10b DAQ + Control GTX / GTH links (3.2Gbs, 16bit @ 160MHz w/ 8b10b encoding)
        gt_8b10b_rx_clk_arr_i   : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gt_8b10b_tx_clk_arr_i   : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gt_8b10b_rx_data_arr_i  : in  t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        gt_8b10b_tx_data_arr_o  : out t_gt_8b10b_tx_data_arr(g_NUM_OF_OHs - 1 downto 0);

        -- Trigger RX GTX / GTH links (3.2Gbs, 16bit @ 160MHz w/ 8b10b encoding)
        gt_trig0_rx_clk_arr_i   : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gt_trig0_rx_data_arr_i  : in  t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);
        gt_trig1_rx_clk_arr_i   : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gt_trig1_rx_data_arr_i  : in  t_gt_8b10b_rx_data_arr(g_NUM_OF_OHs - 1 downto 0);

        -- GBT DAQ + Control GTX / GTH links (4.8Gbs, 40bit @ 120MHz without 8b10b encoding)
        gt_gbt_rx_common_clk_i  : in  std_logic;
        gt_gbt_rx_links_arr_i   : in  t_gbt_mgt_rx_links_arr(g_NUM_OF_OHs - 1 downto 0);
        gt_gbt_tx_links_arr_o   : out t_gbt_mgt_tx_links_arr(g_NUM_OF_OHs - 1 downto 0);
        gt_gbt_tx0_clk_arr_i    : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gt_gbt_tx1_clk_arr_i    : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gt_gbt_tx2_clk_arr_i    : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);

        -- IPbus
        ipb_reset_i             : in  std_logic;
        ipb_clk_i               : in  std_logic;
        ipb_miso_arr_o          : out ipb_rbus_array(g_NUM_IPB_SLAVES - 1 downto 0);
        ipb_mosi_arr_i          : in  ipb_wbus_array(g_NUM_IPB_SLAVES - 1 downto 0);
        
        -- LEDs
        led_l1a_o               : out std_logic;
        led_trigger_o           : out std_logic;
        
        -- DAQLink
        daq_data_clk_i          : in  std_logic;
        daq_data_clk_locked_i   : in  std_logic;
        daq_to_daqlink_o        : out t_daq_to_daqlink;
        daqlink_to_daq_i        : in  t_daqlink_to_daq;
        
        -- Board serial number
        board_id_i              : in std_logic_vector(15 downto 0)
        
    );
end gem_amc;

architecture gem_amc_arch of gem_amc is

    --== VIO for LEDs ==--
    component vio_LEDs
        port(
            clk       : in std_logic;
            probe_in0 : in std_logic;
            probe_out0 : OUT std_logic
        );
    end component;

    --== General ==--
    signal reset       : std_logic;
    signal reset_pwrup : std_logic;
    signal ipb_reset   : std_logic;

    --== TTC signals ==--
    signal ttc_cmd      : t_ttc_cmds;
    signal ttc_counters : t_ttc_daq_cntrs;
    signal ttc_status   : t_ttc_status;

    --== Other ==--
    signal ipb_miso_arr : ipb_rbus_array(g_NUM_IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
    signal LED_state    : std_logic;
    signal LED_button_state : std_logic; --driven by VIO (either 0 or 1)

begin

    --================================--
    -- Power-on reset  
    --================================--
    
    reset_pwrup_o <= reset_pwrup;
    reset <= reset_i or reset_pwrup; -- TODO: Add a global reset from IPbus
    ipb_reset <= ipb_reset_i or reset_pwrup;
    ipb_miso_arr_o <= ipb_miso_arr;
    led_trigger_o <= LED_state when LED_button_state = '0' else '0';     -- connect LED to LED_state based on button
    led_l1a_o <= LED_state when LED_button_state = '1' else '0';         -- connect other LED to LED_state based on button

    process(ttc_clocks_i.clk_40) -- NOTE: using TTC clock, no nothing will work if there's no TTC clock
        variable countdown : integer := 40_000_000; -- 1s - probably way too long, but ok for now (this is only used after powerup)
    begin
        if (rising_edge(ttc_clocks_i.clk_40)) then
            if (countdown > 0) then
              reset_pwrup <= '1';
              countdown := countdown - 1;
            else
              reset_pwrup <= '0';
            end if;
        end if;
    end process;    
    
    --================================--
    -- TTC  
    --================================--

    i_ttc : entity work.ttc
        port map(
            reset_i             => reset,
            ttc_clks_i          => ttc_clocks_i,
            ttc_clks_locked_i   => ttc_clocks_locked_i,
            ttc_data_p_i        => ttc_data_p_i,
            ttc_data_n_i        => ttc_data_n_i,
            ttc_cmds_o          => ttc_cmd,
            ttc_daq_cntrs_o     => ttc_counters,
            ttc_status_o        => ttc_status,
            l1a_led_o           => open,
            ipb_reset_i         => ipb_reset,
            ipb_clk_i           => ipb_clk_i,
            ipb_mosi_i          => ipb_mosi_arr_i(C_IPB_SLV.ttc),
            ipb_miso_o          => ipb_miso_arr(C_IPB_SLV.ttc)
        );

    --================================--
    -- fake outputs  
    --================================--
    
    g_fake_outputs : for i in 0 to g_NUM_OF_OHs - 1 generate
        gt_8b10b_tx_data_arr_o(i).txchardispmode <= (others => '0');
        gt_8b10b_tx_data_arr_o(i).txchardispval <= (others => '0');
        gt_8b10b_tx_data_arr_o(i).txcharisk <= (others => '0');
        gt_8b10b_tx_data_arr_o(i).txdata <= (others => '0');
        
        gt_gbt_tx_links_arr_o(i).tx0data <= (others => '0');
        gt_gbt_tx_links_arr_o(i).tx1data <= (others => '0');
        gt_gbt_tx_links_arr_o(i).tx2data <= (others => '0');
        
        daq_to_daqlink_o.event_clk <= ttc_clocks_i.clk_40;
        daq_to_daqlink_o.event_data <= (others => '0');
        daq_to_daqlink_o.event_header <= '0';
        daq_to_daqlink_o.event_trailer <= '0';
        daq_to_daqlink_o.event_valid <= '0';
        daq_to_daqlink_o.reset <= reset_pwrup;
        daq_to_daqlink_o.resync <= '0';
        daq_to_daqlink_o.trig <= (others => '0');
        daq_to_daqlink_o.ttc_bc0 <= '0';
        daq_to_daqlink_o.ttc_clk <= ttc_clocks_i.clk_40;
        daq_to_daqlink_o.tts_clk <= ttc_clocks_i.clk_40;
        daq_to_daqlink_o.tts_state <= (others => '0');
    end generate;

    --================================--
    -- LED test  
    --================================--

    process(ttc_clocks_i.clk_40) 
        variable countdown : integer := 40_000_000;
    begin
        if (rising_edge(ttc_clocks_i.clk_40)) then
            if (countdown > 0) then
                countdown := countdown - 1;
            else
                countdown := 40_000_000;
            end if;
            
            if (countdown > 20_000_000) then
              LED_state <= '1';
            else
              LED_state <= '0';
            end if;
        end if;
    end process; 

    --================================--
    -- VIO Component  
    --================================--

    i_vio_LEDs : vio_LEDs
    port map (
        clk => ttc_clocks_i.clk_40,
        probe_in0 => LED_state,
        probe_out0 => LED_button_state
    );


end gem_amc_arch;
