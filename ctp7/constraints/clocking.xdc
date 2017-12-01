##should be always present after control FPGA is configured
#create_clock -period 25.000 -name clk40_in [get_ports clk40_in]
##LHC clock, overconstrain it a little bit to fix sporadic data corruption
#create_clock -period 24.800 -name lhc_clk [get_ports lhc_clk_p]
##generated in control FPGA
#create_clock -period 8.000 -name clk_125M [get_ports clk_125M]
##GTH sync clock
#create_clock -period 1.563 -name gt_sync_clk [get_ports {gth_refclk_sync_p[*]}]
##GTH async clock
#create_clock -period 8.000 -name gt_async_clk [get_ports {gth_refclk_async_p[*]}]
##DAQ async clock
#create_clock -period 8.000 -name daq_refclk [get_ports daq_refclk_p]
##DAQ TX data clock
#create_clock -period 4.000 -name daq_txoutclk [get_pins amc13_link/gth_tx/daq_link_tx_init_i/daq_link_tx_i/gt0_daq_link_tx_i/gthe2_i/TXOUTCLK]

##############################################################################
# Datapath clks
##############################################################################

# Xilinx prefers 1 clk definition per clock, but you end up with a stupid 
# number of clk definitions. For refclks easier to place all clocks into 
# single definition.  Unfortunately it is currenntly limited to 64 clks.
# Hence split problem up into many more clk definitions.
 
create_clock -period 4 -name gth_10g_rx0_clk  [get_pins -hier -filter {name=~mp7_links/datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/g_gt_instances[0].gth_transceiver_i/gthe2_i/RXOUTCLK}]
create_clock -period 4 -name gth_10g_rx1_clk  [get_pins -hier -filter {name=~mp7_links/datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/g_gt_instances[1].gth_transceiver_i/gthe2_i/RXOUTCLK}]
create_clock -period 4 -name gth_10g_rx2_clk  [get_pins -hier -filter {name=~mp7_links/datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/g_gt_instances[2].gth_transceiver_i/gthe2_i/RXOUTCLK}]
create_clock -period 4 -name gth_10g_rx3_clk  [get_pins -hier -filter {name=~mp7_links/datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/g_gt_instances[3].gth_transceiver_i/gthe2_i/RXOUTCLK}]

create_clock -period 4 -name gth_10g_tx0_clk  [get_pins -hier -filter {name=~mp7_links/datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/g_gt_instances[0].gth_transceiver_i/gthe2_i/TXOUTCLK}]
create_clock -period 4 -name gth_10g_tx1_clk  [get_pins -hier -filter {name=~mp7_links/datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/g_gt_instances[1].gth_transceiver_i/gthe2_i/TXOUTCLK}]
create_clock -period 4 -name gth_10g_tx2_clk  [get_pins -hier -filter {name=~mp7_links/datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/g_gt_instances[2].gth_transceiver_i/gthe2_i/TXOUTCLK}]
create_clock -period 4 -name gth_10g_tx3_clk  [get_pins -hier -filter {name=~mp7_links/datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/g_gt_instances[3].gth_transceiver_i/gthe2_i/TXOUTCLK}]

##############################################################################
# Inter clock relationship
##############################################################################

set_clock_groups -asynchronous \
   -group [get_clocks -include_generated_clocks clk_125M] \
   -group [get_clocks -include_generated_clocks axi_c2c_selio_rx_clk_in] \
   -group [get_clocks -include_generated_clocks clk40_in] \
   -group [get_clocks -include_generated_clocks lhc_clk] \
   -group [get_clocks -include_generated_clocks gt_sync_clk] \
   -group [get_clocks -include_generated_clocks gt_async_clk] \
   -group [get_clocks -include_generated_clocks daq_refclk] \
   -group [get_clocks -include_generated_clocks daq_k_rx_clk] \
   -group [get_clocks -include_generated_clocks daq_txoutclk] \
   -group [get_clocks -include_generated_clocks gth_10g_rx0_clk] \
   -group [get_clocks -include_generated_clocks gth_10g_rx1_clk] \
   -group [get_clocks -include_generated_clocks gth_10g_rx2_clk] \
   -group [get_clocks -include_generated_clocks gth_10g_rx3_clk] \
   -group [get_clocks -include_generated_clocks gth_10g_tx0_clk] \
   -group [get_clocks -include_generated_clocks gth_10g_tx1_clk] \
   -group [get_clocks -include_generated_clocks gth_10g_tx2_clk] \
   -group [get_clocks -include_generated_clocks gth_10g_tx3_clk]
