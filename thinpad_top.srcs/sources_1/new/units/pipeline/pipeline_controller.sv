`include "../../headers/exc.vh"
`include "../../headers/privilege.vh"
module pipeline_controller(
  input wire clk_i,
  input wire rst_i,

  // signals from IF stage
  input wire        if_if_busy_i,
  // pc signals to IF stage
  output reg [31:0] if_pc_o,
  output reg        if_pc_sel_o,

  // pc signals from EXE stage
  input wire [31:0] exe_if_pc_i,
  input wire        exe_if_pc_sel_i,  // 0: pc+4, 1: exe_pc
  input wire [31:0] exe_exe_pc_i,

  // signals from ID stage
  input wire [ 4:0] id_rf_raddr_a_i,
  input wire [ 4:0] id_rf_raddr_b_i,

  // signals from ID/EXE pipeline registers
  input wire [ 4:0] exe_rf_raddr_a_i,
  input wire [ 4:0] exe_rf_raddr_b_i,
  input wire        exe_mem_en_i,
  input wire        exe_mem_wen_i,
  input wire [ 4:0] exe_rf_waddr_i,

  // signals from EXE/MEM pipeline registers
  input wire [31:0] mem_rf_wdata_i,
  input wire [ 4:0] mem_rf_waddr_i,
  input wire        mem_rf_wen_i,
  input wire        mem_mem_en_i,
  input wire        mem_mem_wen_i,

  // signals from MEM stage
  input wire        mem_mem_busy_i,
  input wire        mem_tlb_flush_or_satp_update_i,
  input wire [`EXC_SIG_T_WIDTH-1:0] mem_exc_sig_i,

  // signals from MEM/WB pipeline registers
  input wire [31:0] wb_rf_wdata_i,
  input wire [ 4:0] wb_rf_waddr_i,
  input wire        wb_rf_wen_i,

  // forward signals to EXE stage
  output reg [31:0] exe_forward_alu_a_o,
  output reg [31:0] exe_forward_alu_b_o,
  output reg        exe_forward_alu_a_sel_o,
  output reg        exe_forward_alu_b_sel_o,

  // stall and flush signals
  output reg if_stall_o,
  output reg id_stall_o,
  output reg exe_stall_o,
  output reg mem_stall_o,
  output reg wb_stall_o,
  output reg if_flush_o,
  output reg id_flush_o,
  output reg exe_flush_o,
  output reg mem_flush_o,
  output reg wb_flush_o,

  // signals to exception unit
  output reg        exc_exc_en_o,
  output reg        exc_exc_ret_o,
  output reg [31:0] exc_cur_pc_o,
  output reg [30:0] exc_sync_exc_code_o,
  output reg [31:0] exc_mtval_o,

  // signals to MEM stage and exception unit
  output reg [ 1:0] privilege_o,

  // pc signals from exception unit
  input wire [31:0] exc_pc_i,
  input wire [ 1:0] exc_nxt_privilege_i
);

  logic       mem_busy;      // memory busy status
  logic [1:0] cpu_priv_lvl;  // cpu current privilege level
  logic       exc_handling;  // exception handling status
  exc_sig_t   exc_sig;       // exception signals

  assign mem_busy = if_if_busy_i | mem_mem_busy_i;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      cpu_priv_lvl <= `PRIVILEGE_M;
    end else begin
      if (exc_handling) begin
        cpu_priv_lvl <= exc_nxt_privilege_i;
      end
    end
  end

  /* ========== exception handler ========== */
  always_comb begin
    exc_sig = mem_exc_sig_i;
    exc_handling = (exc_sig.exc_occur | exc_sig.exc_ret) & ~mem_busy;

    exc_exc_en_o = exc_sig.exc_occur & ~mem_busy;
    exc_exc_ret_o = exc_sig.exc_ret & ~mem_busy;
    exc_cur_pc_o = exc_sig.cur_pc;
    exc_sync_exc_code_o = exc_sig.sync_exc_code;
    exc_mtval_o = exc_sig.mtval;
    privilege_o = cpu_priv_lvl;
  end

  /* ========== forward unit ========== */
  logic mem_forward_enable;
  logic wb_forward_enable;
  always_comb begin
    exe_forward_alu_a_o = 32'h0000_0000;
    exe_forward_alu_b_o = 32'h0000_0000;
    exe_forward_alu_a_sel_o = 1'b0;
    exe_forward_alu_b_sel_o = 1'b0;

    // exe(0) -> exe(1), exe(2)
    mem_forward_enable = mem_rf_wen_i;
    wb_forward_enable = wb_rf_wen_i;
    if (wb_forward_enable) begin
      if(wb_rf_waddr_i == exe_rf_raddr_a_i) begin
        exe_forward_alu_a_o = wb_rf_wdata_i;
        exe_forward_alu_a_sel_o = 1'b1;
      end
      if(wb_rf_waddr_i == exe_rf_raddr_b_i) begin
        exe_forward_alu_b_o = wb_rf_wdata_i;
        exe_forward_alu_b_sel_o = 1'b1;
      end
    end
    if (mem_forward_enable) begin
      if (mem_rf_waddr_i == exe_rf_raddr_a_i) begin
        exe_forward_alu_a_o = mem_rf_wdata_i;
        exe_forward_alu_a_sel_o = 1'b1;
      end
      if (mem_rf_waddr_i == exe_rf_raddr_b_i) begin
        exe_forward_alu_b_o = mem_rf_wdata_i;
        exe_forward_alu_b_sel_o = 1'b1;
      end
    end
  end

  /* ========== hazard detection unit ========== */
  logic load_use_hazard;

  always_comb begin
    // load use hazard
    if (exe_mem_en_i && !exe_mem_wen_i && 
    (exe_rf_waddr_i == id_rf_raddr_a_i || exe_rf_waddr_i == id_rf_raddr_b_i)) begin
      load_use_hazard = 1'b1;
    end else begin
      load_use_hazard = 1'b0;
    end

    if_stall_o = 1'b0;
    id_stall_o = 1'b0;
    exe_stall_o = 1'b0;
    mem_stall_o = 1'b0;
    wb_stall_o = 1'b0;
    if_flush_o = 1'b0;
    id_flush_o = 1'b0;
    exe_flush_o = 1'b0;
    mem_flush_o = 1'b0;
    wb_flush_o = 1'b0;

    if (mem_busy) begin  // stall if memory is busy
      if_stall_o = 1'b1;
      id_stall_o = 1'b1;
      exe_stall_o = 1'b1;
      mem_stall_o = 1'b1;
      wb_stall_o = 1'b1;
    end else if (exc_handling) begin  // flush if exception occurs
      id_flush_o = 1'b1;
      exe_flush_o = 1'b1;
      mem_flush_o = 1'b1;
      wb_flush_o = 1'b1;
    end else if (mem_tlb_flush_or_satp_update_i) begin  // flush if tlb flush occurs
      id_flush_o = 1'b1;
      exe_flush_o = 1'b1;
      mem_flush_o = 1'b1;
    end else if (exe_if_pc_sel_i == 1'b1) begin  // branch and jump
      id_flush_o = 1'b1;
      exe_flush_o = 1'b1;
    end
  end
  
  /* ========== PC MUX ========== */
  always_comb begin
    if_pc_o = exc_handling ? exc_pc_i :
              mem_tlb_flush_or_satp_update_i ? exe_exe_pc_i:
              exe_if_pc_sel_i ? exe_if_pc_i :
              32'h0000_0000;
    if_pc_sel_o = exc_handling | mem_tlb_flush_or_satp_update_i | exe_if_pc_sel_i;
  end

endmodule