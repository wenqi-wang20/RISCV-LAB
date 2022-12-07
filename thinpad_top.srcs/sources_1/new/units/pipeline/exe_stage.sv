`include "../../headers/alu.vh"
`include "../../headers/exc.vh"
`include "../../headers/privilege.vh"
module exe_stage(
  input wire clk_i,
  input wire rst_i,

  // signals from ID stage
  input wire        exe_flushed_i,
  input wire [31:0] exe_pc_i,
  input wire [31:0] exe_instr_i,
  input wire [ 4:0] exe_rf_raddr_a_i,
  input wire [ 4:0] exe_rf_raddr_b_i,
  input wire [31:0] exe_rf_rdata_a_i,
  input wire [31:0] exe_rf_rdata_b_i,
  input wire [31:0] exe_imm_i,
  input wire        exe_mem_en_i,
  input wire        exe_mem_wen_i,
  input wire [`ALU_OP_T_WIDTH-1:0] exe_alu_op_i,
  input wire        exe_alu_a_sel_i,  // 0: rs1, 1: pc
  input wire        exe_alu_b_sel_i,  // 0: rs2, 1: imm
  input wire [ 4:0] exe_rf_waddr_i,
  input wire        exe_rf_wen_i,
  input wire [`SYS_INSTR_T_WIDTH-1:0] exe_sys_instr_i,
  input wire [  `EXC_SIG_T_WIDTH-1:0] exe_exc_sig_i,

  // stall signals and flush signals
  input  wire       stall_i,
  input  wire       flush_i,

  // signals to pipeline controller (pc mux)
  output reg [31:0] if_pc_o,
  output reg        if_pc_sel_o,  // 0: pc+4, 1: exe_pc
  output reg [31:0] exe_pc_o,

  // signals to MEM stage
  output reg [31:0] mem_pc_o,
  output reg [31:0] mem_instr_o,
  output reg [31:0] mem_mem_wdata_o,
  output reg        mem_mem_en_o,
  output reg        mem_mem_wen_o,
  output reg [31:0] mem_alu_result_o,
  output reg [ 4:0] mem_rf_waddr_o,
  output reg        mem_rf_wen_o,
  output reg [31:0] mem_csr_rs1_data_o,
  output reg [ 4:0] mem_csr_rs1_addr_o,
  output reg [`SYS_INSTR_T_WIDTH-1:0] mem_sys_instr_o,
  output reg [  `EXC_SIG_T_WIDTH-1:0] mem_exc_sig_o,

  // signals from forward unit
  input wire [31:0] exe_forward_alu_a_i,
  input wire [31:0] exe_forward_alu_b_i,
  input wire        exe_forward_alu_a_sel_i,
  input wire        exe_forward_alu_b_sel_i,

  // signals to load use hazard handler
  output reg [ 4:0] exe_rf_raddr_a_o,
  output reg [ 4:0] exe_rf_raddr_b_o,
  output reg        exe_mem_en_o,
  output reg        exe_mem_wen_o,
  output reg [ 4:0] exe_rf_waddr_o,

  // signals from exception unit
  input wire        interrupt_i
);

  // pipeline registers
  logic        flushed;
  logic [31:0] pc;
  logic [31:0] instr;
  logic [ 4:0] rf_raddr_a;
  logic [ 4:0] rf_raddr_b;
  logic [31:0] rf_rdata_a;
  logic [31:0] rf_rdata_b;
  logic [31:0] imm;
  logic        mem_en;
  logic        mem_wen;
  logic [ 3:0] alu_op;
  logic        alu_a_sel;
  logic        alu_b_sel;
  logic [31:0] alu_result;
  logic [ 4:0] rf_waddr;
  logic        rf_wen;
  sys_instr_t  sys_instr;
  exc_sig_t    exc_sig;

  // alu signals
  logic [31:0] alu_a;
  logic [31:0] alu_b;

  // internal signals
  logic [ 6:0] opcode;
  logic [ 2:0] funct3;
  logic [ 6:0] funct7;
  logic [31:0] rf_rdata_a_exact;
  logic [31:0] rf_rdata_b_exact;
  exc_sig_t    exc_sig_gen;

  alu u_alu(
    .a(alu_a),
    .b(alu_b),
    .op(alu_op),
    .result(alu_result)
  );

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
			flushed <= 1'b1;
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
      rf_raddr_a <= 5'h0;
      rf_raddr_b <= 5'h0;
      rf_rdata_a <= 32'h0;
      rf_rdata_b <= 32'h0;
      imm <= 32'h0;
      alu_op <= ALU_ADD;
      alu_a_sel <= 1'b0;
      alu_b_sel <= 1'b0;
      mem_en <= 1'b0;
      mem_wen <= 1'b0;
      rf_waddr <= 5'h0;
      rf_wen <= 1'b0;
      sys_instr <= SYS_INSTR_NOP;
      exc_sig <= `EXC_SIG_NULL;
    end else if (stall_i) begin
      // do nothing
    end else if (flush_i) begin
			flushed <= 1'b1;
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
      rf_raddr_a <= 5'h0;
      rf_raddr_b <= 5'h0;
      rf_rdata_a <= 32'h0;
      rf_rdata_b <= 32'h0;
      imm <= 32'h0;
      alu_op <= ALU_ADD;
      alu_a_sel <= 1'b0;
      alu_b_sel <= 1'b0;
      mem_en <= 1'b0;
      mem_wen <= 1'b0;
      rf_waddr <= 5'h0;
      rf_wen <= 1'b0;
      sys_instr <= SYS_INSTR_NOP;
      exc_sig <= `EXC_SIG_NULL;
    end else begin
			flushed <= exe_flushed_i;
      pc <= exe_pc_i;
      instr <= exe_instr_i;
      rf_raddr_a <= exe_rf_raddr_a_i;
      rf_raddr_b <= exe_rf_raddr_b_i;
      rf_rdata_a <= exe_rf_rdata_a_i;
      rf_rdata_b <= exe_rf_rdata_b_i;
      imm <= exe_imm_i;
      alu_op <= exe_alu_op_i;
      alu_a_sel <= exe_alu_a_sel_i;
      alu_b_sel <= exe_alu_b_sel_i;
      mem_en <= exe_mem_en_i;
      mem_wen <= exe_mem_wen_i;
      rf_waddr <= exe_rf_waddr_i;
      rf_wen <= exe_rf_wen_i;
      sys_instr <= sys_instr_t'(exe_sys_instr_i);
      exc_sig <= exe_exc_sig_i;
    end
  end

  always_comb begin
    // exact register data
    rf_rdata_a_exact = exe_forward_alu_a_sel_i ? exe_forward_alu_a_i : rf_rdata_a;
    rf_rdata_b_exact = exe_forward_alu_b_sel_i ? exe_forward_alu_b_i : rf_rdata_b;

    // alu operands selection
    alu_a = alu_a_sel ? pc  : rf_rdata_a_exact;
    alu_b = alu_b_sel ? imm : rf_rdata_b_exact;

    opcode = instr[6:0];
    funct3 = instr[14:12];
    funct7 = instr[31:25];

    // branch and jump
    if_pc_o = pc + 4;
    if_pc_sel_o = 1'b0;
    if (opcode == 7'b110_0011) begin  // branch
      if (funct3 == 3'b000) begin
        // beq
        if (rf_rdata_a_exact == rf_rdata_b_exact) begin
          if_pc_o = alu_result;
          if_pc_sel_o = 1'b1;
        end
      end else if (funct3 == 3'b001) begin
        // bne
        if (rf_rdata_a_exact != rf_rdata_b_exact) begin
          if_pc_o = alu_result;
          if_pc_sel_o = 1'b1;
        end
      end else if (funct3 == 3'b100) begin
        // blt
        if ($signed(rf_rdata_a_exact) < $signed(rf_rdata_b_exact)) begin
          if_pc_o = alu_result;
          if_pc_sel_o = 1'b1;
        end
      end else if (funct3 == 3'b101) begin
        // bge
        if ($signed(rf_rdata_a_exact) >= $signed(rf_rdata_b_exact)) begin
          if_pc_o = alu_result;
          if_pc_sel_o = 1'b1;
        end
      end else if (funct3 == 3'b110) begin
        // bltu
        if ($unsigned(rf_rdata_a_exact) < $unsigned(rf_rdata_b_exact)) begin
          if_pc_o = alu_result;
          if_pc_sel_o = 1'b1;
        end
      end else if (funct3 == 3'b111) begin
        // bgeu
        if ($unsigned(rf_rdata_a_exact) >= $unsigned(rf_rdata_b_exact)) begin
          if_pc_o = alu_result;
          if_pc_sel_o = 1'b1;
        end
      end
    end else if (opcode == 7'b110_1111) begin
      // jal
      if_pc_o = alu_result;
      if_pc_sel_o = 1'b1;
    end else if (opcode == 7'b110_0111) begin
      // jalr
      if_pc_o = alu_result & 32'hfffffffe;
      if_pc_sel_o = 1'b1;
    end

    // tbl flush
    exe_pc_o = pc;

    // exception signals generation
    if (interrupt_i && !flushed) begin
      exc_sig_gen.exc_occur = 1'b1;
      exc_sig_gen.exc_ret = 1'b0;
      exc_sig_gen.cur_pc = pc;
      exc_sig_gen.sync_exc_code = 31'h0;
      exc_sig_gen.mtval = 32'h0;
    end else begin
      exc_sig_gen = exc_sig;
    end
    mem_exc_sig_o = exc_sig_gen;

    // signals to MEM stage
    mem_pc_o = pc;
    mem_instr_o = instr;
    mem_mem_wdata_o = rf_rdata_b_exact;
    mem_mem_en_o = mem_en & ~exc_sig_gen.exc_occur;
    mem_mem_wen_o = mem_wen;
    mem_alu_result_o = alu_result;
    mem_rf_waddr_o = rf_waddr;
    mem_rf_wen_o = rf_wen & ~exc_sig_gen.exc_occur;
    mem_sys_instr_o = sys_instr;
    mem_csr_rs1_data_o = rf_rdata_a_exact;
    mem_csr_rs1_addr_o = rf_raddr_a;

    // signals to forward unit
    exe_rf_raddr_a_o = rf_raddr_a;
    exe_rf_raddr_b_o = rf_raddr_b;
    exe_mem_en_o = mem_en;
    exe_mem_wen_o = mem_wen;
    exe_rf_waddr_o = rf_waddr;

  end
endmodule