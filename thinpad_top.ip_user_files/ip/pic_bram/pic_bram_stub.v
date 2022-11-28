// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Mon Nov 28 20:05:18 2022
// Host        : LAPTOP-67GVJ3S2 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Download/cod22-grp09/thinpad_top.srcs/sources_1/ip/pic_bram/pic_bram_stub.v
// Design      : pic_bram
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tfgg676-2L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module pic_bram(clka, ena, wea, addra, dina, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[18:0],dina[7:0],clkb,enb,addrb[18:0],doutb[7:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [18:0]addra;
  input [7:0]dina;
  input clkb;
  input enb;
  input [18:0]addrb;
  output [7:0]doutb;
endmodule
