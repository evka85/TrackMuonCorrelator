-- file: clk_wiz_v2_1.vhd
-- 
-- (c) Copyright 2010 - 2012 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
------------------------------------------------------------------------------
-- User entered comments
------------------------------------------------------------------------------
-- None
--
------------------------------------------------------------------------------
-- Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
-- Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
------------------------------------------------------------------------------
-- CLK_OUT1   100.000      0.000    50.000      130.958     98.575
-- CLK_OUT2   200.000      0.000    50.000      114.829     98.575
--
------------------------------------------------------------------------------
-- Input Clock   Input Freq (MHz)   Input Jitter (UI)
------------------------------------------------------------------------------
-- primary         100.000            0.010

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity gth_4p8_raw_CLOCK_MODULE is
  generic
    (
      MULT                      : real    := 9.0;
      DIVIDE                    : integer := 2;
      CLK_PERIOD                : real    := 6.25;
      OUT0_DIVIDE               : real    := 6.0;
      OUT1_DIVIDE               : integer := 6;
      OUT2_DIVIDE               : integer := 1;
      OUT3_DIVIDE               : integer := 1;
      PLL_LOCK_WAIT_TIMEOUT     : unsigned(23 downto 0) := x"002710" -- way too long, will measure how low we can go here      
      );
  port
    (  -- Clock in ports
      CLK_IN_160        : in  std_logic;
      CLK_ALIGN_120     : in  std_logic; -- 120MHz clock to which CLK_OUT_120 should be phase aligned
      -- Clock out ports
      CLK_OUT_120       : out std_logic;
      CLK_OUT_120_90deg : out std_logic;
      -- Status and control signals
      MMCM_RESET_IN     : in  std_logic;
      MMCM_LOCKED_OUT   : out std_logic;
      -- debug
      MMCM_SHIFT_CNT    : out std_logic_vector(11 downto 0);
      PLL_LOCK_TIME     : out std_logic_vector(23 downto 0)
      );
end gth_4p8_raw_CLOCK_MODULE;

architecture xilinx of gth_4p8_raw_CLOCK_MODULE is
  attribute X_CORE_INFO                    : string;
  attribute X_CORE_INFO of xilinx          : architecture is "gth_4p8_raw,gtwizard_v3_6_0,{protocol_file=Start_from_scratch}";
  attribute CORE_GENERATION_INFO           : string;
  attribute CORE_GENERATION_INFO of xilinx : architecture is "clk_wiz_v2_1,clk_wiz_v2_1,{component_name=clk_wiz_v2_1,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,feedback_source=FDBK_AUTO,primtype_sel=MMCM_ADV,num_out_clk=2,clkin1_period=10.0,clkin2_period=10.0,use_power_down=false,use_reset=true,use_locked=true,use_inclk_stopped=false,use_status=false,use_freeze=false,use_clk_valid=false,feedback_type=SINGLE,clock_mgr_type=MANUAL,manual_override=false}";
  -- Input clock buffering / unused connectors
  signal clkin1                            : std_logic;
  -- Output clock buffering / unused connectors
  signal clkfbout                          : std_logic;
  signal clkfbout_buf                      : std_logic;
  signal clkfboutb_unused                  : std_logic;
  signal clkout0                           : std_logic;
  signal clkout0_bufg                      : std_logic;
  signal clkout0b_unused                   : std_logic;
  signal clkout1                           : std_logic;
  signal clkout1_bufg                      : std_logic;
  signal clkout1b_unused                   : std_logic;
  signal clkout2                           : std_logic;
  signal clkout2b_unused                   : std_logic;
  signal clkout3                           : std_logic;
  signal clkout3b_unused                   : std_logic;
  signal clkout4_unused                    : std_logic;
  signal clkout5_unused                    : std_logic;
  signal clkout6_unused                    : std_logic;
  -- Dynamic programming unused signals
  signal do_unused                         : std_logic_vector(15 downto 0);
  signal drdy_unused                       : std_logic;
  -- Unused status signals
  signal clkfbstopped_unused               : std_logic;
  signal clkinstopped_unused               : std_logic;
  
  ----------------- phase alignment ------------------
  constant MMCM_PS_DONE_TIMEOUT            : unsigned(7 downto 0) := x"9f"; -- datasheet says MMCM should complete a phase shift in 12 clocks, but we check it with some margin, just in case
  type pa_state_t is (IDLE, CHECK_PHASE, SHIFT_PHASE, WAIT_SHIFT_DONE, SYNC_DONE);

  signal mmcm_ps_clk                       : std_logic;
  signal mmcm_ps_en                        : std_logic;
  signal mmcm_ps_done                      : std_logic;
  signal mmcm_locked                       : std_logic;
  
  signal pll_locked                        : std_logic;
  signal pll_reset                         : std_logic;

  signal pa_state                          : pa_state_t := IDLE;
  signal pll_lock_wait_timer               : unsigned(23 downto 0) := (others => '0');
  signal mmcm_ps_done_timer                : unsigned(7 downto 0) := (others => '0');
  
begin

  -- Input buffering
  --------------------------------------
  clkin1_buf : BUFG
    port map
    (O => clkin1,
     I => CLK_IN_160);

  -- Clocking primitive
  --------------------------------------
  -- Instantiation of the MMCM primitive
  --    * Unused inputs are tied off
  --    * Unused outputs are labeled unused

  mmcm_adv_inst : MMCME2_ADV
    generic map
    (BANDWIDTH            => "OPTIMIZED",
     CLKOUT4_CASCADE      => false,
     COMPENSATION         => "ZHOLD",
     STARTUP_WAIT         => false,
     DIVCLK_DIVIDE        => DIVIDE,
     CLKFBOUT_MULT_F      => MULT,
     CLKFBOUT_PHASE       => 0.000,
     CLKFBOUT_USE_FINE_PS => true,
     CLKOUT0_DIVIDE_F     => OUT0_DIVIDE,
     CLKOUT0_PHASE        => 0.000,
     CLKOUT0_DUTY_CYCLE   => 0.500,
     CLKOUT0_USE_FINE_PS  => false,
     CLKIN1_PERIOD        => CLK_PERIOD,
     CLKOUT1_DIVIDE       => OUT1_DIVIDE,
     CLKOUT1_PHASE        => 90.000,
     CLKOUT1_DUTY_CYCLE   => 0.500,
     CLKOUT1_USE_FINE_PS  => false,
     CLKOUT2_DIVIDE       => OUT2_DIVIDE,
     CLKOUT2_PHASE        => 0.000,
     CLKOUT2_DUTY_CYCLE   => 0.500,
     CLKOUT2_USE_FINE_PS  => false,
     CLKOUT3_DIVIDE       => OUT3_DIVIDE,
     CLKOUT3_PHASE        => 0.000,
     CLKOUT3_DUTY_CYCLE   => 0.500,
     CLKOUT3_USE_FINE_PS  => false,
     REF_JITTER1          => 0.010)
    port map
    -- Output clocks
    (CLKFBOUT     => clkfbout,
     CLKFBOUTB    => clkfboutb_unused,
     CLKOUT0      => clkout0,
     CLKOUT0B     => clkout0b_unused,
     CLKOUT1      => clkout1,
     CLKOUT1B     => clkout1b_unused,
     CLKOUT2      => clkout2,
     CLKOUT2B     => clkout2b_unused,
     CLKOUT3      => clkout3,
     CLKOUT3B     => clkout3b_unused,
     CLKOUT4      => clkout4_unused,
     CLKOUT5      => clkout5_unused,
     CLKOUT6      => clkout6_unused,
     -- Input clock control
     CLKFBIN      => clkfbout,
     CLKIN1       => clkin1,
     CLKIN2       => '0',
     -- Tied to always select the primary input clock
     CLKINSEL     => '1',
     -- Ports for dynamic reconfiguration
     DADDR        => (others => '0'),
     DCLK         => '0',
     DEN          => '0',
     DI           => (others => '0'),
     DO           => do_unused,
     DRDY         => drdy_unused,
     DWE          => '0',
     -- Ports for dynamic phase shift
     PSCLK        => mmcm_ps_clk,
     PSEN         => mmcm_ps_en,
     PSINCDEC     => '1',
     PSDONE       => mmcm_ps_done,
     -- Other control and status signals
     LOCKED       => mmcm_locked,
     CLKINSTOPPED => clkinstopped_unused,
     CLKFBSTOPPED => clkfbstopped_unused,
     PWRDWN       => '0',
     RST          => MMCM_RESET_IN);

  -- Output buffering
  -------------------------------------
  --clkf_buf : BUFG
  --port map
  -- (O => clkfbout_buf,
  --  I => clkfbout);


  clkout0_buf : BUFG
    port map
    (O => clkout0_bufg,
     I => clkout0);

  clkout1_buf : BUFG
    port map
    (O => clkout1_bufg,
     I => clkout1);

  CLK_OUT_120 <= clkout0_bufg;
  CLK_OUT_120_90deg <= clkout1_bufg;

  ---------------------------------------------------------
  -------------------- Phase Alignment --------------------
  ---------------------------------------------------------
  
    mmcm_ps_clk <= CLK_ALIGN_120;
    MMCM_LOCKED_OUT <= '1' when pa_state = SYNC_DONE else '0';
    PLL_LOCK_TIME <= std_logic_vector(pll_lock_wait_timer);
  
    -- using this PLL to check phase alignment between the MMCM 120 output and TTC 120
    i_phase_monitor_pll : PLLE2_BASE
        generic map(
            BANDWIDTH          => "OPTIMIZED",
            CLKFBOUT_MULT      => 7,
            CLKFBOUT_PHASE     => 0.000,
            CLKIN1_PERIOD      => 8.333,
            CLKOUT0_DIVIDE     => 7,
            CLKOUT0_DUTY_CYCLE => 0.500,
            CLKOUT0_PHASE      => 0.000,
            CLKOUT1_DIVIDE     => 7,
            CLKOUT1_DUTY_CYCLE => 0.500,
            CLKOUT1_PHASE      => 0.000,
            CLKOUT2_DIVIDE     => 7,
            CLKOUT2_DUTY_CYCLE => 0.500,
            CLKOUT2_PHASE      => 0.000,
            CLKOUT3_DIVIDE     => 7,
            CLKOUT3_DUTY_CYCLE => 0.500,
            CLKOUT3_PHASE      => 0.000,
            DIVCLK_DIVIDE      => 1,
            REF_JITTER1        => 0.010
        )
        port map(
            CLKFBOUT => open,
            CLKOUT0  => open,
            CLKOUT1  => open,
            CLKOUT2  => open,
            CLKOUT3  => open,
            CLKOUT4  => open,
            CLKOUT5  => open,
            LOCKED   => pll_locked,
            CLKFBIN  => clkout0_bufg,
            CLKIN1   => CLK_ALIGN_120,
            PWRDWN   => '0',
            RST      => pll_reset
        );  

    -- phase alignment FSM
    process(mmcm_ps_clk)
    begin
        if (rising_edge(mmcm_ps_clk)) then
            if (MMCM_RESET_IN = '1') then
                pa_state <= IDLE;
                pll_reset <= '1';
                mmcm_ps_en <= '0';
                pll_lock_wait_timer <= (others => '0'); 
            else
                case pa_state is
                    when IDLE =>
                        if (mmcm_locked = '1') then
                            pa_state <= CHECK_PHASE;
                        end if;
                        
                        pll_reset <= '1';
                        mmcm_ps_en <= '0';
                        pll_lock_wait_timer <= (others => '0');
                        mmcm_ps_done_timer <= (others => '0');
                        
                    when CHECK_PHASE =>
                        if (pll_locked = '1') then
                            pa_state <= SYNC_DONE;
                        else
                            if (pll_lock_wait_timer = 0) then
                                pll_reset <= '1';
                                pll_lock_wait_timer <= pll_lock_wait_timer + 1;
                            elsif (pll_lock_wait_timer = PLL_LOCK_WAIT_TIMEOUT) then
                                pa_state <= SHIFT_PHASE;
                                pll_reset <= '1';
                                pll_lock_wait_timer <= (others => '0');
                            else
                                pll_lock_wait_timer <= pll_lock_wait_timer + 1;
                                pll_reset <= '0';
                            end if;
                        end if;
                        
                        mmcm_ps_en <= '0';
                        mmcm_ps_done_timer <= (others => '0');
                        
                    when SHIFT_PHASE =>
                        mmcm_ps_en <= '1';
                        pa_state <= WAIT_SHIFT_DONE;
                        pll_reset <= '1';
                        mmcm_ps_done_timer <= (others => '0');

                    when WAIT_SHIFT_DONE =>
                        mmcm_ps_en <= '0';
                        pll_reset <= '1';

                        if ((mmcm_ps_done = '1') and (mmcm_locked = '1')) then
                            pa_state <= CHECK_PHASE;
                        else
                            -- datasheet says MMCM should lock in 12 clock cycles and assert mmcm_ps_done for one clock period, but we have a timeout just in case
                            if (mmcm_ps_done_timer = MMCM_PS_DONE_TIMEOUT) then
                                pa_state <= IDLE;
                                mmcm_ps_done_timer <= (others => '0'); 
                            else
                                mmcm_ps_done_timer <= mmcm_ps_done_timer + 1;
                            end if;
                        end if;
                        
                    when SYNC_DONE =>
                        pa_state <= SYNC_DONE;
                        mmcm_ps_en <= '0';
                        
                    when others =>
                        pa_state <= IDLE;
                        mmcm_ps_en <= '0';
                        
                end case;
            end if;
        end if;
    end process;    

    i_mmcm_shift_counter : entity work.counter
        generic map(
            g_COUNTER_WIDTH  => 12,
            g_ALLOW_ROLLOVER => false
        )
        port map(
            ref_clk_i => mmcm_ps_clk,
            reset_i   => MMCM_RESET_IN,
            en_i      => mmcm_ps_en,
            count_o   => MMCM_SHIFT_CNT
        );

end xilinx;
