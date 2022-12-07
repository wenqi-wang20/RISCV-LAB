`include "../../headers/exc.vh"
`include "../../headers/privilege.vh"
module id_stage(
  input wire clk_i,
  input wire rst_i,

  // signals from IF stage
  input wire [31:0] id_pc_i,
  input wire [31:0] id_instr_i,
  input wire [`EXC_SIG_T_WIDTH-1:0] id_exc_sig_i,

  // stall signals and flush signals
  input wire        stall_i,
  input wire        flush_i,

  // current privilege level
  input wire [ 1:0] privilege_i,

  // regfile signals
  input wire [31:0] rf_rdata_a_i,
  input wire [31:0] rf_rdata_b_i,
  output reg [ 4:0] rf_raddr_a_o,
  output reg [ 4:0] rf_raddr_b_o,

  // signals to EXE stage
  output reg        exe_flushed_o,
  output reg [31:0] exe_pc_o,
  output reg [31:0] exe_instr_o,
  output reg [ 4:0] exe_rf_raddr_a_o,
  output reg [ 4:0] exe_rf_raddr_b_o,
  output reg [31:0] exe_rf_rdata_a_o,
  output reg [31:0] exe_rf_rdata_b_o,
  output reg [31:0] exe_imm_o,
  output reg        exe_mem_en_o,
  output reg        exe_mem_wen_o,
  output reg [`ALU_OP_T_WIDTH-1:0] exe_alu_op_o,
  output reg        exe_alu_a_sel_o,  // 0: rs1, 1: pc
  output reg        exe_alu_b_sel_o,  // 0: rs2, 1: imm
  output reg [ 4:0] exe_rf_waddr_o,
  output reg        exe_rf_wen_o,

  output reg [`SYS_INSTR_T_WIDTH-1:0] exe_sys_instr_o,
  output reg [  `EXC_SIG_T_WIDTH-1:0] exe_exc_sig_o,

  // signals to forward unit
  output reg [ 4:0] id_rf_raddr_a_o,
  output reg [ 4:0] id_rf_raddr_b_o
);

  // pipeline registers
  logic [31:0] pc;
  logic [31:0] instr;
  exc_sig_t    exc_sig;

  // generated signals
  logic        flushed;
  logic [31:0] imm;
  logic        mem_en;
  logic        mem_wen;
  logic [`ALU_OP_T_WIDTH-1:0] alu_op;
  logic        alu_a_sel;
  logic        alu_b_sel;
  logic [ 4:0] rf_raddr_a;
  logic [ 4:0] rf_raddr_b;
  logic [ 4:0] rf_waddr;
  logic        rf_wen;
  logic        instr_legal;
  logic [`SYS_INSTR_T_WIDTH-1:0] sys_instr;
  exc_sig_t    exc_sig_gen;

  instr_decoder u_instr_decoder(
    .instr_i(instr),
    .privilege_i(privilege_i),
    .imm_o(imm),
    .mem_en_o(mem_en),
    .mem_wen_o(mem_wen),
    .alu_op_o(alu_op),
    .alu_a_sel_o(alu_a_sel),  // 0: rs1, 1: pc
    .alu_b_sel_o(alu_b_sel),  // 0: rs2, 1: imm
    .rf_raddr_a_o(rf_raddr_a),
    .rf_raddr_b_o(rf_raddr_b),
    .rf_waddr_o(rf_waddr),
    .rf_wen_o(rf_wen),
    .instr_legal_o(instr_legal),
    .sys_instr_o(sys_instr)
  );

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      flushed <= 1'b1;
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
      exc_sig <= `EXC_SIG_NULL;
    end else if (stall_i) begin
      // do nothing
    end else if (flush_i) begin
      flushed <= 1'b1;
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
      exc_sig <= `EXC_SIG_NULL;
    end else begin
      flushed <= 1'b0;
      pc <= id_pc_i;
      instr <= id_instr_i;
      exc_sig <= id_exc_sig_i;
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
    exe_flushed_o = flushed;
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
    exe_sys_instr_o = sys_instr;

    // exception signals to EXE stage
    if (!instr_legal) begin
      exc_sig_gen.exc_occur = 1'b1;
      exc_sig_gen.exc_ret = 1'b0;
      exc_sig_gen.cur_pc = pc;
      exc_sig_gen.sync_exc_code = `EXC_ILLEGAL_INSTRUCTION;
      exc_sig_gen.mtval = 32'h0;
    end else begin
      exc_sig_gen = exc_sig;
    end
    exe_exc_sig_o = exc_sig_gen;
  end
endmodule