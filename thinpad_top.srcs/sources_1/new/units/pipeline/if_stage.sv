`include "../../headers/exc.vh"
module if_stage(
  input wire clk_i,
  input wire rst_i,

  // mmu signals
  input  wire [31:0] mmu_data_i,
  input  wire        mmu_ack_i,
  output reg  [31:0] mmu_v_addr_o,
  output reg  [ 3:0] mmu_sel_o,
  output reg  [31:0] mmu_data_o,
  output reg         mmu_load_en_o,  // Load
  output reg         mmu_store_en_o, // Store
  output reg         mmu_fetch_en_o, // Fetch instruction
  output reg         mmu_flush_en_o, // Flush the TLB
  input  wire        mmu_load_pf_i,
  input  wire        mmu_store_pf_i,
  input  wire        mmu_fetch_pf_i,
  input  wire        mmu_invalid_addr_i,

  // stall signals and flush signals
  input wire        stall_i,
  input wire        flush_i,

  // tlb flush signals
  input wire        tlb_flush_or_satp_update_i,

  // pc mux signals
  input wire        pc_sel_i,
  input wire [31:0] pc_i,

  // signals to ID stage
  output reg [31:0] id_pc_o,
  output reg [31:0] id_instr_o,
  output reg [`EXC_SIG_T_WIDTH-1:0] id_exc_sig_o,

  // signals to hazard handler
  output reg if_busy_o
);
  typedef enum logic {
    IF_ACCESS = 1'b0,
    IF_DONE = 1'b1
  } if_state_t;

  if_state_t if_state, if_next_state;

  // internal registers
  logic [31:0] pc;
  logic [31:0] instr;
  exc_sig_t    exc_sig_gen;

  // internal signals
  logic [31:0] pc_next;
  logic        pc_misaligned;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin 
      if_state <= IF_ACCESS;
      instr <= 32'h0000_0000;
      exc_sig_gen <= `EXC_SIG_NULL;
    end else begin
      if_state <= if_next_state;
      if (mmu_fetch_pf_i) begin
        instr <= 32'h0000_0013;  // nop for exception
        exc_sig_gen.exc_occur <= 1'b1;
        exc_sig_gen.cur_pc <= pc;
        exc_sig_gen.sync_exc_code <= `EXC_INSTRUCTION_PAGE_FAULT;
        exc_sig_gen.mtval <= pc;
      end else if (mmu_invalid_addr_i) begin
        instr <= 32'h0000_0013;  // nop for exception
        exc_sig_gen.exc_occur <= 1'b1;
        exc_sig_gen.cur_pc <= pc;
        exc_sig_gen.sync_exc_code <= `EXC_INSTRUCTION_ACCESS_FAULT;
        exc_sig_gen.mtval <= pc;
      end else if (pc_misaligned) begin
        instr <= 32'h0000_0013;  // nop for exception
        exc_sig_gen.exc_occur <= 1'b1;
        exc_sig_gen.cur_pc <= pc;
        exc_sig_gen.sync_exc_code <= `EXC_INSTRUCTION_ADDRESS_MISALIGNED;
        exc_sig_gen.mtval <= pc;
      end else if (tlb_flush_or_satp_update_i) begin
        exc_sig_gen <= `EXC_SIG_NULL;
        instr <= 32'h0000_0013;  // nop for tlb flush
      end else if (mmu_ack_i) begin
        instr <= mmu_data_i;
        exc_sig_gen <= `EXC_SIG_NULL;
      end
    end
  end

  always_comb begin
    case (if_state)
      IF_ACCESS: begin
        if_next_state = (mmu_ack_i || mmu_invalid_addr_i || mmu_fetch_pf_i || pc_misaligned || tlb_flush_or_satp_update_i) ? IF_DONE : IF_ACCESS;
      end
      IF_DONE: begin
        if_next_state = stall_i ? IF_DONE : IF_ACCESS;
      end
      default: begin
        if_next_state = IF_ACCESS;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pc <= 32'h8000_0000;
    end else if (stall_i) begin
      // do nothing
    end else begin
      pc <= pc_next;
    end
  end

  always_comb begin
    // signals to ID stage
    id_pc_o = pc;
    id_instr_o = instr;
    id_exc_sig_o = exc_sig_gen;

    // pc align
    pc_misaligned = (pc[1:0] != 2'b00);

    // mmu signals
    mmu_v_addr_o = pc;
    mmu_sel_o = 4'b1111;
    mmu_data_o = 32'h0000_0000;
    mmu_load_en_o = 1'b0;
    mmu_store_en_o = 1'b0;
    mmu_fetch_en_o = ~if_state & ~mmu_invalid_addr_i & ~pc_misaligned & ~tlb_flush_or_satp_update_i;
    mmu_flush_en_o = 1'b0;

    // if busy signal
    if_busy_o = ~if_state;

    // pc mux
    pc_next = pc_sel_i ? pc_i : pc + 4;
  end
endmodule