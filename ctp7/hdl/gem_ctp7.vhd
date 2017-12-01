-------------------------------------------------------------------------------
--                                                                            
--       Unit Name: gem_ctp7                                            
--                                                                            
--     Description: 
--
--                                                                            
-------------------------------------------------------------------------------
--                                                                            
--           Notes:                                                           
--                                                                            
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

use work.gth_pkg.all;

use work.ctp7_utils_pkg.all;
use work.ttc_pkg.all;
use work.system_package.all;
use work.gem_pkg.all;
use work.ipbus.all;
use work.axi_pkg.all;
use work.ipb_addr_decode.all;
use work.board_config_package.all;
use work.mp7_data_types.all;

--============================================================================
--                                                          Entity declaration
--============================================================================
entity gem_ctp7 is
    generic(
        C_DATE_CODE      : std_logic_vector(31 downto 0) := x"00000000";
        C_GITHASH_CODE   : std_logic_vector(31 downto 0) := x"00000000";
        C_GIT_REPO_DIRTY : std_logic                     := '0'
    );
    port(
        clk_200_diff_in_clk_p          : in  std_logic;
        clk_200_diff_in_clk_n          : in  std_logic;

        clk_40_ttc_p_i                 : in  std_logic; -- TTC backplane clock signals
        clk_40_ttc_n_i                 : in  std_logic;
        ttc_data_p_i                   : in  std_logic;
        ttc_data_n_i                   : in  std_logic;

        LEDs                           : out std_logic_vector(1 downto 0);

        axi_c2c_v7_to_zynq_data        : out std_logic_vector(14 downto 0);
        axi_c2c_v7_to_zynq_clk         : out std_logic;
        axi_c2c_zynq_to_v7_clk         : in  std_logic;
        axi_c2c_zynq_to_v7_data        : in  std_logic_vector(14 downto 0);
        axi_c2c_v7_to_zynq_link_status : out std_logic;
        axi_c2c_zynq_to_v7_reset       : in  std_logic;

        refclk_F_0_p_i                 : in  std_logic_vector(3 downto 0);
        refclk_F_0_n_i                 : in  std_logic_vector(3 downto 0);
        refclk_F_1_p_i                 : in  std_logic_vector(3 downto 0);
        refclk_F_1_n_i                 : in  std_logic_vector(3 downto 0);

        refclk_B_0_p_i                 : in  std_logic_vector(3 downto 1);
        refclk_B_0_n_i                 : in  std_logic_vector(3 downto 1);
        refclk_B_1_p_i                 : in  std_logic_vector(3 downto 1);
        refclk_B_1_n_i                 : in  std_logic_vector(3 downto 1);
        
        -- AMC13 GTH
        amc13_gth_refclk_p             : in  std_logic;
        amc13_gth_refclk_n             : in  std_logic;
        amc_13_gth_rx_n                : in  std_logic;
        amc_13_gth_rx_p                : in  std_logic;
        amc13_gth_tx_n                 : out std_logic;
        amc13_gth_tx_p                 : out std_logic
        
    );
end gem_ctp7;

--============================================================================
--                                                        Architecture section
--============================================================================
architecture gem_ctp7_arch of gem_ctp7 is

    --============================================================================
    --                                                         Signal declarations
    --============================================================================

    -------------------------- System clocks ---------------------------------
    signal clk_50       : std_logic;
    signal clk_200      : std_logic;

    -------------------------- AXI-IPbus bridge ---------------------------------
    --AXI
    signal axi_clk      : std_logic;
    signal axi_reset    : std_logic;
    signal ipb_axi_mosi : t_axi_lite_mosi;
    signal ipb_axi_miso : t_axi_lite_miso;
    --IPbus
    signal ipb_reset    : std_logic;
    signal ipb_clk      : std_logic;
    signal ipb_miso_arr : ipb_rbus_array(C_NUM_IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
    signal ipb_mosi_arr : ipb_wbus_array(C_NUM_IPB_SLAVES - 1 downto 0);

    -------------------------- TTC ---------------------------------
    signal ttc_clocks           : t_ttc_clks;
    signal ttc_clocks_locked    : std_logic;
    signal ttc_commands         : t_ttc_cmds;

    -------------------------- GTH ---------------------------------
    signal clk_gth_tx_arr       : std_logic_vector(g_NUM_OF_GTH_GTs - 1 downto 0);
    signal clk_gth_rx_arr       : std_logic_vector(g_NUM_OF_GTH_GTs - 1 downto 0);
    signal gth_tx_data_arr      : t_gt_8b10b_tx_data_arr(g_NUM_OF_GTH_GTs - 1 downto 0);
    signal gth_rx_data_arr      : t_gt_8b10b_rx_data_arr(g_NUM_OF_GTH_GTs - 1 downto 0);
    signal gth_gbt_tx_data_arr  : t_gt_gbt_tx_data_arr(g_NUM_OF_GTH_GTs - 1 downto 0);
    signal gth_gbt_rx_data_arr  : t_gt_gbt_rx_data_arr(g_NUM_OF_GTH_GTs - 1 downto 0);
    signal gth_rxreset_arr      : std_logic_vector(g_NUM_OF_GTH_GTs - 1 downto 0);
    signal gth_txreset_arr      : std_logic_vector(g_NUM_OF_GTH_GTs - 1 downto 0);

    
    -------------------- GTHs mapped to GEM links ---------------------------------
    signal gth_muon_downlinks   : ldata((CFG_MP7_QUADS_NUM * 4) - 1 downto 0); -- GTH muon downlinks (not mapped to physical fiber)
    signal gth_muon_uplinks     : ldata((CFG_MP7_QUADS_NUM * 4) - 1 downto 0); -- GTH muon uplinks   (not mapped to physical fiber
    signal fiber_muon_downlinks : ldata((CFG_MP7_QUADS_NUM * 4) - 1 downto 0); -- GTH muon downlinks with numbering mapped to physical fiber number
    signal fiber_muon_uplinks   : ldata((CFG_MP7_QUADS_NUM * 4) - 1 downto 0); -- GTH muon uplinks with numbering mapped to physical fiber
    signal muon_link_clk        : std_logic; 
    
    
    -------------------------- DEBUG ----------------------------------
    signal debug_gth_rx_data    : t_gt_8b10b_rx_data;
    signal debug_gth_tx_data    : t_gt_8b10b_tx_data;

    signal tmp_countdown        : integer range 0 to 15000 := 15000;
    signal fake_valid           : std_logic;

    -------------------- AMC13 DAQLink ---------------------------------
    signal daq_to_daqlink       : t_daq_to_daqlink;
    signal daqlink_to_daq       : t_daqlink_to_daq;

--    attribute mark_debug : string;
--    attribute mark_debug of debug_gth_tx_data : signal is "true";
--    attribute mark_debug of debug_gth_rx_data : signal is "true";

--  attribute mark_debug of gth_rx_data_arr: signal is "true";
--  attribute mark_debug of gth_tx_data_arr: signal is "true";

--============================================================================
--                                                          Architecture begin
--============================================================================

begin

    -------------------------- SYSTEM ---------------------------------

    i_system : entity work.system
        generic map(
            C_MP7_QUADS_NUM => CFG_MP7_QUADS_NUM
        )
        port map(
            clk_200_diff_in_clk_p          => clk_200_diff_in_clk_p,
            clk_200_diff_in_clk_n          => clk_200_diff_in_clk_n,
            
            axi_c2c_v7_to_zynq_data        => axi_c2c_v7_to_zynq_data,
            axi_c2c_v7_to_zynq_clk         => axi_c2c_v7_to_zynq_clk,
            axi_c2c_zynq_to_v7_clk         => axi_c2c_zynq_to_v7_clk,
            axi_c2c_zynq_to_v7_data        => axi_c2c_zynq_to_v7_data,
            axi_c2c_v7_to_zynq_link_status => axi_c2c_v7_to_zynq_link_status,
            axi_c2c_zynq_to_v7_reset       => axi_c2c_zynq_to_v7_reset,
            
            refclk_F_0_p_i                 => refclk_F_0_p_i,
            refclk_F_0_n_i                 => refclk_F_0_n_i,
            refclk_F_1_p_i                 => refclk_F_1_p_i,
            refclk_F_1_n_i                 => refclk_F_1_n_i,
            refclk_B_0_p_i                 => refclk_B_0_p_i,
            refclk_B_0_n_i                 => refclk_B_0_n_i,
            refclk_B_1_p_i                 => refclk_B_1_p_i,
            refclk_B_1_n_i                 => refclk_B_1_n_i,

            clk_50_o                       => clk_50,
            clk_200_o                      => clk_200,
            
            axi_clk_o                      => axi_clk,
            axi_reset_o                    => axi_reset,
            ipb_axi_mosi_o                 => ipb_axi_mosi,
            ipb_axi_miso_i                 => ipb_axi_miso,
            
            clk_40_ttc_p_i                 => clk_40_ttc_p_i,
            clk_40_ttc_n_i                 => clk_40_ttc_n_i,
            ttc_data_p_i                   => ttc_data_p_i,
            ttc_data_n_i                   => ttc_data_n_i,
            ttc_clks_o                     => ttc_clocks,
            ttc_clks_locked_o              => ttc_clocks_locked,
            ttc_commands_o                 => ttc_commands,
            
            clk_gth_tx_arr_o               => clk_gth_tx_arr,
            clk_gth_rx_arr_o               => clk_gth_rx_arr,
            
            gth_tx_data_arr_i              => gth_tx_data_arr,
            gth_rx_data_arr_o              => gth_rx_data_arr,
            gth_gbt_tx_data_arr_i          => gth_gbt_tx_data_arr,
            gth_gbt_rx_data_arr_o          => gth_gbt_rx_data_arr,

            gth_gbt_common_rxusrclk_o      => open,
            
            gth_rxreset_arr_o              => gth_rxreset_arr,
            gth_txreset_arr_o              => gth_txreset_arr,

            muon_downlinks_o               => gth_muon_downlinks,
            muon_uplinks_i                 => gth_muon_uplinks,
            muon_link_clk_o                => muon_link_clk,

            amc13_gth_refclk_p             => amc13_gth_refclk_p,
            amc13_gth_refclk_n             => amc13_gth_refclk_n,
            amc_13_gth_rx_n                => amc_13_gth_rx_n,
            amc_13_gth_rx_p                => amc_13_gth_rx_p,
            amc13_gth_tx_n                 => amc13_gth_tx_n,
            amc13_gth_tx_p                 => amc13_gth_tx_p,
            
            daq_to_daqlink_i               => daq_to_daqlink,
            daqlink_to_daq_o               => daqlink_to_daq,

            ipb_reset_i                    => ipb_reset,
            ipb_clk_i                      => ipb_clk,
            ipb_miso_o                     => ipb_miso_arr(C_IPB_SLV.mp7),
            ipb_mosi_i                     => ipb_mosi_arr(C_IPB_SLV.mp7)          
        );

    -------------------------- IPBus ---------------------------------

    i_axi_ipbus_bridge : entity work.axi_ipbus_bridge
        generic map(
            C_NUM_IPB_SLAVES   => C_NUM_IPB_SLAVES,
            C_S_AXI_DATA_WIDTH => 32,
            C_S_AXI_ADDR_WIDTH => C_IPB_AXI_ADDR_WIDTH
        )
        port map(
            ipb_reset_o   => ipb_reset,
            ipb_clk_o     => ipb_clk,
            ipb_miso_i    => ipb_miso_arr,
            ipb_mosi_o    => ipb_mosi_arr,
            S_AXI_ACLK    => axi_clk,
            S_AXI_ARESETN => axi_reset,
            S_AXI_AWADDR  => ipb_axi_mosi.awaddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0),
            S_AXI_AWPROT  => ipb_axi_mosi.awprot,
            S_AXI_AWVALID => ipb_axi_mosi.awvalid,
            S_AXI_AWREADY => ipb_axi_miso.awready,
            S_AXI_WDATA   => ipb_axi_mosi.wdata,
            S_AXI_WSTRB   => ipb_axi_mosi.wstrb,
            S_AXI_WVALID  => ipb_axi_mosi.wvalid,
            S_AXI_WREADY  => ipb_axi_miso.wready,
            S_AXI_BRESP   => ipb_axi_miso.bresp,
            S_AXI_BVALID  => ipb_axi_miso.bvalid,
            S_AXI_BREADY  => ipb_axi_mosi.bready,
            S_AXI_ARADDR  => ipb_axi_mosi.araddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0),
            S_AXI_ARPROT  => ipb_axi_mosi.arprot,
            S_AXI_ARVALID => ipb_axi_mosi.arvalid,
            S_AXI_ARREADY => ipb_axi_miso.arready,
            S_AXI_RDATA   => ipb_axi_miso.rdata,
            S_AXI_RRESP   => ipb_axi_miso.rresp,
            S_AXI_RVALID  => ipb_axi_miso.rvalid,
            S_AXI_RREADY  => ipb_axi_mosi.rready
        );

    -------------------------- Correlator logic ---------------------------------
    
    i_correlator : entity work.correlator
        generic map(
            G_NUM_IPB_SLAVES     => C_NUM_IPB_SLAVES - 1,
            G_DAQ_CLK_FREQ       => 50_000_000,
            G_MUON_LINK_NUM      => CFG_MUON_LINK_NUM
        )
        port map(
            reset_i                 => '0',
            reset_pwrup_o           => open,
            
            ttc_clocks_i            => ttc_clocks,
            ttc_clocks_locked_i     => ttc_clocks_locked,
            ttc_commands_i          => ttc_commands,

            muon_downlinks_i        => fiber_muon_downlinks,
            muon_uplinks_o          => fiber_muon_uplinks,
            muon_link_clk_i         => muon_link_clk,
                        
            ipb_reset_i             => ipb_reset,
            ipb_clk_i               => ipb_clk,
            ipb_miso_arr_o          => ipb_miso_arr(C_NUM_IPB_SLAVES - 2 downto 0), -- the top slave is already used for mp7 modules
            ipb_mosi_arr_i          => ipb_mosi_arr(C_NUM_IPB_SLAVES - 2 downto 0), -- the top slave is already used for mp7 modules

            led_l1a_o               => LEDs(0),
            led_trigger_o           => LEDs(1),
            
            daq_data_clk_i          => clk_50,
            daq_data_clk_locked_i   => '1',
            daq_to_daqlink_o        => daq_to_daqlink,
            daqlink_to_daq_i        => daqlink_to_daq,
            
            board_id_i              => x"beef"
        );

    -- GTH mapping to physical fibers
    g_gem_links : for i in 0 to CFG_MUON_LINK_NUM - 1 generate
        fiber_muon_downlinks(i) <= gth_muon_downlinks(CFG_CXP_FIBER_TO_GTH_MAP(CFG_MUON_LINK_CONFIG_ARR(i)).rx);
        gth_muon_uplinks(CFG_CXP_FIBER_TO_GTH_MAP(CFG_MUON_LINK_CONFIG_ARR(i)).tx) <= fiber_muon_uplinks(i);
    end generate; 

    process(muon_link_clk)
    begin
        if (rising_edge(muon_link_clk)) then
            if (tmp_countdown > 0) then
                tmp_countdown <= tmp_countdown - 1;
            else
                tmp_countdown <= 15000;
            end if;
            
            if (tmp_countdown < 3000) then
                fake_valid <= '0';
            else
                fake_valid <= '1';
            end if;
        end if;
    end process;

end gem_ctp7_arch;

--============================================================================
--                                                            Architecture end
--============================================================================

