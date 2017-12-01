# Timing constraints for MP7

# Special path constraints

set_false_path -through [get_nets {i_system/mp7_links/datapath/refclk_mon[*]}]
#  Search design for false path endpoints
set_false_path -to [get_cells -hier -filter {MP7_FALSE_PATH_DEST_CELL == TRUE}]

###############################################################################
# Tx path for MGTs
###############################################################################

for {set i 0} {$i < 4} {incr i} {
	for {set j 0} {$j < 4} {incr j} {
		set tx_ff_out [get_pins -quiet "i_system/mp7_links/datapath/rgen[$i].region/*/tx_gen[$j].tx_clk_bridge/buf*_reg[*]/C"]
		set tx_ff_in [get_pins -quiet "i_system/mp7_links/datapath/rgen[$i].region/*/tx_gen[$j].tx_clk_bridge/data_out_reg[*]/D"]
		if {[llength $tx_ff_out] != 0} {
			set_max_delay -from $tx_ff_out -to $tx_ff_in -datapath_only 4.0
			set_min_delay -to $tx_ff_in 0.2
		}
	}
}

