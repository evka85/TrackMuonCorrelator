------------------------------------------------------------------------------------------------------------------------------------------------------
-- Company: TAMU
-- Engineer: Dan Marley (daniel.edison.marley@cernSPAMNOT.ch)
-- 
-- Create Date:    2017-06-02
-- Module Name:    muonlink 
-- Description:    Module responsible for muon link data processing/decoding
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
use work.mp7_data_types.all;
use work.registers.all;


entity muonlink is
    port(
        reset_i        : in  std_logic;
        clk_240_i      : in  std_logic;
        muonlink_i     : in  lword;

        -- IPbus
        ipb_reset_i    : in  std_logic;
        ipb_clk_i      : in  std_logic;
        ipb_miso_o     : out ipb_rbus;
        ipb_mosi_i     : in  ipb_wbus
    );
end muonlink;

architecture Behavioral of muonlink is

    component ila_bx
        port(
            clk    : in std_logic;
            probe0 : in std_logic_vector(31 downto 0);
            probe1 : in std_logic_vector(2 downto 0);
            probe2 : in std_logic_vector(11 downto 0);
            probe3 : in std_logic;
            probe4 : in std_logic_vector(2 downto 0);
            probe5 : in std_logic_vector(1 downto 0)
        );
    end component;

    -- Custom state for reading Muon data
    type state_t is (IDLE, DECODE_FRAME_0, DECODE_FRAME_1);
    
    signal state          : state_t := IDLE;
    signal count_muons_bx : unsigned(1 downto 0);  -- count muons per bunch crossing
    signal count_bxs      : unsigned(11 downto 0);
    
    signal strobe_muons      : std_logic;
    signal muon_counter      : std_logic_vector(31 downto 0); --count all muons
    signal muon_rate_counter : std_logic_vector(31 downto 0); --count all muons
    signal muon_data         : std_logic_vector(31 downto 0); -- t_std32_array( G_MUON_LINK_NUM - 1 downto 0 );
    
    signal first_bc0           : std_logic;
    signal strobe_bc0          : std_logic; 
    signal frame_counter       : unsigned(2 downto 0);
    signal bx_sync_err_counter : unsigned(31 downto 0);
    signal count_sync_errs     : unsigned(31 downto 0);
    signal data_bx             : std_logic_vector( 2 downto 0 );

    ------ Register signals begin (this section is generated by <gem_amc_repo_root>/scripts/generate_registers.py -- do not edit)
    signal regs_read_arr        : t_std32_array(REG_MUONLINK_NUM_REGS - 1 downto 0);
    signal regs_write_arr       : t_std32_array(REG_MUONLINK_NUM_REGS - 1 downto 0);
    signal regs_addresses       : t_std32_array(REG_MUONLINK_NUM_REGS - 1 downto 0);
    signal regs_defaults        : t_std32_array(REG_MUONLINK_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_read_pulse_arr  : std_logic_vector(REG_MUONLINK_NUM_REGS - 1 downto 0);
    signal regs_write_pulse_arr : std_logic_vector(REG_MUONLINK_NUM_REGS - 1 downto 0);
    signal regs_read_ready_arr  : std_logic_vector(REG_MUONLINK_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_write_done_arr  : std_logic_vector(REG_MUONLINK_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_writable_arr    : std_logic_vector(REG_MUONLINK_NUM_REGS - 1 downto 0) := (others => '0');
    ------ Register signals end ----------------------------------------------

begin

    --================================--
    -- Muon Data Processing State Machine
    --================================--

    process(clk_240_i)
    begin
        if (rising_edge(clk_240_i)) then            
            if ( (muonlink_i.valid = '0') or (reset_i = '1') ) then 
                state <= IDLE;
                count_muons_bx <= (others => '0');
            else
                case state is
                    when DECODE_FRAME_0 => 
                        -- go to the next frame to decode data
                        state <= DECODE_FRAME_1;
                    when DECODE_FRAME_1 => 
                        -- Count muons per bunch crossing
                        if (count_muons_bx = "10") then
                            count_muons_bx <= (others => '0');  -- reset_i the muon counter
                        else
                            count_muons_bx <= count_muons_bx + 1;
                        end if;
                        -- go back to DECODE_FRAME_0, if valid_bx <='1' else IDLE
                        state <= DECODE_FRAME_0;
                    when IDLE =>
                        -- reset number of muons per bunch crossing and go to next state
                        count_muons_bx <= (others => '0');
                        state <= DECODE_FRAME_0;
                    when others => state <= IDLE;
                end case;
 
            end if;
        end if;
    end process; 



    --================================--
    -- Muon Data Processing
    --
    -- Link our signal with the data
    --================================--

    process(clk_240_i)
    begin
        if (rising_edge(clk_240_i)) then
            if ( reset_i='1' ) then
                muon_data <= (others => '0');
            else
                muon_data <= muonlink_i.data;
            end if;
        end if;
    end process; 



    --================================--
    -- Muon Data Processing
    --
    -- Data is structured such that 32 bits 
    -- of information are passed in two frames
    -- for each muon.
    -- More information: 
    --   CMS Detector Note
    --   Head ID: 319791
    --================================--

    process(clk_240_i)
    begin
        if (rising_edge(clk_240_i)) then
            if ( reset_i='1' ) then
                bx_sync_err_counter <= (others => '0');
                count_sync_errs <= (others => '0');
                strobe_bc0 <= '0';
                first_bc0 <= '0';
            else
                strobe_bc0 <= '0';
                case state is
                    when DECODE_FRAME_0 => 
                        -- No muons and at BX0, reset the bunch crossing counter
                        if ((count_muons_bx = "00") and (muon_data(31) = '1')) then
                            strobe_bc0 <= '1';
                            first_bc0 <= '1';
                            data_bx <= (others => '0');
                        end if;
                        -- 1 muon, set the first bunch crossing bit to the value in the data ("B0" according to manual)
                        if (count_muons_bx = "01") then
                            data_bx(0) <= muon_data(31);
                        end if;
                        -- 2 muons, set the third bunch crossing bit to the value in the data ("B2")
                        if (count_muons_bx = "10") then
                            data_bx(2) <= muon_data(31);
                        end if;
                    when DECODE_FRAME_1 => 
                        -- No muons and Synchronization Error, increment our internal error counter
                        if ((count_muons_bx = "00") and (muon_data(31) = '1')) then 
                            count_sync_errs <= count_sync_errs + 1;
                        end if;
                        -- 1 muon, set the second bunch crossing bit to the value in the data ("B1")
                        if (count_muons_bx = "01") then
                            data_bx(1) <= muon_data(31);
                        end if;
                        -- 2 muons and the bunch crossing data doesn't match our counter
                        if ((first_bc0 = '1') and (count_muons_bx = "10") and (data_bx /= std_logic_vector(count_bxs(2 downto 0)))) then
                            bx_sync_err_counter <= bx_sync_err_counter + 1;
                        end if;
                    when others => 
                end case;
            end if;
        end if;
    end process;


    --===
    -- MuonData : Bunch crossing counting for invalid crossing
    --===

    process(clk_240_i)
    begin
        if (rising_edge(clk_240_i)) then
            if (reset_i='1') then
                frame_counter <= (others => '0');
                count_bxs <= (others => '0');
            else
                if (strobe_bc0 = '1') then
                    frame_counter <= "010";
                    count_bxs <= (others => '0');                
                elsif (frame_counter = "101") then
                    frame_counter <= (others => '0');
                    count_bxs <= count_bxs + 1;
                else
                    frame_counter <= frame_counter+1;
                end if;
            end if;
        end if;
    end process;


    --===
    -- MuonData : strobe for muons
    --==
    
    process(clk_240_i)
    begin
        if (rising_edge(clk_240_i)) then
            if ( reset_i='1' ) then
                strobe_muons <= '0';
            else
                -- Check that the muon pT != 0 (9 bits in data)
                if ((state = DECODE_FRAME_0) and (muon_data(8 downto 0) /= "000000000")) then 
                    strobe_muons <= '1';
                else
                    strobe_muons <= '0';
                end if;
            end if;
        end if;
    end process;


    --===
    -- Interface with counter and rate counter (modules built by Evaldas)
    --===

    i_muoncounter : entity work.counter
        generic map(
            g_COUNTER_WIDTH  => 32,
            g_ALLOW_ROLLOVER => true,
            g_INCREMENT_STEP => 1
        )
        port map(
            ref_clk_i => clk_240_i,
            reset_i   => reset_i,
            en_i      => strobe_muons,
            count_o   => muon_counter
        );


    i_muonratecounter : entity work.rate_counter
        generic map(
            g_CLK_FREQUENCY => C_PROCESSING_CLK_FREQUENCY_SLV,
            g_COUNTER_WIDTH => 32
        )
        port map(
            clk_i   => clk_240_i,
            reset_i => reset_i,
            en_i    => strobe_muons,
            rate_o  => muon_rate_counter
        );


    ila_bxs : ila_bx
    port map (
        clk => clk_240_i,
        probe0 => muon_data, 
        probe1 => data_bx, 
        probe2 => std_logic_vector(count_bxs),
        probe3 => strobe_bc0,
        probe4 => std_logic_vector(frame_counter),
        probe5 => std_logic_vector(count_muons_bx)
    );


    --===============================================================================================
    -- this section is generated by <gem_amc_repo_root>/scripts/generate_registers.py (do not edit)
    --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
    ipbus_slave_inst : entity work.ipbus_slave
        generic map(
           g_NUM_REGS             => REG_MUONLINK_NUM_REGS,
           g_ADDR_HIGH_BIT        => REG_MUONLINK_ADDRESS_MSB,
           g_ADDR_LOW_BIT         => REG_MUONLINK_ADDRESS_LSB,
           g_USE_INDIVIDUAL_ADDRS => true
       )
       port map(
           ipb_reset_i            => ipb_reset_i,
           ipb_clk_i              => ipb_clk_i,
           ipb_mosi_i             => ipb_mosi_i,
           ipb_miso_o             => ipb_miso_o,
           usr_clk_i              => clk_240_i,
           regs_read_arr_i        => regs_read_arr,
           regs_write_arr_o       => regs_write_arr,
           read_pulse_arr_o       => regs_read_pulse_arr,
           write_pulse_arr_o      => regs_write_pulse_arr,
           regs_read_ready_arr_i  => regs_read_ready_arr,
           regs_write_done_arr_i  => regs_write_done_arr,
           individual_addrs_arr_i => regs_addresses,
           regs_defaults_arr_i    => regs_defaults,
           writable_regs_i        => regs_writable_arr
      );

    -- Addresses
    regs_addresses(0)(REG_MUONLINK_ADDRESS_MSB downto REG_MUONLINK_ADDRESS_LSB) <= x"0000";
    regs_addresses(1)(REG_MUONLINK_ADDRESS_MSB downto REG_MUONLINK_ADDRESS_LSB) <= x"0001";
    regs_addresses(2)(REG_MUONLINK_ADDRESS_MSB downto REG_MUONLINK_ADDRESS_LSB) <= x"0002";
    regs_addresses(3)(REG_MUONLINK_ADDRESS_MSB downto REG_MUONLINK_ADDRESS_LSB) <= x"0003";

    -- Connect read signals
    regs_read_arr(0)(REG_MUONLINK_STATUS_MUON_COUNTER_MSB downto REG_MUONLINK_STATUS_MUON_COUNTER_LSB) <= muon_counter;
    regs_read_arr(1)(REG_MUONLINK_STATUS_MUON_RATE_COUNTER_MSB downto REG_MUONLINK_STATUS_MUON_RATE_COUNTER_LSB) <= muon_rate_counter;
    regs_read_arr(2)(REG_MUONLINK_STATUS_BX_SYNC_ERR_COUNTER_MSB downto REG_MUONLINK_STATUS_BX_SYNC_ERR_COUNTER_LSB) <= std_logic_vector(bx_sync_err_counter);
    regs_read_arr(3)(REG_MUONLINK_STATUS_COUNT_SYNC_ERRS_MSB downto REG_MUONLINK_STATUS_COUNT_SYNC_ERRS_LSB) <= std_logic_vector(count_sync_errs);

    -- Connect write signals

    -- Connect write pulse signals

    -- Connect write done signals

    -- Connect read pulse signals

    -- Connect read ready signals

    -- Defaults

    -- Define writable regs

    --==== Registers end ============================================================================

end Behavioral;
