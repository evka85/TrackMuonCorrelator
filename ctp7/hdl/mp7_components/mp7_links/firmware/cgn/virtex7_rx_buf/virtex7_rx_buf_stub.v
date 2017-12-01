// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
// Date        : Wed Jul  5 12:50:05 2017
// Host        : cmstca running 64-bit CentOS Linux release 7.3.1611 (Core)
// Command     : write_verilog -force -mode synth_stub
//               /home/evka/code/correlator/ctp7/hdl/mp7_components/mp7_links/firmware/cgn/virtex7_rx_buf/virtex7_rx_buf_stub.v
// Design      : virtex7_rx_buf
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1927-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_3_5,Vivado 2016.4" *)
module virtex7_rx_buf(clka, wea, addra, dina, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[8:0],dina[35:0],clkb,enb,addrb[8:0],doutb[35:0]" */;
  input clka;
  input [0:0]wea;
  input [8:0]addra;
  input [35:0]dina;
  input clkb;
  input enb;
  input [8:0]addrb;
  output [35:0]doutb;
endmodule
