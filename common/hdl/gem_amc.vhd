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
        g_NUM_IPB_SLAVES     : integer;
        g_DAQ_CLK_FREQ       : integer
    );
    port(
        reset_i                 : in   std_logic;
        reset_pwrup_o           : out  std_logic;

        -- TTC
        ttc_clocks_i            : in t_ttc_clks;
        ttc_commands_i          : in t_ttc_cmds;
        ttc_clocks_locked_i     : in  std_logic;
        
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

    --== Other ==--
    signal ipb_miso_arr : ipb_rbus_array(g_NUM_IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
    signal LED_raw_button_state : std_logic; --driven by VIO (either 0 or 1)
    
    signal LEDs : std_logic_vector( 1 downto 0 ); -- connect LEDs into vector for fsm

begin

    --================================--
    -- Power-on reset  
    --================================--
    
    reset_pwrup_o <= reset_pwrup;
    reset <= reset_i or reset_pwrup; -- TODO: Add a global reset from IPbus
    ipb_reset <= ipb_reset_i or reset_pwrup;
    ipb_miso_arr_o <= ipb_miso_arr;
    --led_trigger_o <= LED_state when LED_button_state = '0' else '0';     -- connect LED to LED_state based on button
    --led_l1a_o <= LED_state when LED_button_state = '1' else '0';         -- connect other LED to LED_state based on button
    led_trigger_o <= LEDs(0);
    led_l1a_o <= LEDs(1);

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
    -- fake DAQLink outputs (TODO: implement DAQ)   
    --================================--
    
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

    i_fsm : entity work.led_fsm
        port map(
            reset_i  => reset_pwrup,
            clk_i    => ttc_clocks_i.clk_40,
            button_i => LED_raw_button_state,
            LEDs_o   => LEDs
        );

    --================================--
    -- VIO Component  
    --================================--

    i_vio_LEDs : vio_LEDs
    port map (
        clk => ttc_clocks_i.clk_40,
        probe_in0 => LEDs(0),
        probe_out0 => LED_raw_button_state
    );


end gem_amc_arch;
