##=================================================================================================##
####################################   Srcipt Information   #########################################
##=================================================================================================##
##                                                                                         
## Company:               CERN (PH-ESE-BE)                                                         
## Engineer:              Manoel Barros Marin (manoel.barros.marin@cern.ch) (m.barros.marin@ieee.org)
##                                                                                                 
## Project Name:          GBT-FPGA                                                                
## Script Name:           Xilinx Virtex 6 - GBT Bank                                        
##                                                                                                 
## Language:              TCL (Xilinx version)                                                              
##                                                                                                   
## Target Device:         Xilinx Virtex 6                                                      
##                                                                                                   
## Version:               3.2                                                                      
##
## Description:            
##
## Versions history:      DATE         VERSION   AUTHOR            DESCRIPTION
##
##                        11/04/2014   3.0       M. Barros Marin   First .tcl script definition
##
##                        12/09/2014   3.2       M. Barros Marin   Minor modifications
##
## Additional Comments:   TCL script for adding the source files of the Xilinx Virtex 6 GBT Bank to ISE
##
##=================================================================================================##
#####################################################################################################
##=================================================================================================##


#####################################################################################################
############################# Absolute Data Path Set By The User ####################################
#####################################################################################################

## Comment: The user has to provide the absolute data path to the root folder of the GBT-FPGA Core
##          source files.

set COMMON_SOURCE_PATH /home/evka/code/gem_amc/common/hdl
set GLIB_SOURCE_PATH /home/evka/code/gem_amc/glib/hdl
set GLIB_IP_PATH /home/evka/code/gem_amc/glib/ip

#####################################################################################################
#####################################################################################################


#####################################################################################################
#################### Commands for Adding the Source Files of the GBT-FPGA Core ######################
#####################################################################################################
      
## Comment: Adding Common files: 

puts "->" 
puts "-> Adding common files of the GBT-FPGA Core to the ISE project..."
puts "->" 

xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_decoder.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_decoder_gbtframe_chnsrch.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_decoder_gbtframe_deintlver.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_decoder_gbtframe_elpeval.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_decoder_gbtframe_errlcpoly.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_decoder_gbtframe_lmbddet.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_decoder_gbtframe_rs2errcor.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_decoder_gbtframe_rsdec.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_decoder_gbtframe_syndrom.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_descrambler.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_descrambler_16bit.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_descrambler_21bit.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_framealigner.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_framealigner_bscounter.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_framealigner_pattsearch.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_framealigner_rightshift.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_framealigner_wraddr.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_gearbox.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_gearbox_latopt.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_gearbox_std.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_gearbox_std_rdctrl.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_rx/gbt_rx_status.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_encoder.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_encoder_gbtframe_intlver.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_encoder_gbtframe_polydiv.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_encoder_gbtframe_rsencode.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_gearbox.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_gearbox_latopt.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_gearbox_std.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_gearbox_std_rdwrctrl.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_scrambler.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_scrambler_16bit.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_tx/gbt_tx_scrambler_21bit.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/mgt/mgt_latopt_bitslipctrl.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/mgt/multi_gigabit_transceivers.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_bank.vhd
xfile add $COMMON_SOURCE_PATH/gbt_bank/core_sources/gbt_bank_package.vhd

## Comment: Adding Xilinx Virtex 6 specific files:

puts "-> Adding Xilinx Virtex 6 specific files of the GBT-FPGA Core to the ISE project..."
puts "->" 

xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/gbt_rx/xlx_v6_gbt_rx_gearbox_std_dpram.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/gbt_tx/xlx_v6_gbt_tx_gearbox_std_dpram.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/mgt/xlx_v6_gtx_latopt.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/mgt/xlx_v6_gtx_latopt_rx_sync.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/mgt/xlx_v6_gtx_latopt_tx_sync.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/mgt/xlx_v6_gtx_std.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/mgt/xlx_v6_gtx_std_double_reset.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/mgt/xlx_v6_mgt_latopt.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/mgt/xlx_v6_mgt_std.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/xlx_v6_gbt_bank_package.vhd
xfile add $GLIB_SOURCE_PATH/gbt_bank_v6/xlx_v6_gbt_banks_user_setup.vhd
xfile add $GLIB_IP_PATH/gbt_bank_v6/rx_dpram/xlx_v6_rx_dpram.xco
xfile add $GLIB_IP_PATH/gbt_bank_v6/tx_dpram/xlx_v6_tx_dpram.xco

#####################################################################################################
#####################################################################################################
