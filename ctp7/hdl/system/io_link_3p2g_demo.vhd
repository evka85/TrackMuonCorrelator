-------------------------------------------------------------------------------
--                                                                            
--       Unit Name: io_link_3p2g_demo                                            
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
use IEEE.NUMERIC_STD.all;
use work.ttc_pkg.all;
use work.gth_pkg.all;
use work.capture_playback_pkg.all;
use work.ctp7_utils_pkg.all;

entity io_link_3p2g_demo is
  generic(
    g_link_num : integer
    );
  port (
    clk_160_bc_i : in std_logic;
    ttc_cmds_i   : in t_ttc_cmds;

    clk_gth_tx_usrclk_i : in std_logic;
    clk_gth_rx_usrclk_i : in std_logic;

    gth_tx_data_o : out t_gth_tx_data;
    gth_rx_data_i : in  t_gth_rx_data;

    enable_tx_cdc_fifo_i : std_logic;
    enable_rx_cdc_fifo_i : std_logic;

    rx_capture_ctrl_i   : in  t_capture_ctrl;
    rx_capture_status_o : out t_capture_status;

    BRAM_CTRL_RX_RAM_addr : in  std_logic_vector (11 downto 0);
    BRAM_CTRL_RX_RAM_clk  : in  std_logic;
    BRAM_CTRL_RX_RAM_din  : in  std_logic_vector (31 downto 0);
    BRAM_CTRL_RX_RAM_dout : out std_logic_vector (31 downto 0);
    BRAM_CTRL_RX_RAM_en   : in  std_logic;
    BRAM_CTRL_RX_RAM_rst  : in  std_logic;
    BRAM_CTRL_RX_RAM_we   : in  std_logic;

    BRAM_CTRL_TX_RAM_addr : in  std_logic_vector (11 downto 0);
    BRAM_CTRL_TX_RAM_clk  : in  std_logic;
    BRAM_CTRL_TX_RAM_din  : in  std_logic_vector (31 downto 0);
    BRAM_CTRL_TX_RAM_dout : out std_logic_vector (31 downto 0);
    BRAM_CTRL_TX_RAM_en   : in  std_logic;
    BRAM_CTRL_TX_RAM_rst  : in  std_logic;
    BRAM_CTRL_TX_RAM_we   : in  std_logic

    );
end io_link_3p2g_demo;

architecture io_link_3p2g_demo_arch of io_link_3p2g_demo is

--============================================================================
--                                                     Constant   declarations
--============================================================================

constant C_ILA_PROBE_CH : integer := 6; -- DUT CH for ILA debugging

--============================================================================
--                                                           Type declarations
--============================================================================
  type t_capture_state_type is (
    idle_state,
    ready_state,
    capture_state,
    done_state
    );

  component fifo_cdc_18b
    port (
      rst    : in  std_logic;
      wr_clk : in  std_logic;
      rd_clk : in  std_logic;
      din    : in  std_logic_vector(17 downto 0);
      wr_en  : in  std_logic;
      rd_en  : in  std_logic;
      dout   : out std_logic_vector(17 downto 0);
      full   : out std_logic;
      empty  : out std_logic
      );
  end component fifo_cdc_18b;

  component ila_tx_rx_3p2g
    port (
      clk : in std_logic;
      probe0 : in std_logic_vector(15 downto 0);
      probe1 : in std_logic_vector(1 downto 0);
      probe2 : in std_logic_vector(15 downto 0);
      probe3 : in std_logic_vector(1 downto 0)
      );
  end component ila_tx_rx_3p2g;

  component capture_ram is
    port (
      --Port A
      RSTA  : in  std_logic;            --opt port
      ENA   : in  std_logic;            --opt port
      WEA   : in  std_logic_vector(0 downto 0);
      ADDRA : in  std_logic_vector(9 downto 0);
      DINA  : in  std_logic_vector(31 downto 0);
      DOUTA : out std_logic_vector(31 downto 0);
      CLKA  : in  std_logic;
      --Port B
      ENB   : in  std_logic;            --opt port
      WEB   : in  std_logic_vector(0 downto 0);
      ADDRB : in  std_logic_vector(9 downto 0);
      DINB  : in  std_logic_vector(31 downto 0);
      DOUTB : out std_logic_vector(31 downto 0);
      CLKB  : in  std_logic
      );
  end component;

  component playback_capture_ram is
    port (
      --Port A
      RSTA  : in  std_logic;            --opt port
      ENA   : in  std_logic;            --opt port
      WEA   : in  std_logic_vector(0 downto 0);
      ADDRA : in  std_logic_vector(9 downto 0);
      DINA  : in  std_logic_vector(31 downto 0);
      DOUTA : out std_logic_vector(31 downto 0);
      CLKA  : in  std_logic;
      --Port B
      ENB   : in  std_logic;            --opt port
      WEB   : in  std_logic_vector(0 downto 0);
      ADDRB : in  std_logic_vector(9 downto 0);
      DINB  : in  std_logic_vector(31 downto 0);
      DOUTB : out std_logic_vector(31 downto 0);
      CLKB  : in  std_logic
      );
  end component;

--============================================================================
--                                                         Signal declarations
--============================================================================

  signal s_rst_TX_cdc_fifo   : std_logic;
  signal s_wr_en_TX_cdc_fifo : std_logic;
  signal s_rd_en_TX_cdc_fifo : std_logic;
  signal s_empty_TX_cdc_fifo : std_logic;
  signal s_enable_tx_d4      : std_logic_vector(3 downto 0);

  signal s_playback_cycle : unsigned(9 downto 0);

  signal s_playback_data : std_logic_vector(15 downto 0);
  signal s_playback_charisk : std_logic_vector(1 downto 0);

  signal s_tx_charisk : std_logic_vector(1 downto 0);
  signal s_tx_data    : std_logic_vector(15 downto 0);

  signal s_rst_RX_cdc_fifo   : std_logic;
  signal s_wr_en_RX_cdc_fifo : std_logic;
  signal s_rd_en_RX_cdc_fifo : std_logic;
  signal s_empty_RX_cdc_fifo : std_logic;
  signal s_enable_Rx_d4      : std_logic_vector(3 downto 0);


  signal s_rx_charisk : std_logic_vector(1 downto 0);
  signal s_rx_data    : std_logic_vector(15 downto 0);

  signal s_capture_data : std_logic_vector(17 downto 0);

  signal s_cap_en_cs : t_capture_state_type := idle_state;
  signal s_cap_en_ns : t_capture_state_type := idle_state;

  signal s_rst_sync : std_logic;

  signal s_capture_cycle  : unsigned(9 downto 0);
  signal s_capture_ram_we : std_logic;


  signal s_capture_arm_RE : std_logic;

  signal s_capture_arm_sync : std_logic;
  signal s_cap_trigger      : std_logic;

  signal s_data_dX : std_logic_vector(31 downto 0);

  signal s_capture_done              : std_logic;
  signal s_capture_fsm_state         : std_logic_vector(3 downto 0);
  signal s_capture_start_local_BX_id : std_logic_vector(11 downto 0);
  signal s_capture_start_link_BX_id  : std_logic_vector(11 downto 0);

  signal s_notintable_cnt            : unsigned(31 downto 0) := (others => '0');
  signal s_disperr_cnt               : unsigned(31 downto 0)  := (others => '0');

--============================================================================
--                                                          Architecture begin
--============================================================================

begin
----------------------------------------------------------------------
-- Output Logic
----------------------------------------------------------------------

  process(clk_160_bc_i) is
  begin
    if rising_edge(clk_160_bc_i) then
      s_playback_cycle <= s_playback_cycle + 1;
    end if;
  end process;

  i_playback_ram : playback_capture_ram
    port map (
      --Port A
      RSTA                => BRAM_CTRL_TX_RAM_rst,
      ENA                 => BRAM_CTRL_TX_RAM_en,
      WEA(0)              => BRAM_CTRL_TX_RAM_we,
      ADDRA               => BRAM_CTRL_TX_RAM_addr(11 downto 2),
      DINA                => BRAM_CTRL_TX_RAM_din,
      DOUTA               => BRAM_CTRL_TX_RAM_dout,
      CLKA                => BRAM_CTRL_TX_RAM_clk,
      --Port B
      ENB                 => '1',
      WEB(0)              => '0',
      ADDRB               => std_logic_vector(s_playback_cycle),
      DINB                => x"00000000",
      DOUTB(15 downto 0)  => s_playback_data,
      DOUTB(17 downto 16) => s_playback_charisk,
      DOUTB(31 downto 18) => open,
      CLKB                => clk_160_bc_i

      );

  process(clk_160_bc_i)
  begin
    if rising_edge(clk_160_bc_i) then
      s_enable_tx_d4(3 downto 0) <= s_enable_tx_d4(2 downto 0) & enable_tx_cdc_fifo_i;
    end if;
  end process;

  s_rst_TX_cdc_fifo   <= not enable_tx_cdc_fifo_i;
  s_wr_en_TX_cdc_fifo <= s_enable_tx_d4(3);

  s_rd_en_TX_cdc_fifo <= not s_empty_TX_cdc_fifo;

  i_fifo_cdc_18b_tx : fifo_cdc_18b
    port map (
      rst    => s_rst_TX_cdc_fifo,
      wr_clk => clk_160_bc_i,
      rd_clk => clk_gth_tx_usrclk_i,

      din(15 downto 0)  => s_playback_data,
      din(17 downto 16) => s_playback_charisk,

      wr_en              => s_wr_en_TX_cdc_fifo,
      rd_en              => s_rd_en_TX_cdc_fifo,
      dout(17 downto 16) => s_tx_charisk,
      dout(15 downto 0)  => s_tx_data,
      full               => open,
      empty              => s_empty_TX_cdc_fifo
      );


  gth_tx_data_o.txcharisk(1 downto 0) <= s_tx_charisk;
  gth_tx_data_o.txdata(15 downto 0)   <= s_tx_data;

----------------------------------------------------------------------
-- Input Logic
----------------------------------------------------------------------

  process(clk_160_bc_i)
  begin
    if rising_edge(clk_160_bc_i) then
      s_enable_rx_d4(3 downto 0) <= s_enable_rx_d4(2 downto 0) & enable_rx_cdc_fifo_i;
    end if;
  end process;

  s_rst_RX_cdc_fifo   <= not enable_rx_cdc_fifo_i;
  s_wr_en_RX_cdc_fifo <= s_enable_rx_d4(3);

  s_rd_en_RX_cdc_fifo <= not s_empty_RX_cdc_fifo;

  i_fifo_cdc_18b_rx : fifo_cdc_18b
    port map (
      rst    => s_rst_TX_cdc_fifo,
      wr_clk => clk_gth_rx_usrclk_i,

      rd_clk            => clk_160_bc_i,
      din(17 downto 16) => gth_rx_data_i.rxcharisk(1 downto 0),
      din(15 downto 0)  => gth_rx_data_i.rxdata(15 downto 0),

      wr_en              => s_wr_en_RX_cdc_fifo,
      rd_en              => s_rd_en_RX_cdc_fifo,
      dout(17 downto 16) => s_rx_charisk,
      dout(15 downto 0)  => s_rx_data,
      full               => open,
      empty              => s_empty_RX_cdc_fifo
      );

  s_capture_data <= (s_rx_charisk & s_rx_data) when rising_edge(clk_160_bc_i);

  i_capture_arm_sync : synchronizer
    generic map (
      N_STAGES => 2
      )
    port map(
      async_i => rx_capture_ctrl_i.arm,
      clk_i   => clk_160_bc_i,
      sync_o  => s_capture_arm_sync
      );

  i_capture_arm_edge : edge_detect
    port map(
      clk  => clk_160_bc_i,
      sig  => s_capture_arm_sync,
      edge => s_capture_arm_RE
      );

  i_rst_sync : synchronizer
    generic map (
      N_STAGES => 2
      )
    port map(
      clk_i   => clk_160_bc_i,
      async_i => rx_capture_ctrl_i.rst,
      sync_o  => s_rst_sync
      );

  process(clk_160_bc_i) is
  begin
    if (rising_edge(clk_160_bc_i)) then

      if(s_rx_charisk(0) = '1' and s_rx_data(7 downto 0) = x"BC") then
        s_cap_trigger <= '1';
      else
        s_cap_trigger <= '0';
      end if;
    end if;
  end process;

  p_fsm_capture_current_state : process(clk_160_bc_i) is
  begin
    if (rising_edge(clk_160_bc_i)) then
      if (s_rst_sync = '1') then
        s_cap_en_cs <= idle_state;
      else
        s_cap_en_cs <= s_cap_en_ns;
      end if;
    end if;
  end process;

  p_fsm_capture_next_state : process(s_cap_en_cs,
                                     s_capture_arm_RE,
                                     s_capture_cycle,
                                     s_cap_trigger,
                                     s_cap_trigger) is
  begin

    s_cap_en_ns <= s_cap_en_cs;

    case s_cap_en_cs is

      when idle_state =>
        if (s_capture_arm_RE = '1') then
          s_cap_en_ns <= ready_state;
        end if;

      when ready_state =>
        if (s_cap_trigger = '1') then
          s_cap_en_ns <= capture_state;
        end if;

      when capture_state =>
        if (s_capture_cycle = 1023) then
          s_cap_en_ns <= done_state;
        end if;

      when done_state =>
        if (s_capture_arm_RE = '1') then
          s_cap_en_ns <= ready_state;
        end if;

      when others =>
        s_cap_en_ns <= idle_state;

    end case;
  end process;

  rx_capture_status_o.fsm_state <= s_capture_fsm_state;
  rx_capture_status_o.done      <= s_capture_done;

  p_fsm_capture_outputs : process(clk_160_bc_i) is
  begin

    if rising_edge(clk_160_bc_i) then
      s_capture_cycle  <= (others => '0');
      s_capture_ram_we <= '0';
      s_capture_done   <= '0';

      case s_cap_en_cs is

        when idle_state =>
          s_capture_fsm_state <= x"0";

        when ready_state =>
          s_capture_fsm_state <= x"1";
          if (s_cap_trigger = '1') then
            s_capture_ram_we <= '1';
          end if;

        when capture_state =>
          s_capture_fsm_state <= x"2";
          s_capture_ram_we    <= '1';
          s_capture_cycle     <= s_capture_cycle + 1;
          if (s_capture_cycle = 1023) then
            s_capture_ram_we <= '0';
          end if;

        when done_state =>
          s_capture_fsm_state <= x"3";
          s_capture_done      <= '1';

        when others =>
          s_capture_fsm_state <= x"0";

      end case;
    end if;
  end process;

  i_capture_ram : playback_capture_ram
    port map (
      --Port A
      RSTA               => BRAM_CTRL_RX_RAM_rst,
      ENA                => BRAM_CTRL_RX_RAM_en,
      WEA(0)             => BRAM_CTRL_RX_RAM_we,
      ADDRA              => BRAM_CTRL_RX_RAM_addr(11 downto 2),
      DINA               => BRAM_CTRL_RX_RAM_din,
      DOUTA              => BRAM_CTRL_RX_RAM_dout,
      CLKA               => BRAM_CTRL_RX_RAM_clk,
      --Port B
      ENB                => '1',
      WEB(0)             => s_capture_ram_we,
      ADDRB              => std_logic_vector(s_capture_cycle),
      DINB(17 downto 0)  => s_capture_data,
      DINB(31 downto 18) => "00000000000000",
      DOUTB              => open,
      CLKB               => clk_160_bc_i

      );
      
--============================================================================
-- ILA Debug Core: Data and Charisk, TX and RX
-- Only a single channel for debug: C_ILA_PROBE_CH

  gen_ila : if g_link_num = C_ILA_PROBE_CH generate
        i_ila_tx_rx_3p2g : ila_tx_rx_3p2g
          port map(
            clk    => clk_160_bc_i,
            probe0 => s_playback_data,
            probe1 => s_playback_charisk,
            probe2 => s_rx_data,
            probe3 => s_rx_charisk
            --probe4 => gth_rx_data_i.rxnotintable,
            --probe5 => gth_rx_data_i.rxdisperr
         );
      end generate;
      
end io_link_3p2g_demo_arch;

--============================================================================
--                                                            Architecture end
--============================================================================

