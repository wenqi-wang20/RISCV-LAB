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
 * Mmu 2 port arbiter
 */
module mmu_arbiter_2 #
(
    parameter DATA_WIDTH = 32,                    // width of data bus in bits (8, 16, 32, or 64)
    parameter ADDR_WIDTH = 32,                    // width of address bus in bits
    parameter SELECT_WIDTH = (DATA_WIDTH/8),      // width of word select bus (1, 2, 4, or 8)
    parameter ARB_TYPE_ROUND_ROBIN = 0,           // select round robin arbitration
    parameter ARB_LSB_HIGH_PRIORITY = 1           // LSB priority selection
)
(
    input  wire                    clk,
    input  wire                    rst,

    /*
     * MMU master 0 input
     */

    // Data read and write
    input  wire [31:0] mmu0_v_addr_i,
    input  wire [31:0] mmu0_data_i,
    output wire [31:0] mmu0_data_o,
    input  wire [ 3:0] mmu0_sel_i,
    output wire        mmu0_ack_o,

    // Enabling signals
    input wire mmu0_load_en_i,  // Load
    input wire mmu0_store_en_i, // Store
    input wire mmu0_fetch_en_i, // Fetch instruction
    input wire mmu0_flush_en_i, // Flush the TLB

    // Page faults
    output wire mmu0_load_pf_o,
    output wire mmu0_store_pf_o,
    output wire mmu0_fetch_pf_o,

    output wire mmu0_invalid_addr_o,

    /*
     * MMU master 1 input
     */

    // Data read and write
    input  wire [31:0] mmu1_v_addr_i,
    input  wire [31:0] mmu1_data_i,
    output wire [31:0] mmu1_data_o,
    input  wire [ 3:0] mmu1_sel_i,
    output wire        mmu1_ack_o,

    // Enabling signals
    input wire mmu1_load_en_i,  // Load
    input wire mmu1_store_en_i, // Store
    input wire mmu1_fetch_en_i, // Fetch instruction
    input wire mmu1_flush_en_i, // Flush the TLB

    // Page faults
    output wire mmu1_load_pf_o,
    output wire mmu1_store_pf_o,
    output wire mmu1_fetch_pf_o,

    output wire mmu1_invalid_addr_o,

    /*
     * MMU slave output
     */

    // Data read and write
    output wire [31:0] mmu_v_addr_o,
    output wire [31:0] mmu_data_o,
    input  wire [31:0] mmu_data_i,
    output wire [ 3:0] mmu_sel_o,
    input  wire        mmu_ack_i,

    // Enabling signals
    output wire mmu_load_en_o,  // Load
    output wire mmu_store_en_o, // Store
    output wire mmu_fetch_en_o, // Fetch instruction
    output wire mmu_flush_en_o, // Flush the TLB

    // Page faults
    input wire mmu_load_pf_i,
    input wire mmu_store_pf_i,
    input wire mmu_fetch_pf_i,

    input wire mmu_invalid_addr_i

);

wire [1:0] request;
wire [1:0] grant;
wire grant_valid;

assign request[0] = mmu0_load_en_i | mmu0_store_en_i | mmu0_fetch_en_i | mmu0_flush_en_i;
assign request[1] = mmu1_load_en_i | mmu1_store_en_i | mmu1_fetch_en_i | mmu1_flush_en_i;

wire mmu0_sel = grant[0] & grant_valid;
wire mmu1_sel = grant[1] & grant_valid;

// master 0
assign mmu0_data_o     = mmu_data_i;
assign mmu0_ack_o      = mmu_ack_i      & mmu0_sel;
assign mmu0_load_pf_o  = mmu_load_pf_i  & mmu0_sel;
assign mmu0_store_pf_o = mmu_store_pf_i & mmu0_sel;
assign mmu0_fetch_pf_o = mmu_fetch_pf_i & mmu0_sel;
assign mmu0_invalid_addr_o = mmu_invalid_addr_i & mmu0_sel;

// master 1
assign mmu1_data_o     = mmu_data_i;
assign mmu1_ack_o      = mmu_ack_i      & mmu1_sel;
assign mmu1_load_pf_o  = mmu_load_pf_i  & mmu1_sel;
assign mmu1_store_pf_o = mmu_store_pf_i & mmu1_sel;
assign mmu1_fetch_pf_o = mmu_fetch_pf_i & mmu1_sel;
assign mmu1_invalid_addr_o = mmu_invalid_addr_i & mmu1_sel;

// slave

assign mmu_v_addr_o = mmu0_sel ? mmu0_v_addr_i :
                      mmu1_sel ? mmu1_v_addr_i :
                      {ADDR_WIDTH{1'b0}};

assign mmu_data_o = mmu0_sel ? mmu0_data_i :
                    mmu1_sel ? mmu1_data_i :
                    {DATA_WIDTH{1'b0}};

assign mmu_sel_o = mmu0_sel ? mmu0_sel_i :
                   mmu1_sel ? mmu1_sel_i :
                   {SELECT_WIDTH{1'b0}};

assign mmu_load_en_o = mmu0_sel ? mmu0_load_en_i :
                       mmu1_sel ? mmu1_load_en_i :
                       1'b0;

assign mmu_store_en_o = mmu0_sel ? mmu0_store_en_i :
                        mmu1_sel ? mmu1_store_en_i :
                        1'b0;

assign mmu_fetch_en_o = mmu0_sel ? mmu0_fetch_en_i :
                        mmu1_sel ? mmu1_fetch_en_i :
                        1'b0;

assign mmu_flush_en_o = mmu0_sel ? mmu0_flush_en_i :
                        mmu1_sel ? mmu1_flush_en_i :
                        1'b0;

// arbiter instance
arbiter #(
    .PORTS(2),
    .ARB_TYPE_ROUND_ROBIN(ARB_TYPE_ROUND_ROBIN),
    .ARB_BLOCK(1),
    .ARB_BLOCK_ACK(0),
    .ARB_LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
)
arb_inst (
    .clk(clk),
    .rst(rst),
    .request(request),
    .acknowledge(),
    .grant(grant),
    .grant_valid(grant_valid),
    .grant_encoded()
);

endmodule
