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

entity mp7_link is
generic(
    constant N_REGION : natural;
    constant N_REFCLK : natural);
port(
    ipb_clk: in std_logic; -- ipbus clock, rst, bus
    ipb_rst: in std_logic;
    ipb_in: in ipb_wbus;
    ipb_out: out ipb_rbus;
    clk40_in_p: in std_logic; -- TTC backplane clock signals
    clk40_in_n: in std_logic;
    ttc_in_p: in std_logic; -- TTC protocol backplane signas
    ttc_in_n: in std_logic;
    clk40: out std_logic; -- clock outputs
    rsto40: out std_logic; -- clock domain reset outputs
    clk80: out std_logic; -- clock outputs
    rsto80: out std_logic; -- clock domain reset outputs
    clk160: out std_logic; -- clock outputs
    rsto160: out std_logic; -- clock domain reset outputs
    clk320: out std_logic; -- clock outputs
    rsto320: out std_logic; -- clock domain reset outputs
    --
    ttc_data : out std_logic_vector(1 downto 0);
    ttc_bc0 : out std_logic;
    ttc_resync : out std_logic;
    --
    clk_p: out std_logic;
    rst_p: out std_logic;
    payload_bc0: in std_logic;
    refclk: in std_logic_vector(N_REFCLK - 1 downto 0); -- MGT refclks & IO
    d: in ldata(N_REGION * 4 - 1 downto 0); -- parallel data from payload
    q: out ldata(N_REGION * 4 - 1 downto 0) -- parallel data to payload
);
end mp7_link;

architecture rtl of mp7_link is

signal ipb_in_ctrl, ipb_in_ttc, ipb_in_datapath : ipb_wbus;
signal ipb_out_ctrl, ipb_out_ttc, ipb_out_datapath : ipb_rbus;

signal ipbw: ipb_wbus_array(N_SLAVES-1 downto 0);
signal ipbr: ipb_rbus_array(N_SLAVES-1 downto 0);

signal clk40_i, rsto40_i : std_logic;
signal clk_p_i, rst_p_i, clk40_rst, clk40_sel, clk40_lock, clk40_stop, nuke, soft_rst : std_logic;
signal clks_aux, rsts_aux : std_logic_vector(2 downto 0);
signal ttc_l1a, ttc_l1a_dist, dist_lock, oc_flag, ec_flag : std_logic;
signal ttc_cmd, ttc_cmd_dist: ttc_cmd_t;
signal bunch_ctr: std_logic_vector(11 downto 0);
signal evt_ctr, orb_ctr: eoctr_t;
signal qsel: std_logic_vector(7 downto 0);
signal board_id : std_logic_vector(31 downto 0);
signal ctrs: ttc_stuff_array(N_REGION - 1 downto 0);
signal rst_loc, clken_loc: std_logic_vector(N_REGION - 1 downto 0);
signal cap_bus: daq_cap_bus;
signal daq_bus_top, daq_bus_bot: daq_bus;
signal tmt_sync: tmt_sync_t;
	
signal clkmon: std_logic_vector(2 downto 0);

begin

clk40 <= clk40_i;
rsto40 <= rsto40_i;
-- Watch out: range of ratio_array_t in top_decl.vhd is downto (inverted)
clk80 <= clks_aux(2);
rsto80 <= rsts_aux(2);
clk160 <= clks_aux(1);
rsto160 <= rsts_aux(1);
clk320 <= clks_aux(0);
rsto320 <= rsts_aux(0);
clk_p <= clk_p_i;
rst_p <= rst_p_i;

ttc_bc0 <= '1' when ttc_cmd = TTC_BCMD_BC0 else '0';
ttc_resync <= '1' when ttc_cmd = TTC_BCMD_RESYNC else '0';

ctrl: entity work.mp7_ctrl
port map(
   clk => ipb_clk,
   rst => ipb_rst,
   ipb_in => ipb_in_ctrl,
   ipb_out => ipb_out_ctrl,
   nuke => nuke,
   soft_rst => soft_rst,
   board_id => board_id,
   clk40_rst => clk40_rst,
   clk40_sel => clk40_sel,
   clk40_lock => clk40_lock,
   clk40_stop => clk40_stop
);
   
-- TTC signal handling
ttc: entity work.mp7_ttc
port map(
    clk => ipb_clk,
    rst => ipb_rst,
    mmcm_rst => soft_rst,
    sel => '1', --backplane clock
    lock => clk40_lock,
    stop => clk40_stop,
    ipb_in => ipb_in_ttc,
    ipb_out => ipb_out_ttc,
    clk40_in_p => clk40_in_p,
    clk40_in_n => clk40_in_n,
    clk40ish_in => '0',
    clk40 => clk40_i,
    rst40 => rsto40_i,
    clk_p => clk_p_i,
    rst_p => rst_p_i,
    clks_aux => clks_aux,
    rsts_aux => rsts_aux,
    ttc_in_p => ttc_in_p,
    ttc_in_n => ttc_in_n,
    ttc_cmd => ttc_cmd,
    ttc_cmd_dist => ttc_cmd_dist,
    ttc_l1a_dist => ttc_l1a_dist,
    l1a_throttle => '0',
    ttc_data => ttc_data,
    dist_lock => dist_lock,
    bunch_ctr => bunch_ctr,
    evt_ctr => evt_ctr,
    orb_ctr => orb_ctr,
    oc_flag => oc_flag,
    ec_flag => ec_flag,
    tmt_sync => tmt_sync,
    monclk => clkmon
);

-- MGTs, buffers and TTC fanout
datapath: entity work.mp7_datapath
port map(
   clk => ipb_clk,
   rst => ipb_rst,
   ipb_in => ipb_in_datapath,
   ipb_out => ipb_out_datapath,
   board_id => board_id,
   clk40 => clk40_i,
   clk_p => clk_p_i,
   rst_p => rst_p_i,
   ttc_cmd => ttc_cmd_dist,
   ttc_l1a => ttc_l1a_dist,
   lock => dist_lock,
   ctrs_out => ctrs,
   rst_out => rst_loc,
   clken_out => clken_loc,
   tmt_sync => tmt_sync,
   cap_bus => cap_bus,
   daq_bus_in => daq_bus_top,
   daq_bus_out => daq_bus_bot,
   payload_bc0 => payload_bc0,
   refclk => refclk,
   clkmon => clkmon,
   q => q,
   d => d
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