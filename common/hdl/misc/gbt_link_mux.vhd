------------------------------------------------------------------------------------------------------------------------------------------------------
-- Company: TAMU
-- Engineer: Evaldas Juska (evaldas.juska@cern.ch, evka85@gmail.com)
-- 
-- Create Date:    20:38:00 2016-08-30
-- Module Name:    GBT_LINK_MUX
-- Description:    This module is used to direct the GBT links either to the OH modules (standard operation) or to the GEM_TESTS module 
------------------------------------------------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gem_pkg.all;

entity gbt_link_mux is
    generic(
        g_NUM_OF_OHs                : integer;
        g_USE_3x_GBTs               : boolean
    );
    port(
        -- links
        gbt_rx_data_arr_i           : in  t_gbt_frame_array(g_NUM_OF_OHs - 1 downto 0);
        gbt_tx_data_arr_o           : out t_gbt_frame_array(g_NUM_OF_OHs - 1 downto 0);
        gbt_rx_ready_arr_i          : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        gbt_rx_valid_arr_i          : in  std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        
        extra_gbt_rx_data_arr_i     : in  t_gbt_frame_array((g_NUM_OF_OHs * 2) - 1 downto 0);
        extra_gbt_tx_data_arr_o     : out t_gbt_frame_array((g_NUM_OF_OHs * 2) - 1 downto 0);
        extra_gbt_rx_ready_arr_i    : in  std_logic_vector((g_NUM_OF_OHs * 2) - 1 downto 0);
        extra_gbt_rx_valid_arr_i        : in  std_logic_vector((g_NUM_OF_OHs * 2) - 1 downto 0);
        
        -- configure
        link_test_mode_i            : in std_logic;
        
        -- to OHv2
        ohv2_gbt_rx_data_arr_o      : out t_gbt_frame_array(g_NUM_OF_OHs - 1 downto 0);
        ohv2_gbt_tx_data_arr_i      : in  t_gbt_frame_array(g_NUM_OF_OHs - 1 downto 0);
        ohv2_gbt_ready_arr_o        : out std_logic_vector(g_NUM_OF_OHs - 1 downto 0);
        
        -- to tests module
        tst_gbt_rx_data_arr_o       : out t_gbt_frame_array((g_NUM_OF_OHs * 3) - 1 downto 0);
        tst_gbt_tx_data_arr_i       : in  t_gbt_frame_array((g_NUM_OF_OHs * 3) - 1 downto 0);
        tst_gbt_ready_arr_o         : out std_logic_vector((g_NUM_OF_OHs * 3) - 1 downto 0)
    );
end gbt_link_mux;

architecture Behavioral of gbt_link_mux is

begin

    ohv2_gbt_rx_data_arr_o <= gbt_rx_data_arr_i when link_test_mode_i = '0' else (others => (others => '0'));
    ohv2_gbt_ready_arr_o <= gbt_rx_ready_arr_i when link_test_mode_i = '0' else (others => '0');
    gbt_tx_data_arr_o <= ohv2_gbt_tx_data_arr_i when link_test_mode_i = '0' else tst_gbt_tx_data_arr_i(g_NUM_OF_OHs - 1 downto 0);
    
    tst_gbt_rx_data_arr_o(g_NUM_OF_OHs - 1 downto 0) <= gbt_rx_data_arr_i when link_test_mode_i = '1' else (others => (others => '0'));
    tst_gbt_ready_arr_o(g_NUM_OF_OHs - 1 downto 0) <= gbt_rx_ready_arr_i when link_test_mode_i = '1' else (others => '0');
    
    gen_3x_gbt_test_links : if g_USE_3x_GBTs generate
        tst_gbt_rx_data_arr_o((g_NUM_OF_OHs * 3) - 1 downto g_NUM_OF_OHs) <= extra_gbt_rx_data_arr_i when link_test_mode_i = '1' else (others => (others => '0'));
        tst_gbt_ready_arr_o((g_NUM_OF_OHs * 3) - 1 downto g_NUM_OF_OHs) <= extra_gbt_rx_ready_arr_i when link_test_mode_i = '1' else (others => '0');
        extra_gbt_tx_data_arr_o <= tst_gbt_tx_data_arr_i((g_NUM_OF_OHs * 3) - 1 downto g_NUM_OF_OHs) when link_test_mode_i = '1' else (others => (others => '0'));
    end generate;

end Behavioral;
