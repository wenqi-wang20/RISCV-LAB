module id_stage(
  input wire clk_i,
  input wire rst_i,

  // signals from IF stage
  input wire [31:0] id_pc_i,
  input wire [31:0] id_instr_i,

  // stall signals and flush signals
  input  wire        stall_i,
  input  wire        flush_i,

  // regfile signals
  input wire [31:0] rf_rdata_a_i,
  input wire [31:0] rf_rdata_b_i,
  output reg [ 4:0] rf_raddr_a_o,
  output reg [ 4:0] rf_raddr_b_o,

  // signals to EXE stage
  output reg [31:0] exe_pc_o,
  output reg [31:0] exe_instr_o,
  output reg [ 4:0] exe_rf_raddr_a_o,
  output reg [ 4:0] exe_rf_raddr_b_o,
  output reg [31:0] exe_rf_rdata_a_o,
  output reg [31:0] exe_rf_rdata_b_o,
  output reg [31:0] exe_imm_o,
  output reg        exe_mem_en_o,
  output reg        exe_mem_wen_o,
  output reg [ 3:0] exe_alu_op_o,
  output reg        exe_alu_a_sel_o,  // 0: rs1, 1: pc
  output reg        exe_alu_b_sel_o,  // 0: rs2, 1: imm
  output reg [ 4:0] exe_rf_waddr_o,
  output reg        exe_rf_wen_o,

  // signals to forward unit
  output reg [ 4:0] id_rf_raddr_a_o,
  output reg [ 4:0] id_rf_raddr_b_o
);

  // pipeline registers
  logic [31:0] pc;
  logic [31:0] instr;

  // generated signals
  logic [31:0] imm;
  logic        mem_en;
  logic        mem_wen;
  logic [ 3:0] alu_op;
  logic        alu_a_sel;
  logic        alu_b_sel;
  logic [ 4:0] rf_raddr_a;
  logic [ 4:0] rf_raddr_b;
  logic [ 4:0] rf_waddr;
  logic        rf_wen;

  instr_decoder u_instr_decoder(
    .instr_i(instr),
    .imm_o(imm),
    .mem_en_o(mem_en),
    .mem_wen_o(mem_wen),
    .alu_op_o(alu_op),
    .alu_a_sel_o(alu_a_sel),  // 0: rs1, 1: pc
    .alu_b_sel_o(alu_b_sel),  // 0: rs2, 1: imm
    .rf_raddr_a_o(rf_raddr_a),
    .rf_raddr_b_o(rf_raddr_b),
    .rf_waddr_o(rf_waddr),
    .rf_wen_o(rf_wen)
  );

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
    end else if (stall_i) begin
      // do nothing
    end else if (flush_i) begin
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
    end else begin
      pc <= id_pc_i;
      instr <= id_instr_i;
    end
  end

  always_comb begin
    // read registers
    rf_raddr_a_o = rf_raddr_a;
    rf_raddr_b_o = rf_raddr_b;

    // signals to forward unit
    id_rf_raddr_a_o = rf_raddr_a;
    id_rf_raddr_b_o = rf_raddr_b;
    
    // signals to EXE stage
    exe_pc_o = pc;
    exe_instr_o = instr;
    exe_rf_raddr_a_o = rf_raddr_a;
    exe_rf_raddr_b_o = rf_raddr_b;
    exe_rf_rdata_a_o = rf_rdata_a_i;
    exe_rf_rdata_b_o = rf_rdata_b_i;
    exe_imm_o = imm;
    exe_mem_en_o = mem_en;
    exe_mem_wen_o = mem_wen;
    exe_alu_op_o = alu_op;
    exe_alu_a_sel_o = alu_a_sel;
    exe_alu_b_sel_o = alu_b_sel;
    exe_rf_wen_o = rf_wen;
    exe_rf_waddr_o = rf_waddr;
  end
endmodule