-- mp7_link
--
-- Wrapper for 10G link code provided by nice MP7 folks
--
-- Adrian Byszuk

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.ipbus.all;
use work.mp7_data_types.all;
use work.mp7_ttc_decl.all;
use work.mp7_readout_decl.all;
use work.ipbus_decode_mp7.all;

entity mp7_link_sim is
generic(
    constant N_REGION : natural := 4;
    constant N_REFCLK : natural := 4);
port(
    ipb_clk: in std_logic; -- ipbus clock, rst, bus
    ipb_rst: in std_logic;
    ipb_in: in ipb_wbus;
     ipb_out: out ipb_rbus
);
end mp7_link_sim;

architecture rtl of mp7_link_sim is

signal ipb_in_ctrl, ipb_in_ttc, ipb_in_datapath : ipb_wbus;
signal ipb_out_ctrl, ipb_out_ttc, ipb_out_datapath : ipb_rbus;

signal ipbw: ipb_wbus_array(N_SLAVES-1 downto 0);
signal ipbr: ipb_rbus_array(N_SLAVES-1 downto 0);

signal clk40_i, clk_p_i, rst_p_i, clk40_rst, clk40_sel, clk40_lock, clk40_stop, nuke, soft_rst : std_logic;
signal dist_lock, oc_flag, ec_flag : std_logic;
signal ttc_cmd, ttc_cmd_dist: ttc_cmd_t;
signal bunch_ctr: std_logic_vector(11 downto 0);
signal evt_ctr, orb_ctr: std_logic_vector(23 downto 0);
signal qsel: std_logic_vector(7 downto 0);
signal ctrs: ttc_stuff_array(N_REGION - 1 downto 0);
signal rst_loc, clken_loc: std_logic_vector(N_REGION - 1 downto 0);
signal cap_bus: daq_cap_bus;
signal daq_bus_top, daq_bus_bot: daq_bus;
signal data: ldata(N_REGION * 4 - 1 downto 0);
	
signal clkmon: std_logic_vector(2 downto 0);
signal clk125 : std_logic := '0';
signal refclk : std_logic_vector(N_REFCLK-1 downto 0);

begin
--REFCLK generation
clk125 <= not(clk125) after 4 ns;
refclk_gen: for i in refclk'high downto 0 generate
   begin
      refclk(i) <= clk125;
   end generate;

ctrl: entity work.mp7_ctrl
port map(
   clk => ipb_clk,
   rst => ipb_rst,
   ipb_in => ipb_in_ctrl,
   ipb_out => ipb_out_ctrl,
   nuke => nuke,
   soft_rst => soft_rst,
   qsel => qsel,
   clk40_rst => clk40_rst,
   clk40_sel => clk40_sel,
   clk40_lock => clk40_lock,
   clk40_stop => clk40_stop
);
   
-- TTC signal handling
ttc: entity work.mp7_ttc_sim
port map(
    clk => ipb_clk,
    rst => ipb_rst,
    mmcm_rst => ipb_rst,
    sel => '1', --backplane clock
    lock => clk40_lock,
    stop => clk40_stop,
    ipb_in => ipb_in_ttc,
    ipb_out => ipb_out_ttc,
    clk40 => clk40_i,
    rsto40 => open,
    clk_p => clk_p_i,
    rst_p => rst_p_i,
    clk_payload => open,
    rst_payload => open,
    ttc_cmd => ttc_cmd,
    ttc_cmd_dist => ttc_cmd_dist,
    dist_lock => dist_lock,
    bunch_ctr => bunch_ctr,
    evt_ctr => evt_ctr,
    orb_ctr => orb_ctr,
    oc_flag => oc_flag,
    ec_flag => ec_flag,
    monclk => clkmon
);

-- MGTs, buffers and TTC fanout
datapath: entity work.mp7_datapath
port map(
   clk => ipb_clk,
   rst => ipb_rst,
   ipb_in => ipb_in_datapath,
   ipb_out => ipb_out_datapath,
   qsel => qsel,
   clk40 => clk40_i,
   clk_p => clk_p_i,
   rst_p => rst_p_i,
   ttc_cmd => ttc_cmd_dist,
   lock => dist_lock,
   ctrs_out => ctrs,
   rst_out => rst_loc,
   clken_out => clken_loc,
   cap_bus => cap_bus,
   daq_bus_in => daq_bus_top,
   daq_bus_out => daq_bus_bot,
   payload_bc0 => '0',
   refclk => refclk,
   clkmon => clkmon,
   q => data,
   d => data
);

-- ipbus address decode
		
fabric: entity work.ipbus_fabric_sel
generic map(
   NSLV => N_SLAVES,
   SEL_WIDTH => IPBUS_SEL_WIDTH
)
port map(
   ipb_in => ipb_in,
   ipb_out => ipb_out,
   sel => ipbus_sel_mp7(ipb_in.ipb_addr),
   ipb_to_slaves => ipbw,
   ipb_from_slaves => ipbr
);

ipbr(N_SLV_CTRL) <= ipb_out_ctrl;
ipb_in_ctrl <= ipbw(N_SLV_CTRL);
ipbr(N_SLV_TTC) <= ipb_out_ttc;
ipb_in_ttc <= ipbw(N_SLV_TTC);
ipbr(N_SLV_DATAPATH) <= ipb_out_datapath;
ipb_in_datapath <= ipbw(N_SLV_DATAPATH);

end rtl;