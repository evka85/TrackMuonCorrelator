-------------------------------------------------------------------------------
--                                                                            
--       Unit Name: io_link_3p2g_demo_ctrl                                            
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

--============================================================================
--                                                          Entity declaration
--============================================================================
entity io_link_3p2g_demo_ctrl is
  port (
    clk_160_bc_i : in std_logic;
    ttc_cmds_i   : in t_ttc_cmds;

    clk_gth_tx_usrclk_i : in std_logic_vector(11 downto 0);
    clk_gth_rx_usrclk_i : in std_logic_vector(11 downto 0);

    gth_tx_data_o : out t_gth_tx_data_arr(11 downto 0);
    gth_rx_data_i : in  t_gth_rx_data_arr(11 downto 0);

    enable_tx_cdc_fifo_i : std_logic_vector(11 downto 0);
    enable_rx_cdc_fifo_i : std_logic_vector(11 downto 0);

    rx_capture_ctrl_i   : in  t_capture_ctrl_arr(11 downto 0);
    rx_capture_status_o : out t_capture_status_arr(11 downto 0);

    BRAM_CTRL_RX_RAM_addr : in  std_logic_vector (16 downto 0);
    BRAM_CTRL_RX_RAM_clk  : in  std_logic;
    BRAM_CTRL_RX_RAM_din  : in  std_logic_vector (31 downto 0);
    BRAM_CTRL_RX_RAM_dout : out std_logic_vector (31 downto 0);
    BRAM_CTRL_RX_RAM_en   : in  std_logic;
    BRAM_CTRL_RX_RAM_rst  : in  std_logic;
    BRAM_CTRL_RX_RAM_we   : in  std_logic_vector (3 downto 0);

    BRAM_CTRL_TX_RAM_addr : in  std_logic_vector (16 downto 0);
    BRAM_CTRL_TX_RAM_clk  : in  std_logic;
    BRAM_CTRL_TX_RAM_din  : in  std_logic_vector (31 downto 0);
    BRAM_CTRL_TX_RAM_dout : out std_logic_vector (31 downto 0);
    BRAM_CTRL_TX_RAM_en   : in  std_logic;
    BRAM_CTRL_TX_RAM_rst  : in  std_logic;
    BRAM_CTRL_TX_RAM_we   : in  std_logic_vector (3 downto 0)
    );
end io_link_3p2g_demo_ctrl;

--============================================================================
--                                                          Architecture begin
--============================================================================
architecture io_link_3p2g_demo_ctrl_arch of io_link_3p2g_demo_ctrl is

--============================================================================
--                                                           Type declarations
--============================================================================
  type t_BRAM_dout_arr_12 is array (11 downto 0) of std_logic_vector(31 downto 0);

--============================================================================
--                                                         Signal declarations
--============================================================================
  signal s_BRAM_CTRL_RX_RAM_dout_arr : t_BRAM_dout_arr_12;
  signal s_BRAM_CTRL_TX_RAM_dout_arr : t_BRAM_dout_arr_12;

  signal s_BRAM_CTRL_RX_RAM_we : std_logic_vector(11 downto 0);
  signal s_BRAM_CTRL_TX_RAM_we : std_logic_vector(11 downto 0);

  signal s_BRAM_CTRL_RX_RAM_rst : std_logic_vector(11 downto 0);
  signal s_BRAM_CTRL_TX_RAM_rst : std_logic_vector(11 downto 0);

  component io_link_3p2g_demo
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
  end component io_link_3p2g_demo;

--============================================================================
--                                                          Architecture begin
--============================================================================
begin

  gen_io_link_3p2g_demo : for i in 0 to 11 generate
    i_io_link_3p2g_demo : io_link_3p2g_demo
      generic map(
        g_link_num => i
        )
      port map(
        clk_160_bc_i => clk_160_bc_i,
        ttc_cmds_i   => ttc_cmds_i,

        clk_gth_tx_usrclk_i => clk_gth_tx_usrclk_i(i),
        clk_gth_rx_usrclk_i => clk_gth_rx_usrclk_i(i),

        gth_tx_data_o => gth_tx_data_o(i),
        gth_rx_data_i => gth_rx_data_i(i),

        enable_tx_cdc_fifo_i => enable_tx_cdc_fifo_i(i),
        enable_rx_cdc_fifo_i => enable_rx_cdc_fifo_i(i),

        rx_capture_ctrl_i   => rx_capture_ctrl_i(i),
        rx_capture_status_o => rx_capture_status_o(i),

        BRAM_CTRL_RX_RAM_addr => BRAM_CTRL_RX_RAM_addr(11 downto 0),
        BRAM_CTRL_RX_RAM_clk  => BRAM_CTRL_RX_RAM_clk,
        BRAM_CTRL_RX_RAM_din  => BRAM_CTRL_RX_RAM_din,
        BRAM_CTRL_RX_RAM_dout => s_BRAM_CTRL_RX_RAM_dout_arr(i),
        BRAM_CTRL_RX_RAM_en   => BRAM_CTRL_RX_RAM_en,
        BRAM_CTRL_RX_RAM_rst  => s_BRAM_CTRL_RX_RAM_rst(i),
        BRAM_CTRL_RX_RAM_we   => s_BRAM_CTRL_RX_RAM_we(i),

        BRAM_CTRL_TX_RAM_addr => BRAM_CTRL_TX_RAM_addr(11 downto 0),
        BRAM_CTRL_TX_RAM_clk  => BRAM_CTRL_TX_RAM_clk,
        BRAM_CTRL_TX_RAM_din  => BRAM_CTRL_TX_RAM_din,
        BRAM_CTRL_TX_RAM_dout => s_BRAM_CTRL_TX_RAM_dout_arr(i),
        BRAM_CTRL_TX_RAM_en   => BRAM_CTRL_TX_RAM_en,
        BRAM_CTRL_TX_RAM_rst  => s_BRAM_CTRL_TX_RAM_rst(i),
        BRAM_CTRL_TX_RAM_we   => s_BRAM_CTRL_TX_RAM_we(i)
        );
  end generate;

  s_BRAM_CTRL_RX_RAM_we(0)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"0") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(1)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"1") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(2)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"2") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(3)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"3") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(4)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"4") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(5)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"5") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(6)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"6") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(7)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"7") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(8)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"8") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(9)  <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"9") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(10) <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"A") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';
  s_BRAM_CTRL_RX_RAM_we(11) <= '1' when ((BRAM_CTRL_RX_RAM_addr(16 downto 12) = '0' & x"B") and (BRAM_CTRL_RX_RAM_we = x"F")) else '0';

  process(BRAM_CTRL_RX_RAM_addr(16 downto 12))
  begin

    s_BRAM_CTRL_RX_RAM_rst <= (others => '1');

    case(BRAM_CTRL_RX_RAM_addr(16 downto 12)) is
      when '0' & x"0" => s_BRAM_CTRL_RX_RAM_rst(0) <= '0';
    when '0' & x"1" => s_BRAM_CTRL_RX_RAM_rst(1)  <= '0';
    when '0' & x"2" => s_BRAM_CTRL_RX_RAM_rst(2)  <= '0';
    when '0' & x"3" => s_BRAM_CTRL_RX_RAM_rst(3)  <= '0';
    when '0' & x"4" => s_BRAM_CTRL_RX_RAM_rst(4)  <= '0';
    when '0' & x"5" => s_BRAM_CTRL_RX_RAM_rst(5)  <= '0';
    when '0' & x"6" => s_BRAM_CTRL_RX_RAM_rst(6)  <= '0';
    when '0' & x"7" => s_BRAM_CTRL_RX_RAM_rst(7)  <= '0';
    when '0' & x"8" => s_BRAM_CTRL_RX_RAM_rst(8)  <= '0';
    when '0' & x"9" => s_BRAM_CTRL_RX_RAM_rst(9)  <= '0';
    when '0' & x"A" => s_BRAM_CTRL_RX_RAM_rst(10) <= '0';
    when others     => s_BRAM_CTRL_RX_RAM_rst(11) <= '0';

  end case;
end process;

s_BRAM_CTRL_TX_RAM_we(0)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"0") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(1)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"1") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(2)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"2") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(3)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"3") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(4)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"4") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(5)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"5") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(6)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"6") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(7)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"7") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(8)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"8") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(9)  <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"9") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(10) <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"A") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';
s_BRAM_CTRL_TX_RAM_we(11) <= '1' when ((BRAM_CTRL_TX_RAM_addr(16 downto 12) = '0' & x"B") and (BRAM_CTRL_TX_RAM_we = x"F")) else '0';

process(BRAM_CTRL_TX_RAM_addr(16 downto 12))
begin

  s_BRAM_CTRL_TX_RAM_rst <= (others => '1');

  case(BRAM_CTRL_TX_RAM_addr(16 downto 12)) is
    when '0' & x"0" => s_BRAM_CTRL_TX_RAM_rst(0) <= '0';
  when '0' & x"1" => s_BRAM_CTRL_TX_RAM_rst(1)  <= '0';
  when '0' & x"2" => s_BRAM_CTRL_TX_RAM_rst(2)  <= '0';
  when '0' & x"3" => s_BRAM_CTRL_TX_RAM_rst(3)  <= '0';
  when '0' & x"4" => s_BRAM_CTRL_TX_RAM_rst(4)  <= '0';
  when '0' & x"5" => s_BRAM_CTRL_TX_RAM_rst(5)  <= '0';
  when '0' & x"6" => s_BRAM_CTRL_TX_RAM_rst(6)  <= '0';
  when '0' & x"7" => s_BRAM_CTRL_TX_RAM_rst(7)  <= '0';
  when '0' & x"8" => s_BRAM_CTRL_TX_RAM_rst(8)  <= '0';
  when '0' & x"9" => s_BRAM_CTRL_TX_RAM_rst(9)  <= '0';
  when '0' & x"A" => s_BRAM_CTRL_TX_RAM_rst(10) <= '0';
  when others     => s_BRAM_CTRL_TX_RAM_rst(11) <= '0';

end case;
end process;

gen_RAM_RX_dout : for j in 0 to 31 generate
begin
  BRAM_CTRL_RX_RAM_dout(j) <=
    s_BRAM_CTRL_RX_RAM_dout_arr(0)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(1)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(2)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(3)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(4)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(5)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(6)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(7)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(8)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(9)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(10)(j) or
    s_BRAM_CTRL_RX_RAM_dout_arr(11)(j);

end generate;

    gen_RAM_TX_dout : for j in 0 to 31 generate
    begin
      BRAM_CTRL_TX_RAM_dout(j) <=
        s_BRAM_CTRL_TX_RAM_dout_arr(0)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(1)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(2)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(3)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(4)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(5)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(6)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(7)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(8)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(9)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(10)(j) or
        s_BRAM_CTRL_TX_RAM_dout_arr(11)(j);

    end generate;

 end io_link_3p2g_demo_ctrl_arch;
--============================================================================
--                                                            Architecture end
--============================================================================

