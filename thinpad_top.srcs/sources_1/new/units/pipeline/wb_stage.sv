module wb_stage(
  input wire clk_i,
  input wire rst_i,

  // signals from MEM stage
  input wire [31:0] wb_pc_i,
  input wire [31:0] wb_instr_i,
  input wire [31:0] wb_rf_wdata_i,
  input wire [ 4:0] wb_rf_waddr_i,
  input wire        wb_rf_wen_i,

  // stall signals and flush signals
  input  wire       stall_i,
  input  wire       flush_i,

  // signals to regfile
  output reg [31:0] rf_wdata_o,
  output reg [ 4:0] rf_waddr_o,
  output reg        rf_wen_o,

  // signals to forward unit
  output reg [31:0] wb_rf_wdata_o,
  output reg [ 4:0] wb_rf_waddr_o,
  output reg        wb_rf_wen_o
);
  // pipeline registers
  logic [31:0] pc;
  logic [31:0] instr;
  logic [31:0] rf_wdata;
  logic [ 4:0] rf_waddr;
  logic        rf_wen;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
      rf_wdata <= 32'h0;
      rf_waddr <= 5'h0;
      rf_wen <= 1'b0;
    end else if (stall_i) begin
      // do nothing
    end else if (flush_i) begin
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
      rf_wdata <= 32'h0;
      rf_waddr <= 5'h0;
      rf_wen <= 1'b0;
    end else begin
      pc <= wb_pc_i;
      instr <= wb_instr_i;
      rf_wdata <= wb_rf_wdata_i;
      rf_waddr <= wb_rf_waddr_i;
      rf_wen <= wb_rf_wen_i;
    end
  end

  always_comb begin
    // regfile write signals
    rf_wdata_o = rf_wdata;
    rf_waddr_o = rf_waddr;
    rf_wen_o = rf_wen & ~stall_i;

    // signals to forward unit
    wb_rf_wdata_o = rf_wdata;
    wb_rf_waddr_o = rf_waddr;
    wb_rf_wen_o = rf_wen;
  end
endmodule