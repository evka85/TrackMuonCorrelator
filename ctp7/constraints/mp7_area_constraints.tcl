# Area constraints for MP7

create_pblock ttc
add_cells_to_pblock [get_pblocks ttc] [get_cells -quiet [list mp7_links/ttc]]
remove_cells_from_pblock ttc [get_cells -quiet mp7_links/ttc/clocks/ibuf_clk40]
resize_pblock [get_pblocks ttc] -add {CLOCKREGION_X0Y4:CLOCKREGION_X0Y4}

create_pblock ctrl
resize_pblock [get_pblocks ctrl] -add {CLOCKREGION_X0Y6:CLOCKREGION_X0Y6}
add_cells_to_pblock [get_pblocks ctrl] [get_cells -quiet [list mp7_links/ctrl]]

# Quad and per-region area constraints

set q_coords {
    {SLICE_X0Y400:SLICE_X39Y449 RAMB18_X0Y160:RAMB18_X1Y179}
    {SLICE_X0Y450:SLICE_X39Y499 RAMB18_X0Y180:RAMB18_X1Y199}
    {SLICE_X182Y450:SLICE_X221Y499 RAMB18_X14Y180:RAMB18_X14Y199 RAMB18_X13Y170:RAMB18_X13Y179}
	{SLICE_X182Y400:SLICE_X221Y449 RAMB18_X14Y160:RAMB18_X14Y179 RAMB18_X13Y190:RAMB18_X13Y199}
}

set p_coords {
	SLICE_X40Y400:SLICE_X105Y449
	SLICE_X40Y450:SLICE_X105Y499
	SLICE_X106Y450:SLICE_X181Y499
	SLICE_X106Y400:SLICE_X181Y449
}

for {set i 0} {$i < 4} {incr i} {
	set bq [create_pblock quad_$i]
	resize_pblock $bq -add [lindex $q_coords $i]
	add_cells_to_pblock $bq "mp7_links/datapath/rgen\[$i\].region"
#	set br [create_pblock payload_$i]
#	resize_pblock $br -add [lindex $p_coords $i]
}
