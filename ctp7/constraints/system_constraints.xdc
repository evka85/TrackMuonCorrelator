
#---------------
set_property PACKAGE_PIN H29 [get_ports clk_200_diff_in_clk_n]

set_property IOSTANDARD LVDS [get_ports clk_200_diff_in_clk_p]
set_property IOSTANDARD LVDS [get_ports clk_200_diff_in_clk_n]

create_clock -period 5.000 [get_ports clk_200_diff_in_clk_p]

#---------------
#green
set_property PACKAGE_PIN A20 [get_ports {LEDs[0]}]
#orange
set_property PACKAGE_PIN B20 [get_ports {LEDs[1]}]

set_property IOSTANDARD LVCMOS18 [get_ports {LEDs[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {LEDs[1]}]


# ==========================================================================


set_property PACKAGE_PIN AV30 [get_ports clk_40_ttc_n_i]

set_property IOSTANDARD LVDS [get_ports clk_40_ttc_p_i]
set_property IOSTANDARD LVDS [get_ports clk_40_ttc_n_i]

## create_clock -period 24.950 -name clk_40_ttc_p_i [get_ports clk_40_ttc_p_i]

## ~40.5 MHz (over-constrained)
create_clock -period 24.691 -name clk_40_ttc_p_i [get_ports clk_40_ttc_p_i]


set_property PACKAGE_PIN J26 [get_ports ttc_data_n_i]

set_property IOSTANDARD LVDS [get_ports ttc_data_p_i]
set_property IOSTANDARD LVDS [get_ports ttc_data_n_i]



# ==========================================================================
# AXI Chip2Chip

set_property INTERNAL_VREF 0.9 [get_iobanks 16]


# AXI Chip2Chip - RX section
set_property PACKAGE_PIN BD31 [get_ports axi_c2c_v7_to_zynq_clk]
set_property PACKAGE_PIN AY32 [get_ports {axi_c2c_v7_to_zynq_data[0]}]
set_property PACKAGE_PIN BA33 [get_ports {axi_c2c_v7_to_zynq_data[1]}]
set_property PACKAGE_PIN AR31 [get_ports {axi_c2c_v7_to_zynq_data[2]}]
set_property PACKAGE_PIN AR32 [get_ports {axi_c2c_v7_to_zynq_data[3]}]
set_property PACKAGE_PIN AV32 [get_ports {axi_c2c_v7_to_zynq_data[4]}]
set_property PACKAGE_PIN AW32 [get_ports {axi_c2c_v7_to_zynq_data[5]}]
set_property PACKAGE_PIN AJ30 [get_ports {axi_c2c_v7_to_zynq_data[6]}]
set_property PACKAGE_PIN AJ31 [get_ports {axi_c2c_v7_to_zynq_data[7]}]
set_property PACKAGE_PIN AM32 [get_ports {axi_c2c_v7_to_zynq_data[8]}]
set_property PACKAGE_PIN AM33 [get_ports {axi_c2c_v7_to_zynq_data[9]}]
set_property PACKAGE_PIN BB33 [get_ports {axi_c2c_v7_to_zynq_data[10]}]
set_property PACKAGE_PIN AV33 [get_ports {axi_c2c_v7_to_zynq_data[11]}]
set_property PACKAGE_PIN AP32 [get_ports {axi_c2c_v7_to_zynq_data[12]}]
set_property PACKAGE_PIN AN32 [get_ports {axi_c2c_v7_to_zynq_data[13]}]
set_property PACKAGE_PIN BC34 [get_ports {axi_c2c_v7_to_zynq_data[14]}]

set_property IOSTANDARD HSTL_I_DCI_18 [get_ports axi_c2c_v7_to_zynq_clk]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[0]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[1]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[2]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[3]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[4]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[5]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[6]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[7]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[8]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[9]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[10]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[11]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[12]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[13]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_v7_to_zynq_data[14]}]

# AXI Chip2Chip - TX section
set_property PACKAGE_PIN AU33 [get_ports axi_c2c_zynq_to_v7_clk]
set_property PACKAGE_PIN AV34 [get_ports {axi_c2c_zynq_to_v7_data[0]}]
set_property PACKAGE_PIN AV35 [get_ports {axi_c2c_zynq_to_v7_data[1]}]
set_property PACKAGE_PIN AW34 [get_ports {axi_c2c_zynq_to_v7_data[2]}]
set_property PACKAGE_PIN AW35 [get_ports {axi_c2c_zynq_to_v7_data[3]}]
set_property PACKAGE_PIN AY33 [get_ports {axi_c2c_zynq_to_v7_data[4]}]
set_property PACKAGE_PIN AY34 [get_ports {axi_c2c_zynq_to_v7_data[5]}]
set_property PACKAGE_PIN BA34 [get_ports {axi_c2c_zynq_to_v7_data[6]}]
set_property PACKAGE_PIN BA35 [get_ports {axi_c2c_zynq_to_v7_data[7]}]
set_property PACKAGE_PIN BD34 [get_ports {axi_c2c_zynq_to_v7_data[8]}]
set_property PACKAGE_PIN BD35 [get_ports {axi_c2c_zynq_to_v7_data[9]}]
set_property PACKAGE_PIN BB35 [get_ports {axi_c2c_zynq_to_v7_data[10]}]
set_property PACKAGE_PIN BC35 [get_ports {axi_c2c_zynq_to_v7_data[11]}]
set_property PACKAGE_PIN BC32 [get_ports {axi_c2c_zynq_to_v7_data[12]}]
set_property PACKAGE_PIN BC33 [get_ports {axi_c2c_zynq_to_v7_data[13]}]
set_property PACKAGE_PIN BD32 [get_ports {axi_c2c_zynq_to_v7_data[14]}]

set_property IOSTANDARD HSTL_I_DCI_18 [get_ports axi_c2c_zynq_to_v7_clk]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[0]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[1]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[2]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[3]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[4]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[5]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[6]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[7]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[8]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[9]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[10]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[11]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[12]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[13]}]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports {axi_c2c_zynq_to_v7_data[14]}]


# AXI Chip2Chip - Status/Control section
set_property PACKAGE_PIN BB31 [get_ports axi_c2c_zynq_to_v7_reset]
set_property PACKAGE_PIN BB32 [get_ports axi_c2c_v7_to_zynq_link_status]

set_property IOSTANDARD HSTL_I_DCI_18 [get_ports axi_c2c_zynq_to_v7_reset]
set_property IOSTANDARD HSTL_I_DCI_18 [get_ports axi_c2c_v7_to_zynq_link_status]
# ==========================================================================

## This constraint is embedded in AXI C2C IP module
##create_clock -period 5.000 -name axi_c2c_zynq_to_v7_clk [get_ports axi_c2c_zynq_to_v7_clk]


create_generated_clock -name axi_c2c_v7_to_zynq_clk -source [get_pins i_v7_bd/axi_chip2chip_0/inst/slave_fpga_gen.axi_chip2chip_slave_phy_inst/slave_sio_phy.axi_chip2chip_sio_output_inst/gen_oddr.oddr_clk_out_inst/C] -divide_by 1 [get_ports axi_c2c_v7_to_zynq_clk]



####################### GT reference clock constraints #########################

create_clock -period 6.250 [get_ports {refclk_F_0_p_i[0]}]
create_clock -period 6.250 [get_ports {refclk_F_0_p_i[1]}]
create_clock -period 6.250 [get_ports {refclk_F_0_p_i[2]}]
create_clock -period 6.250 [get_ports {refclk_F_0_p_i[3]}]

create_clock -period 6.250 [get_ports {refclk_F_1_p_i[0]}]
create_clock -period 6.250 [get_ports {refclk_F_1_p_i[1]}]
create_clock -period 6.250 [get_ports {refclk_F_1_p_i[2]}]
create_clock -period 6.250 [get_ports {refclk_F_1_p_i[3]}]

#create_clock -period 6.250 [get_ports {refclk_B_0_p_i[0]}]
create_clock -period 6.250 [get_ports {refclk_B_0_p_i[1]}]
create_clock -period 6.250 [get_ports {refclk_B_0_p_i[2]}]
create_clock -period 6.250 [get_ports {refclk_B_0_p_i[3]}]

#create_clock -period 6.250 [get_ports {refclk_B_1_p_i[0]}]
create_clock -period 6.250 [get_ports {refclk_B_1_p_i[1]}]
create_clock -period 6.250 [get_ports {refclk_B_1_p_i[2]}]
create_clock -period 6.250 [get_ports {refclk_B_1_p_i[3]}]

################################ RefClk Location constraints #####################

set_property PACKAGE_PIN E10 [get_ports {refclk_F_0_p_i[0]}]
set_property PACKAGE_PIN N10 [get_ports {refclk_F_0_p_i[1]}]
set_property PACKAGE_PIN AF8 [get_ports {refclk_F_0_p_i[2]}]
set_property PACKAGE_PIN AR10 [get_ports {refclk_F_0_p_i[3]}]

set_property PACKAGE_PIN G10 [get_ports {refclk_F_1_p_i[0]}]
set_property PACKAGE_PIN R10 [get_ports {refclk_F_1_p_i[1]}]
set_property PACKAGE_PIN AH8 [get_ports {refclk_F_1_p_i[2]}]
set_property PACKAGE_PIN AT8 [get_ports {refclk_F_1_p_i[3]}]

#set_property PACKAGE_PIN AR35 [get_ports  {refclk_B_0_p_i[0]}]
set_property PACKAGE_PIN AF37 [get_ports {refclk_B_0_p_i[1]}]
set_property PACKAGE_PIN N35 [get_ports {refclk_B_0_p_i[2]}]
set_property PACKAGE_PIN E35 [get_ports {refclk_B_0_p_i[3]}]

#set_property PACKAGE_PIN AT37 [get_ports  {refclk_B_1_p_i[0]}]
set_property PACKAGE_PIN AH37 [get_ports {refclk_B_1_p_i[1]}]
set_property PACKAGE_PIN R35 [get_ports {refclk_B_1_p_i[2]}]
set_property PACKAGE_PIN G35 [get_ports {refclk_B_1_p_i[3]}]

################################ GTH2_CHANNEL Location constraints  #####################

set_property LOC GTHE2_CHANNEL_X1Y0 [get_cells {i_gth_wrapper/gen_gth_single[0].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y1 [get_cells {i_gth_wrapper/gen_gth_single[1].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y2 [get_cells {i_gth_wrapper/gen_gth_single[2].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y3 [get_cells {i_gth_wrapper/gen_gth_single[3].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y4 [get_cells {i_gth_wrapper/gen_gth_single[4].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y5 [get_cells {i_gth_wrapper/gen_gth_single[5].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y6 [get_cells {i_gth_wrapper/gen_gth_single[6].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y7 [get_cells {i_gth_wrapper/gen_gth_single[7].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y8 [get_cells {i_gth_wrapper/gen_gth_single[8].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y9 [get_cells {i_gth_wrapper/gen_gth_single[9].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y10 [get_cells {i_gth_wrapper/gen_gth_single[10].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y11 [get_cells {i_gth_wrapper/gen_gth_single[11].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y12 [get_cells {i_gth_wrapper/gen_gth_single[12].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y13 [get_cells {i_gth_wrapper/gen_gth_single[13].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y14 [get_cells {i_gth_wrapper/gen_gth_single[14].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y15 [get_cells {i_gth_wrapper/gen_gth_single[15].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y16 [get_cells {i_gth_wrapper/gen_gth_single[16].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y17 [get_cells {i_gth_wrapper/gen_gth_single[17].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y18 [get_cells {i_gth_wrapper/gen_gth_single[18].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y19 [get_cells {i_gth_wrapper/gen_gth_single[19].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y20 [get_cells {i_gth_wrapper/gen_gth_single[20].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y21 [get_cells {i_gth_wrapper/gen_gth_single[21].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y22 [get_cells {i_gth_wrapper/gen_gth_single[22].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y23 [get_cells {i_gth_wrapper/gen_gth_single[23].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y24 [get_cells {i_gth_wrapper/gen_gth_single[24].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y25 [get_cells {i_gth_wrapper/gen_gth_single[25].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y26 [get_cells {i_gth_wrapper/gen_gth_single[26].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y27 [get_cells {i_gth_wrapper/gen_gth_single[27].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y28 [get_cells {i_gth_wrapper/gen_gth_single[28].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y29 [get_cells {i_gth_wrapper/gen_gth_single[29].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y30 [get_cells {i_gth_wrapper/gen_gth_single[30].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y31 [get_cells {i_gth_wrapper/gen_gth_single[31].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y32 [get_cells {i_gth_wrapper/gen_gth_single[32].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y33 [get_cells {i_gth_wrapper/gen_gth_single[33].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y34 [get_cells {i_gth_wrapper/gen_gth_single[34].gen_gth_*/i_gthe2}]
set_property LOC GTHE2_CHANNEL_X1Y35 [get_cells {i_gth_wrapper/gen_gth_single[35].gen_gth_*/i_gthe2}]


set_property LOC XADC_X0Y0 [get_cells i_v7_bd/xadc_wiz_0/U0/AXI_XADC_CORE_I/XADC_INST]


set_false_path -to [get_cells -hierarchical -filter {NAME =~ *sync*/data_sync_reg1}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *sync*/data_sync_reg1}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *sync*/data_sync_reg1}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *sync*/data_sync_reg1}]


#set_false_path -from [get_clocks -include_generated_clocks -of_objects [get_ports SYSCLK_IN]] -to [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_gth_single_i*gthe2_i*TXOUTCLK}]]
#set_false_path -from [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_gth_single_i*gthe2_i*TXOUTCLK}]] -to [get_clocks -include_generated_clocks -of_objects [get_ports SYSCLK_IN]]

#set_false_path -from [get_clocks -include_generated_clocks -of_objects [get_ports SYSCLK_IN]] -to [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_gth_single_i*gthe2_i*RXOUTCLK}]]
#set_false_path -from [get_clocks -include_generated_clocks -of_objects [get_pins -hier -filter {name=~*gt0_gth_single_i*gthe2_i*RXOUTCLK}]] -to [get_clocks -include_generated_clocks -of_objects [get_ports SYSCLK_IN]]


############# Channel [0] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[0].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[0].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [1] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[1].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[1].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [2] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[2].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[2].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [3] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[3].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[3].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [4] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[4].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[4].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [5] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[5].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[5].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [6] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[6].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[6].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [7] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[7].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[7].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [8] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[8].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[8].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [9] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[9].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[9].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [10] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[10].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[10].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [11] - 3.2 Gbps TX, 3.2 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[11].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[11].gen_gth_*/i_gthe2*RXOUTCLK}]







############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[12].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[12].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[13].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[13].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[14].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[14].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[15].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[15].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[16].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[16].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[17].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[17].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[18].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[18].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[19].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[19].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[20].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[20].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[21].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[21].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[22].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[22].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[23].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[23].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[24].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[24].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[25].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[25].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[26].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[26].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[27].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[27].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[28].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[28].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[29].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[29].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[30].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[30].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[31].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[31].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[32].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[32].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[33].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[33].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[34].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[34].gen_gth_*/i_gthe2*RXOUTCLK}]

############# Channel [12] - 4.8 Gbps TX, 4.8 Gbps RX #############
create_clock -period 6.250 [get_pins -hier -filter {name=~*gen_gth_single[35].gen_gth_*/i_gthe2*TXOUTCLK}]
create_clock -period 4.166 [get_pins -hier -filter {name=~*gen_gth_single[35].gen_gth_*/i_gthe2*RXOUTCLK}]

############# ############# ############# ############# ############# ############# #############
############# ############# False Path Constraints ############# ############# #############

set_clock_groups -asynchronous -group [get_clocks s_clk_40] -group [get_clocks clk_out2_v7_bd_clk_wiz_0_0]
set_clock_groups -asynchronous -group [get_clocks s_clk_160] -group [get_clocks clk_out2_v7_bd_clk_wiz_0_0]

set_clock_groups -asynchronous -group [get_clocks {i_gth_wrapper/gen_gth_single[*].*/i_gthe2/?XOUTCLK}] -group [get_clocks clk_out2_v7_bd_clk_wiz_0_0]
set_clock_groups -asynchronous -group [get_clocks {i_gth_wrapper/gen_gth_single[*].*/i_gthe2/?XOUTCLK}] -group [get_clocks s_clk_160]

set_clock_groups -asynchronous -group [get_clocks clk_out2_v7_bd_clk_wiz_0_0] -group [get_clocks clkout0]
