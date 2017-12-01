-------------------------------------------------------------------------------
--                                                                            
--       Unit Name: io_link_4p8g_demo_ctrl                                            
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

use work.gth_pkg.all;

--============================================================================
--                                                          Entity declaration
--============================================================================
entity io_link_4p8g_demo_ctrl is
  port (

    clk_gth_tx_usrclk_i : in std_logic_vector(23 downto 0);
    clk_gth_rx_usrclk_i : in std_logic_vector(23 downto 0);

    gth_tx_data_o : out t_gth_tx_data_arr(23 downto 0);
    gth_rx_data_i : in  t_gth_rx_data_arr(23 downto 0);

    gth_rx_ctrl_2_arr_i : out t_gth_rx_ctrl_2_arr(23 downto 0)

    );
end io_link_4p8g_demo_ctrl;

--============================================================================
--                                                        Architecture section
--============================================================================
architecture io_link_4p8g_demo_ctrl_arch of io_link_4p8g_demo_ctrl is

  component vio_4p8g
    port (
      clk        : in  std_logic;
      probe_in0  : in  std_logic_vector(31 downto 0);
      probe_out0 : out std_logic_vector(0 downto 0)
      );
  end component vio_4p8g;

  component ila_4p8g
    port (
      clk    : in std_logic;
      probe0 : in std_logic_vector(31 downto 0);
      probe1 : in std_logic_vector(3 downto 0);
      probe2 : in std_logic_vector(3 downto 0);
      probe3 : in std_logic_vector(3 downto 0);
      probe4 : in std_logic_vector(3 downto 0)
      );
  end component ila_4p8g;
--============================================================================
--                                                           Type declarations
--============================================================================
  type t_tx_pattern_cnt is array(integer range <>) of unsigned(15 downto 0);

--============================================================================
--                                                         Signal declarations
--============================================================================

  signal s_tx_pattern_cnt : t_tx_pattern_cnt(23 downto 0);
  signal s_rx_slide       : std_logic_vector(23 downto 0);
begin

  gen_tx_pattern : for i in 0 to 23 generate

    process(clk_gth_tx_usrclk_i(i)) is
    begin
      if rising_edge(clk_gth_tx_usrclk_i(i)) then
        s_tx_pattern_cnt(i) <= s_tx_pattern_cnt(i) + 1;
      end if;
    end process;

    gth_tx_data_o(i).txdata(15 downto 0)  <= std_logic_vector(s_tx_pattern_cnt(i));
    gth_tx_data_o(i).txdata(19 downto 16) <= x"A";
    gth_tx_data_o(i).txdata(31 downto 20) <= x"000";


    gth_tx_data_o(i).txcharisk      <= x"0";
    gth_tx_data_o(i).txchardispmode <= x"0";
    gth_tx_data_o(i).txchardispval  <= x"0";

  end generate;

  i_vio_4p8g : vio_4p8g
    port map(
      clk           => clk_gth_rx_usrclk_i(1),
      probe_in0     => gth_rx_data_i(1).rxdata,
      probe_out0(0) => s_rx_slide(1)
      );

  i_ila_4p8g : ila_4p8g
    port map(
      clk    => clk_gth_rx_usrclk_i(1),
      probe0 => gth_rx_data_i(1).rxdata,
      probe1 => gth_rx_data_i(1).rxdisperr,
      probe2 => gth_rx_data_i(1).rxnotintable,
      probe3 => gth_rx_data_i(1).rxchariscomma,
      probe4 => gth_rx_data_i(1).rxcharisk
      );

  gen_rx_slide : for i in 0 to 23 generate
    gth_rx_ctrl_2_arr_i(i).rxslide <= s_rx_slide(i);
  end generate;

end io_link_4p8g_demo_ctrl_arch;
--============================================================================
-- Architecture end
--============================================================================

