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

  // stall signals and flush signals
  input wire        stall_i,
  input wire        flush_i,
  input wire        mem_access_en_i,
  input wire        pc_sel_i,
  input wire [31:0] pc_i,

  // signals to ID stage
  output reg [31:0] id_pc_o,
  output reg [31:0] id_instr_o,

  // signals to hazard handler
  output reg if_busy_o
);
  typedef enum logic {
    IF_ACCESS = 1'b0,
    IF_DONE = 1'b1
  } if_state_t;

  if_state_t if_state, if_next_state;

  // internal signals
  logic [31:0] pc;
  logic [31:0] pc_next;
  logic [31:0] instr;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin 
      if_state <= IF_ACCESS;
      instr <= 32'h0000_0000;
    end else begin
      if_state <= if_next_state;
      if (mmu_ack_i) begin
        instr <= mmu_data_i;
      end
    end
  end

  always_comb begin
    case (if_state)
      IF_ACCESS: begin
        if_next_state = (!mem_access_en_i) ? IF_ACCESS : (mmu_ack_i ? IF_DONE : IF_ACCESS);
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

    // mmu signals
    mmu_v_addr_o = pc;
    mmu_sel_o = 4'b1111;
    mmu_data_o = 32'h0000_0000;
    mmu_load_en_o = 1'b0;
    mmu_store_en_o = 1'b0;
    mmu_fetch_en_o = mem_access_en_i & ~if_state;
    mmu_flush_en_o = 1'b0;

    // if busy signal
    if_busy_o = ~if_state;

    // pc mux
    pc_next = pc_sel_i ? pc_i : pc + 4;
  end
endmodule