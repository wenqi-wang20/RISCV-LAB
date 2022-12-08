`include "../../headers/alu.vh"
`include "../../headers/exc.vh"
module pipeline(
  input wire clk_i,
  input wire rst_i,


  /* ========== MMU signals ========== */
  // output wire [31:0] mmu_satp_o,

  // MEM-stage: load/store data
  input  wire [31:0] mmu0_data_i,
  input  wire        mmu0_ack_i,
  output wire [31:0] mmu0_v_addr_o,
  output wire [ 3:0] mmu0_sel_o,
  output wire [31:0] mmu0_data_o,

  output wire mmu0_load_en_o,  // Load
  output wire mmu0_store_en_o, // Store
  output wire mmu0_fetch_en_o, // Fetch instruction
  output wire mmu0_flush_en_o, // Flush the TLB

  input wire mmu0_load_pf_i,
  input wire mmu0_store_pf_i,
  input wire mmu0_fetch_pf_i,
  input wire mmu0_invalid_addr_i,

  // IF-stage: instruction fetch
  input  wire [31:0] mmu1_data_i,
  input  wire        mmu1_ack_i,
  output reg  [31:0] mmu1_v_addr_o,
  output reg  [ 3:0] mmu1_sel_o,
  output reg  [31:0] mmu1_data_o,

  output reg mmu1_load_en_o,  // Load
  output reg mmu1_store_en_o, // Store
  output reg mmu1_fetch_en_o, // Fetch instruction
  output reg mmu1_flush_en_o, // Flush the TLB

  input wire mmu1_load_pf_i,
  input wire mmu1_store_pf_i,
  input wire mmu1_fetch_pf_i,
  input wire mmu1_invalid_addr_i,

  /* ========== regfile signals ========== */
  input  wire [31:0] rf_rdata_a_i,
  input  wire [31:0] rf_rdata_b_i,
  output wire [ 4:0] rf_raddr_a_o,
  output wire [ 4:0] rf_raddr_b_o,
  output wire [ 4:0] rf_waddr_o,
  output wire [31:0] rf_wdata_o,
  output wire        rf_wen_o,

  /* ========== exception unit signals ========== */
  input  wire        exc_interrupt_i,
  input  wire [31:0] exc_csr_rdata_i,
  input  wire        exc_csr_invalid_r_i,
  input  wire        exc_csr_invalid_w_i,
  output wire [11:0] exc_csr_raddr_o,
  output wire [11:0] exc_csr_waddr_o,
  output wire [31:0] exc_csr_wdata_o,
  output wire        exc_csr_wen_o,
  output wire        exc_exc_en_o,
  output wire        exc_exc_ret_o,
  output wire [31:0] exc_cur_pc_o,
  output wire [30:0] exc_sync_exc_code_o,
  output wire [31:0] exc_mtval_o,
  output wire [ 1:0] exc_privilege_o,

  input  wire [31:0] exc_next_pc_i,
  input  wire [ 1:0] exc_nxt_privilege_i
);

  // basic mmu version
  // assign mmu_satp_o = 32'h0;


  // IF signals
  logic [31:0] if_id_pc;
  logic [31:0] if_id_instr;
  logic [`EXC_SIG_T_WIDTH-1:0] if_id_exc_sig;

  // ID signals
  logic        id_exe_flushed;
  logic [31:0] id_exe_pc;
  logic [31:0] id_exe_instr;
  logic [ 4:0] id_exe_rf_raddr_a;
  logic [ 4:0] id_exe_rf_raddr_b;
  logic [31:0] id_exe_rf_rdata_a;
  logic [31:0] id_exe_rf_rdata_b;
  logic [31:0] id_exe_imm;
  logic        id_exe_mem_en;
  logic        id_exe_mem_wen;
  logic [`ALU_OP_T_WIDTH-1:0] id_exe_alu_op;
  logic        id_exe_alu_a_sel;
  logic        id_exe_alu_b_sel;
  logic [ 4:0] id_exe_rf_waddr;
  logic        id_exe_rf_wen;
  logic [`SYS_INSTR_T_WIDTH-1:0] id_exe_sys_instr;
  logic [  `EXC_SIG_T_WIDTH-1:0] id_exe_exc_sig;

  // EXE signals
  logic [31:0] exe_mem_pc;
  logic [31:0] exe_mem_instr;
  logic [31:0] exe_mem_mem_data;
  logic        exe_mem_mem_en;
  logic        exe_mem_mem_wen;
  logic [31:0] exe_mem_alu_result;
  logic [ 4:0] exe_mem_rf_waddr;
  logic        exe_mem_rf_wen;
  logic [31:0] exe_if_pc;
  logic        exe_if_pc_sel;
  logic [31:0] exe_exe_pc;
  logic [31:0] exe_forward_alu_a;
  logic [31:0] exe_forward_alu_b;
  logic        exe_forward_alu_a_sel;
  logic        exe_forward_alu_b_sel;
  logic [31:0] exe_mem_csr_rs1_data;
  logic [ 4:0] exe_mem_csr_rs1_addr;
  logic [`SYS_INSTR_T_WIDTH-1:0] exe_mem_sys_instr;
  logic [  `EXC_SIG_T_WIDTH-1:0] exe_mem_exc_sig;

  // MEM signals
  logic [31:0] mem_wb_pc;
  logic [31:0] mem_wb_instr;
  logic [31:0] mem_wb_rf_wdata;
  logic [ 4:0] mem_wb_rf_waddr;
  logic        mem_wb_rf_wen;

  // pipeline controller signals
  logic        if_busy;

  logic [31:0] if_pc;
  logic        if_pc_sel;

  logic [ 4:0] id_rf_raddr_a;
  logic [ 4:0] id_rf_raddr_b;

  logic [ 4:0] exe_rf_raddr_a;
  logic [ 4:0] exe_rf_raddr_b;
  logic        exe_mem_en;
  logic        exe_mem_wen;
  logic [ 4:0] exe_rf_waddr;

  logic [31:0] mem_rf_wdata;
  logic [ 4:0] mem_rf_waddr;
  logic        mem_rf_wen;
  logic        mem_mem_en;
  logic        mem_mem_wen;

  logic        mem_busy;
  logic        mem_tlb_flush_or_satp_update;
  logic [`EXC_SIG_T_WIDTH-1:0] mem_exc_sig;

  logic [ 1:0] privilege;

  logic [31:0] wb_rf_wdata;
  logic [ 4:0] wb_rf_waddr;
  logic        wb_rf_wen;

  logic if_stall;
  logic id_stall;
  logic exe_stall;
  logic mem_stall;
  logic wb_stall;
  logic if_flush;
  logic id_flush;
  logic exe_flush;
  logic mem_flush;
  logic wb_flush;


  /* ========== IF stage ========== */
  if_stage u_if_stage(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // mmu signals
    .mmu_data_i(mmu1_data_i),
    .mmu_ack_i(mmu1_ack_i),
    .mmu_v_addr_o(mmu1_v_addr_o),
    .mmu_sel_o(mmu1_sel_o),
    .mmu_data_o(mmu1_data_o),
    .mmu_load_en_o(mmu1_load_en_o),
    .mmu_store_en_o(mmu1_store_en_o),
    .mmu_fetch_en_o(mmu1_fetch_en_o),
    .mmu_flush_en_o(mmu1_flush_en_o),
    .mmu_load_pf_i(mmu1_load_pf_i),
    .mmu_store_pf_i(mmu1_store_pf_i),
    .mmu_fetch_pf_i(mmu1_fetch_pf_i),
    .mmu_invalid_addr_i(mmu1_invalid_addr_i),

    // stall signals and flush signals
    .stall_i(if_stall),
    .flush_i(if_flush),

      // tlb flush or sapt update signals
    .tlb_flush_or_satp_update_i(mem_tlb_flush_or_satp_update),

    // pc mux signals
    .pc_sel_i(if_pc_sel),
    .pc_i(if_pc),

    // signals to ID stage
    .id_pc_o(if_id_pc),
    .id_instr_o(if_id_instr),
    .id_exc_sig_o(if_id_exc_sig),

    // signals to harzard handler
    .if_busy_o(if_busy)
  );

  /* ========== ID stage ========== */
  id_stage u_id_stage(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // signals from IF stage
    .id_pc_i(if_id_pc),
    .id_instr_i(if_id_instr),
    .id_exc_sig_i(if_id_exc_sig),

    // stall signals and flush signals
    .stall_i(id_stall),
    .flush_i(id_flush),

    // current privilege level
    .privilege_i(privilege),

    // regfile signals
    .rf_rdata_a_i(rf_rdata_a_i),
    .rf_rdata_b_i(rf_rdata_b_i),
    .rf_raddr_a_o(rf_raddr_a_o),
    .rf_raddr_b_o(rf_raddr_b_o),

    // signals to EXE stage
    .exe_flushed_o(id_exe_flushed),
    .exe_pc_o(id_exe_pc),
    .exe_instr_o(id_exe_instr),
    .exe_rf_raddr_a_o(id_exe_rf_raddr_a),
    .exe_rf_raddr_b_o(id_exe_rf_raddr_b),
    .exe_rf_rdata_a_o(id_exe_rf_rdata_a),
    .exe_rf_rdata_b_o(id_exe_rf_rdata_b),
    .exe_imm_o(id_exe_imm),
    .exe_mem_en_o(id_exe_mem_en),
    .exe_mem_wen_o(id_exe_mem_wen),
    .exe_alu_op_o(id_exe_alu_op),
    .exe_alu_a_sel_o(id_exe_alu_a_sel),  // 0: pc, 1: rs1
    .exe_alu_b_sel_o(id_exe_alu_b_sel),  // 0: rs2, 1: imm
    .exe_rf_waddr_o(id_exe_rf_waddr),
    .exe_rf_wen_o(id_exe_rf_wen),
    .exe_sys_instr_o(id_exe_sys_instr),
    .exe_exc_sig_o(id_exe_exc_sig),

    // signals to harzard handler
    .id_rf_raddr_a_o(id_rf_raddr_a),
    .id_rf_raddr_b_o(id_rf_raddr_b)
  );

  /* ========== EXE stage ========== */
  exe_stage u_exe_stage(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // signals from ID stage
    .exe_flushed_i(id_exe_flushed),
    .exe_pc_i(id_exe_pc),
    .exe_instr_i(id_exe_instr),
    .exe_rf_raddr_a_i(id_exe_rf_raddr_a),
    .exe_rf_raddr_b_i(id_exe_rf_raddr_b),
    .exe_rf_rdata_a_i(id_exe_rf_rdata_a),
    .exe_rf_rdata_b_i(id_exe_rf_rdata_b),
    .exe_imm_i(id_exe_imm),
    .exe_mem_en_i(id_exe_mem_en),
    .exe_mem_wen_i(id_exe_mem_wen),
    .exe_alu_op_i(id_exe_alu_op),
    .exe_alu_a_sel_i(id_exe_alu_a_sel),
    .exe_alu_b_sel_i(id_exe_alu_b_sel),
    .exe_rf_waddr_i(id_exe_rf_waddr),
    .exe_rf_wen_i(id_exe_rf_wen),
    .exe_sys_instr_i(id_exe_sys_instr),
    .exe_exc_sig_i(id_exe_exc_sig),

    // stall signals and flush signals
    .stall_i(exe_stall),
    .flush_i(exe_flush),

    .if_pc_o(exe_if_pc),
    .if_pc_sel_o(exe_if_pc_sel),     // 0: pc+4, 1: exe_pc
    .exe_pc_o(exe_exe_pc),

    // signals to MEM stage
    .mem_pc_o(exe_mem_pc),
    .mem_instr_o(exe_mem_instr),
    .mem_mem_wdata_o(exe_mem_mem_data),
    .mem_mem_en_o(exe_mem_mem_en),
    .mem_mem_wen_o(exe_mem_mem_wen),
    .mem_alu_result_o(exe_mem_alu_result),
    .mem_rf_waddr_o(exe_mem_rf_waddr),
    .mem_rf_wen_o(exe_mem_rf_wen),
    .mem_csr_rs1_data_o(exe_mem_csr_rs1_data),
    .mem_csr_rs1_addr_o(exe_mem_csr_rs1_addr),
    .mem_sys_instr_o(exe_mem_sys_instr),
    .mem_exc_sig_o(exe_mem_exc_sig),

    // signals from forward unit
    .exe_forward_alu_a_i(exe_forward_alu_a),
    .exe_forward_alu_b_i(exe_forward_alu_b),
    .exe_forward_alu_a_sel_i(exe_forward_alu_a_sel),
    .exe_forward_alu_b_sel_i(exe_forward_alu_b_sel),

    // signals to load use hazard handler
    .exe_rf_raddr_a_o(exe_rf_raddr_a),
    .exe_rf_raddr_b_o(exe_rf_raddr_b),
    .exe_mem_en_o(exe_mem_en),
    .exe_mem_wen_o(exe_mem_wen),
    .exe_rf_waddr_o(exe_rf_waddr),

    // interrupt signals
    .interrupt_i(exc_interrupt_i)
    );

  /* ========== MEM stage ========== */
  mem_stage u_mem_stage(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // mmu signals
    .mmu_data_i(mmu0_data_i),
    .mmu_ack_i(mmu0_ack_i),
    .mmu_v_addr_o(mmu0_v_addr_o),
    .mmu_sel_o(mmu0_sel_o),
    .mmu_data_o(mmu0_data_o),
    .mmu_load_en_o(mmu0_load_en_o),
    .mmu_store_en_o(mmu0_store_en_o),
    .mmu_fetch_en_o(mmu0_fetch_en_o),
    .mmu_flush_en_o(mmu0_flush_en_o),
    .mmu_load_pf_i(mmu0_load_pf_i),
    .mmu_store_pf_i(mmu0_store_pf_i),
    .mmu_fetch_pf_i(mmu0_fetch_pf_i),
    .mmu_invalid_addr_i(mmu0_invalid_addr_i),

    // signals from EXE stage
    .mem_pc_i(exe_mem_pc),
    .mem_instr_i(exe_mem_instr),
    .mem_mem_wdata_i(exe_mem_mem_data),
    .mem_mem_en_i(exe_mem_mem_en),
    .mem_mem_wen_i(exe_mem_mem_wen),
    .mem_alu_result_i(exe_mem_alu_result),
    .mem_rf_waddr_i(exe_mem_rf_waddr),
    .mem_rf_wen_i(exe_mem_rf_wen),
    .mem_csr_rs1_data_i(exe_mem_csr_rs1_data),
    .mem_csr_rs1_addr_i(exe_mem_csr_rs1_addr),
    .mem_sys_instr_i(exe_mem_sys_instr),
    .mem_exc_sig_i(exe_mem_exc_sig),

    // stall signals and flush signals
    .stall_i(mem_stall),
    .flush_i(mem_flush),

    // signals from CPU
    .privilege_i(privilege),

    // signals to WB(write back) stage
    .wb_pc_o(mem_wb_pc),
    .wb_instr_o(mem_wb_instr),
    .wb_rf_wdata_o(mem_wb_rf_wdata),
    .wb_rf_waddr_o(mem_wb_rf_waddr),
    .wb_rf_wen_o(mem_wb_rf_wen),

    // signals to forward unit
    .mem_rf_wdata_o(mem_rf_wdata),
    .mem_rf_waddr_o(mem_rf_waddr),
    .mem_rf_wen_o(mem_rf_wen),
    .mem_mem_en_o(mem_mem_en),
    .mem_mem_wen_o(mem_mem_wen),

    // signals to hazard detection unit
    .mem_busy_o(mem_busy),
    .mem_tlb_flush_or_satp_update_o(mem_tlb_flush_or_satp_update),

    // signals from/to exception unit
    .csr_rdata_i(exc_csr_rdata_i),
    .csr_invalid_r_i(exc_csr_invalid_r_i),
    .csr_invalid_w_i(exc_csr_invalid_w_i),
    .csr_raddr_o(exc_csr_raddr_o),
    .csr_waddr_o(exc_csr_waddr_o),
    .csr_wdata_o(exc_csr_wdata_o),
    .csr_wen_o(exc_csr_wen_o),

  // signals to exception handler
    .exc_sig_o(mem_exc_sig)
  );

  /* ========== WB(write back) stage ========== */
  wb_stage u_wb_stage(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // signals from MEM stage
    .wb_pc_i(mem_wb_pc),
    .wb_instr_i(mem_wb_instr),
    .wb_rf_wdata_i(mem_wb_rf_wdata),
    .wb_rf_waddr_i(mem_wb_rf_waddr),
    .wb_rf_wen_i(mem_wb_rf_wen),

    // stall signals and flush signals
    .stall_i(wb_stall),
    .flush_i(wb_flush),

    // signals to regfile
    .rf_wdata_o(rf_wdata_o),
    .rf_waddr_o(rf_waddr_o),
    .rf_wen_o(rf_wen_o),

    // signals to forward unit
    .wb_rf_wdata_o(wb_rf_wdata),
    .wb_rf_waddr_o(wb_rf_waddr),
    .wb_rf_wen_o(wb_rf_wen)
  );

  /* ========== Pipeline Controller ========== */
  pipeline_controller u_pipeline_controller(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // signals from IF stage
    .if_if_busy_i(if_busy),
    .if_pc_o(if_pc),
    .if_pc_sel_o(if_pc_sel),

    // pc signals from EXE stage
    .exe_if_pc_i(exe_if_pc),
    .exe_if_pc_sel_i(exe_if_pc_sel),  // 0: pc+4, 1: exe_pc
    .exe_exe_pc_i(exe_exe_pc),

    // signals from ID stage
    .id_rf_raddr_a_i(id_rf_raddr_a),
    .id_rf_raddr_b_i(id_rf_raddr_b),

    // signals from ID/EXE pipeline registers
    .exe_rf_raddr_a_i(exe_rf_raddr_a),
    .exe_rf_raddr_b_i(exe_rf_raddr_b),
    .exe_mem_en_i(exe_mem_en),
    .exe_mem_wen_i(exe_mem_wen),
    .exe_rf_waddr_i(exe_rf_waddr),

    // signals from EXE/MEM pipeline registers
    .mem_rf_wdata_i(mem_rf_wdata),
    .mem_rf_waddr_i(mem_rf_waddr),
    .mem_rf_wen_i(mem_rf_wen),
    .mem_mem_en_i(mem_mem_en),
    .mem_mem_wen_i(mem_mem_wen),

    // signals from MEM stage
    .mem_mem_busy_i(mem_busy),
    .mem_tlb_flush_or_satp_update_i(mem_tlb_flush_or_satp_update),
    .mem_exc_sig_i(mem_exc_sig),

    // signals from MEM/WB pipeline registers
    .wb_rf_wdata_i(wb_rf_wdata),
    .wb_rf_waddr_i(wb_rf_waddr),
    .wb_rf_wen_i(wb_rf_wen),

    // forward signals to EXE stage
    .exe_forward_alu_a_o(exe_forward_alu_a),
    .exe_forward_alu_b_o(exe_forward_alu_b),
    .exe_forward_alu_a_sel_o(exe_forward_alu_a_sel),
    .exe_forward_alu_b_sel_o(exe_forward_alu_b_sel),

    // stall and flush signals
    .if_stall_o(if_stall),
    .id_stall_o(id_stall),
    .exe_stall_o(exe_stall),
    .mem_stall_o(mem_stall),
    .wb_stall_o(wb_stall),
    .if_flush_o(if_flush),
    .id_flush_o(id_flush),
    .exe_flush_o(exe_flush),
    .mem_flush_o(mem_flush),
    .wb_flush_o(wb_flush),

    // signals to exception unit
    .exc_exc_en_o(exc_exc_en_o),
    .exc_exc_ret_o(exc_exc_ret_o),
    .exc_cur_pc_o(exc_cur_pc_o),
    .exc_sync_exc_code_o(exc_sync_exc_code_o),
    .exc_mtval_o(exc_mtval_o),
    .privilege_o(privilege),

    // pc signals from exception unit
    .exc_pc_i(exc_next_pc_i),
    .exc_nxt_privilege_i(exc_nxt_privilege_i)
  );
  assign exc_privilege_o = privilege;
endmodule