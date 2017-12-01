# The code below should work. It doesn't. See 
# http://forums.xilinx.com/t5/Vivado-TCL-Community/Unable-to-use-create-property-user-defined-properties/td-p/486806

#create_property USER_BOARD fileset
#set_property USER_BOARD mp7xe_690 [get_filesets -filter {NAME == "constrs_1"}]

# So in the meantime, a hack:

exec echo "R1" > top/mp7_board_type.txt
