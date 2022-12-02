/*

Copyright (c) 2015-2016 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1 ns / 1 ps

/*
 * Wishbone 8 port multiplexer
 */
module wb_mux_8 #
(
    parameter DATA_WIDTH = 32,                    // width of data bus in bits (8, 16, 32, or 64)
    parameter ADDR_WIDTH = 32,                    // width of address bus in bits
    parameter SELECT_WIDTH = (DATA_WIDTH/8)       // width of word select bus (1, 2, 4, or 8)
)
(
    input  wire                    clk,
    input  wire                    rst,

    /*
     * Wishbone master input
     */
    input  wire [ADDR_WIDTH-1:0]   wbm_adr_i,     // ADR_I() address input
    input  wire [DATA_WIDTH-1:0]   wbm_dat_i,     // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbm_dat_o,     // DAT_O() data out
    input  wire                    wbm_we_i,      // WE_I write enable input
    input  wire [SELECT_WIDTH-1:0] wbm_sel_i,     // SEL_I() select input
    input  wire                    wbm_stb_i,     // STB_I strobe input
    output wire                    wbm_ack_o,     // ACK_O acknowledge output
    output wire                    wbm_err_o,     // ERR_O error output
    output wire                    wbm_rty_o,     // RTY_O retry output
    input  wire                    wbm_cyc_i,     // CYC_I cycle input

    /*
     * Wishbone slave 0 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs0_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs0_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs0_dat_o,    // DAT_O() data out
    output wire                    wbs0_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs0_sel_o,    // SEL_O() select output
    output wire                    wbs0_stb_o,    // STB_O strobe output
    input  wire                    wbs0_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs0_err_i,    // ERR_I error input
    input  wire                    wbs0_rty_i,    // RTY_I retry input
    output wire                    wbs0_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 0 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs0_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs0_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 1 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs1_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs1_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs1_dat_o,    // DAT_O() data out
    output wire                    wbs1_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs1_sel_o,    // SEL_O() select output
    output wire                    wbs1_stb_o,    // STB_O strobe output
    input  wire                    wbs1_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs1_err_i,    // ERR_I error input
    input  wire                    wbs1_rty_i,    // RTY_I retry input
    output wire                    wbs1_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 1 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs1_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs1_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 2 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs2_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs2_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs2_dat_o,    // DAT_O() data out
    output wire                    wbs2_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs2_sel_o,    // SEL_O() select output
    output wire                    wbs2_stb_o,    // STB_O strobe output
    input  wire                    wbs2_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs2_err_i,    // ERR_I error input
    input  wire                    wbs2_rty_i,    // RTY_I retry input
    output wire                    wbs2_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 2 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs2_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs2_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 3 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs3_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs3_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs3_dat_o,    // DAT_O() data out
    output wire                    wbs3_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs3_sel_o,    // SEL_O() select output
    output wire                    wbs3_stb_o,    // STB_O strobe output
    input  wire                    wbs3_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs3_err_i,    // ERR_I error input
    input  wire                    wbs3_rty_i,    // RTY_I retry input
    output wire                    wbs3_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 3 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs3_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs3_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 4 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs4_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs4_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs4_dat_o,    // DAT_O() data out
    output wire                    wbs4_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs4_sel_o,    // SEL_O() select output
    output wire                    wbs4_stb_o,    // STB_O strobe output
    input  wire                    wbs4_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs4_err_i,    // ERR_I error input
    input  wire                    wbs4_rty_i,    // RTY_I retry input
    output wire                    wbs4_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 4 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs4_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs4_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 5 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs5_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs5_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs5_dat_o,    // DAT_O() data out
    output wire                    wbs5_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs5_sel_o,    // SEL_O() select output
    output wire                    wbs5_stb_o,    // STB_O strobe output
    input  wire                    wbs5_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs5_err_i,    // ERR_I error input
    input  wire                    wbs5_rty_i,    // RTY_I retry input
    output wire                    wbs5_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 5 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs5_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs5_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 6 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs6_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs6_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs6_dat_o,    // DAT_O() data out
    output wire                    wbs6_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs6_sel_o,    // SEL_O() select output
    output wire                    wbs6_stb_o,    // STB_O strobe output
    input  wire                    wbs6_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs6_err_i,    // ERR_I error input
    input  wire                    wbs6_rty_i,    // RTY_I retry input
    output wire                    wbs6_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 6 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs6_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs6_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 7 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs7_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs7_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs7_dat_o,    // DAT_O() data out
    output wire                    wbs7_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs7_sel_o,    // SEL_O() select output
    output wire                    wbs7_stb_o,    // STB_O strobe output
    input  wire                    wbs7_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs7_err_i,    // ERR_I error input
    input  wire                    wbs7_rty_i,    // RTY_I retry input
    output wire                    wbs7_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 7 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs7_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs7_addr_msk  // Slave address prefix mask
);

wire wbs0_match = ~|((wbm_adr_i ^ wbs0_addr) & wbs0_addr_msk);
wire wbs1_match = ~|((wbm_adr_i ^ wbs1_addr) & wbs1_addr_msk);
wire wbs2_match = ~|((wbm_adr_i ^ wbs2_addr) & wbs2_addr_msk);
wire wbs3_match = ~|((wbm_adr_i ^ wbs3_addr) & wbs3_addr_msk);
wire wbs4_match = ~|((wbm_adr_i ^ wbs4_addr) & wbs4_addr_msk);
wire wbs5_match = ~|((wbm_adr_i ^ wbs5_addr) & wbs5_addr_msk);
wire wbs6_match = ~|((wbm_adr_i ^ wbs6_addr) & wbs6_addr_msk);
wire wbs7_match = ~|((wbm_adr_i ^ wbs7_addr) & wbs7_addr_msk);

wire wbs0_sel = wbs0_match;
wire wbs1_sel = wbs1_match & ~(wbs0_match);
wire wbs2_sel = wbs2_match & ~(wbs0_match | wbs1_match);
wire wbs3_sel = wbs3_match & ~(wbs0_match | wbs1_match | wbs2_match);
wire wbs4_sel = wbs4_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match);
wire wbs5_sel = wbs5_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match);
wire wbs6_sel = wbs6_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match);
wire wbs7_sel = wbs7_match & ~(wbs0_match | wbs1_match | wbs2_match | wbs3_match | wbs4_match | wbs5_match | wbs6_match);

wire master_cycle = wbm_cyc_i & wbm_stb_i;

wire select_error = ~(wbs0_sel | wbs1_sel | wbs2_sel | wbs3_sel | wbs4_sel | wbs5_sel | wbs6_sel | wbs7_sel) & master_cycle;

// master
assign wbm_dat_o = wbs0_sel ? wbs0_dat_i :
                   wbs1_sel ? wbs1_dat_i :
                   wbs2_sel ? wbs2_dat_i :
                   wbs3_sel ? wbs3_dat_i :
                   wbs4_sel ? wbs4_dat_i :
                   wbs5_sel ? wbs5_dat_i :
                   wbs6_sel ? wbs6_dat_i :
                   wbs7_sel ? wbs7_dat_i :
                   {DATA_WIDTH{1'b0}};

assign wbm_ack_o = wbs0_ack_i |
                   wbs1_ack_i |
                   wbs2_ack_i |
                   wbs3_ack_i |
                   wbs4_ack_i |
                   wbs5_ack_i |
                   wbs6_ack_i |
                   wbs7_ack_i;

assign wbm_err_o = wbs0_err_i |
                   wbs1_err_i |
                   wbs2_err_i |
                   wbs3_err_i |
                   wbs4_err_i |
                   wbs5_err_i |
                   wbs6_err_i |
                   wbs7_err_i |
                   select_error;

assign wbm_rty_o = wbs0_rty_i |
                   wbs1_rty_i |
                   wbs2_rty_i |
                   wbs3_rty_i |
                   wbs4_rty_i |
                   wbs5_rty_i |
                   wbs6_rty_i |
                   wbs7_rty_i;

// slave 0
assign wbs0_adr_o = wbm_adr_i;
assign wbs0_dat_o = wbm_dat_i;
assign wbs0_we_o = wbm_we_i & wbs0_sel;
assign wbs0_sel_o = wbm_sel_i;
assign wbs0_stb_o = wbm_stb_i & wbs0_sel;
assign wbs0_cyc_o = wbm_cyc_i & wbs0_sel;

// slave 1
assign wbs1_adr_o = wbm_adr_i;
assign wbs1_dat_o = wbm_dat_i;
assign wbs1_we_o = wbm_we_i & wbs1_sel;
assign wbs1_sel_o = wbm_sel_i;
assign wbs1_stb_o = wbm_stb_i & wbs1_sel;
assign wbs1_cyc_o = wbm_cyc_i & wbs1_sel;

// slave 2
assign wbs2_adr_o = wbm_adr_i;
assign wbs2_dat_o = wbm_dat_i;
assign wbs2_we_o = wbm_we_i & wbs2_sel;
assign wbs2_sel_o = wbm_sel_i;
assign wbs2_stb_o = wbm_stb_i & wbs2_sel;
assign wbs2_cyc_o = wbm_cyc_i & wbs2_sel;

// slave 3
assign wbs3_adr_o = wbm_adr_i;
assign wbs3_dat_o = wbm_dat_i;
assign wbs3_we_o = wbm_we_i & wbs3_sel;
assign wbs3_sel_o = wbm_sel_i;
assign wbs3_stb_o = wbm_stb_i & wbs3_sel;
assign wbs3_cyc_o = wbm_cyc_i & wbs3_sel;

// slave 4
assign wbs4_adr_o = wbm_adr_i;
assign wbs4_dat_o = wbm_dat_i;
assign wbs4_we_o = wbm_we_i & wbs4_sel;
assign wbs4_sel_o = wbm_sel_i;
assign wbs4_stb_o = wbm_stb_i & wbs4_sel;
assign wbs4_cyc_o = wbm_cyc_i & wbs4_sel;

// slave 5
assign wbs5_adr_o = wbm_adr_i;
assign wbs5_dat_o = wbm_dat_i;
assign wbs5_we_o = wbm_we_i & wbs5_sel;
assign wbs5_sel_o = wbm_sel_i;
assign wbs5_stb_o = wbm_stb_i & wbs5_sel;
assign wbs5_cyc_o = wbm_cyc_i & wbs5_sel;

// slave 6
assign wbs6_adr_o = wbm_adr_i;
assign wbs6_dat_o = wbm_dat_i;
assign wbs6_we_o = wbm_we_i & wbs6_sel;
assign wbs6_sel_o = wbm_sel_i;
assign wbs6_stb_o = wbm_stb_i & wbs6_sel;
assign wbs6_cyc_o = wbm_cyc_i & wbs6_sel;

// slave 7
assign wbs7_adr_o = wbm_adr_i;
assign wbs7_dat_o = wbm_dat_i;
assign wbs7_we_o = wbm_we_i & wbs7_sel;
assign wbs7_sel_o = wbm_sel_i;
assign wbs7_stb_o = wbm_stb_i & wbs7_sel;
assign wbs7_cyc_o = wbm_cyc_i & wbs7_sel;


endmodule
