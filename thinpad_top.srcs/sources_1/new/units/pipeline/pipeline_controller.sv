module pipeline_controller(
  input wire clk_i,
  input wire rst_i,

  // signals from IF stage
  input wire        if_busy_i,

  // pc signals from EXE stage
  input wire        exe_pc_sel_i,  // 0: pc+4, 1: exe_pc

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
  input wire [31:0] mem_alu_result_i,
  input wire [ 4:0] mem_rf_waddr_i,
  input wire        mem_rf_wen_i,
  input wire        mem_mem_en_i,
  input wire        mem_mem_wen_i,

  // signals from MEM stage
  input wire        mem_busy_i,

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
  output reg wb_flush_o
);

  /* ========== forward unit ==========*/
  logic mem_forward_enable;
  logic wb_forward_enable;
  always_comb begin
    exe_forward_alu_a_o = 32'h0000_0000;
    exe_forward_alu_b_o = 32'h0000_0000;
    exe_forward_alu_a_sel_o = 1'b0;
    exe_forward_alu_b_sel_o = 1'b0;

    // exe(0) -> exe(1), exe(2)
    mem_forward_enable = mem_rf_wen_i & ((~mem_mem_en_i) | mem_mem_wen_i);  // disable forwarding when loading
    wb_forward_enable = wb_rf_wen_i;
    if (wb_forward_enable) begin
      if(wb_rf_waddr_i == exe_rf_raddr_a_i) begin
        exe_forward_alu_a_o = wb_rf_wdata_i;
        exe_forward_alu_a_sel_o = 1'b1;
      end else if(wb_rf_waddr_i == exe_rf_raddr_b_i) begin
        exe_forward_alu_b_o = wb_rf_wdata_i;
        exe_forward_alu_b_sel_o = 1'b1;
      end
    end
    if (mem_forward_enable) begin
      if (mem_rf_waddr_i == exe_rf_raddr_a_i) begin
        exe_forward_alu_a_o = mem_alu_result_i;
        exe_forward_alu_a_sel_o = 1'b1;
      end else if (mem_rf_waddr_i == exe_rf_raddr_b_i) begin
        exe_forward_alu_b_o = mem_alu_result_i;
        exe_forward_alu_b_sel_o = 1'b1;
      end
    end
  end

  /* ========== hazard detection unit ==========*/
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

    // IF and MEM stages
    if (if_busy_i || mem_busy_i) begin
      if_stall_o = 1'b1;
      id_stall_o = 1'b1;
      exe_stall_o = 1'b1;
      mem_stall_o = 1'b1;
      wb_stall_o = 1'b1;
    end
    
    // ID stage: next instruction is a load instruction
    if (load_use_hazard) begin
      if_stall_o = 1'b1;
      id_stall_o = 1'b1;
      exe_flush_o = 1'b1;
    end

    // branch and jump
    if (exe_pc_sel_i == 1'b1) begin
      id_flush_o = 1'b1;
      exe_flush_o = 1'b1;
    end
  end

endmodule