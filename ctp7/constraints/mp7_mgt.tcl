# Format is x_loc y_start x_common_loc y_common_loc

set m_loc {
	{1 0 0}
	{1 4 1}
	{1 8 2}
}	

for {set i 0} {$i < 4} {incr i} {
	set d [lindex $m_loc $i]
	set l [get_cells "i_system/mp7_links/datapath/rgen\[$i\].region/*/*/*/*/gthe2_common_*"]
	if {[llength $l] == 1} {
		set_property LOC GTHE2_COMMON_X[lindex $d 0]Y[lindex $d 2] $l
	}
	for {set j 0} {$j < 4} {incr j} {
		set l [get_cells "i_system/mp7_links/datapath/rgen\[$i\].region/*/*/*/*/g_gt_instances\[$j\]*/gthe2_i"]
		if {[llength $l] != 1} {
			set l [get_cells "i_system/mp7_links/datapath/rgen\[$i\].region/*/*/*/*/gt$j*/gthe2_i"]
		}
		if {[llength $l] == 1} {
#			if {$i > 1} {
#				set c [expr {[lindex $d 1] + 3 - $j}]
#			} else {
				set c [expr {[lindex $d 1] + $j}]
#			}			
			set_property LOC GTHE2_CHANNEL_X[lindex $d 0]Y$c $l
		}		
	}
}

#Fix QPLL settings because CTP7 REFCLK is 250 MHz instead of 125 MHz
set_property QPLL_FBDIV 10'b0010000000 [get_cells {i_system/mp7_links/datapath/rgen[*].region/mgt_gen_gth_10g.quad/quad/gth_stdlat.quad_wrapper_inst/gth_quad_i/gthe2_common_i}]