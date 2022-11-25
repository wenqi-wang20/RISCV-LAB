module mem_stage(
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

  // signals from EXE stage
  input wire [31:0] mem_pc_i,
  input wire [31:0] mem_instr_i,
  input wire [31:0] mem_mem_wdata_i,
  input wire        mem_mem_en_i,
  input wire        mem_mem_wen_i,
  input wire [31:0] mem_alu_result_i,
  input wire [ 4:0] mem_rf_waddr_i,
  input wire        mem_rf_wen_i,

  // control signals
  input wire        stall_i,
  input wire        flush_i,

  // signals to WB(write back) stage
  output reg [31:0] wb_pc_o,
  output reg [31:0] wb_instr_o,
  output reg [31:0] wb_rf_wdata_o,
  output reg [ 4:0] wb_rf_waddr_o,
  output reg        wb_rf_wen_o,

  // signals to forward unit
  output reg [31:0] mem_alu_result_o,
  output reg [ 4:0] mem_rf_waddr_o,
  output reg        mem_rf_wen_o,
  output reg        mem_mem_en_o,
  output reg        mem_mem_wen_o,

  // signals to hazard detection unit
  output reg        mem_busy_o
);

  typedef enum logic {
    MEM_ACCESS = 1'b0,
    MEM_DONE = 1'b1
  } mem_state_t;

  // state signals
  mem_state_t mem_state, mem_next_state;

  // pipeline registers
  logic [31:0] pc;
  logic [31:0] instr;
  logic [31:0] mem_wdata;
  logic        mem_en;
  logic        mem_wen;
  logic [31:0] alu_result;
  logic [ 4:0] rf_waddr;
  logic        rf_wen;

  // internal signals
  logic [31:0] mem_rdata;
  logic [31:0] rf_wdata;
  logic        mem_busy;
  logic [ 2:0] funct3;
  logic [ 6:0] opcode;

  assign funct3 = instr[14:12];
  assign opcode = instr[ 6: 0];

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      mem_state <= MEM_ACCESS;
      mem_rdata <= 32'h0000_0000;
    end else begin
      mem_state <= mem_next_state;
      if (mmu_ack_i) begin
        case (funct3)
          3'b000: begin  //lb
            case (mmu_v_addr_o[1:0])
              2'b00: mem_rdata <= $signed(mmu_data_i[ 7: 0]);
              2'b01: mem_rdata <= $signed(mmu_data_i[15: 8]);
              2'b10: mem_rdata <= $signed(mmu_data_i[23:16]);
              2'b11: mem_rdata <= $signed(mmu_data_i[31:24]);
            endcase
          end
          3'b001: begin  //lh
            case (mmu_v_addr_o[1])
              1'b0: mem_rdata <= $signed(mmu_data_i[15: 0]);
              1'b1: mem_rdata <= $signed(mmu_data_i[31:16]);
            endcase
          end
          3'b010: begin  //lw
            mem_rdata <= mmu_data_i;
          end
          3'b100: begin  //lbu
            case (mmu_v_addr_o[1:0])
              2'b00: mem_rdata <= mmu_data_i[ 7: 0];
              2'b01: mem_rdata <= mmu_data_i[15: 8];
              2'b10: mem_rdata <= mmu_data_i[23:16];
              2'b11: mem_rdata <= mmu_data_i[31:24];
            endcase
          end
          3'b101: begin  //lhu
            case (mmu_v_addr_o[1])
              1'b0: mem_rdata <= mmu_data_i[15: 0];
              1'b1: mem_rdata <= mmu_data_i[31:16];
            endcase
          end
        endcase
      end
    end
  end

  always_comb begin
    if (mem_en) begin
      case (mem_state)
        MEM_ACCESS: begin
          mem_next_state = mmu_ack_i ? MEM_DONE : MEM_ACCESS;
        end
        MEM_DONE: begin
          mem_next_state = stall_i ? MEM_DONE : MEM_ACCESS;
        end
        default: begin
          mem_next_state = MEM_ACCESS;
        end
      endcase
    end else begin
      mem_next_state = MEM_ACCESS;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
      alu_result <= 32'h0;
      mem_wdata <= 32'h0;
      mem_en <= 1'b0;
      mem_wen <= 1'b0;
      rf_waddr <= 5'h0;
      rf_wen <= 1'b0;
    end else if (stall_i) begin
      // do nothing
    end else if (flush_i) begin
      pc <= 32'h0;
      instr <= 32'h0000_0013;  // nop
      alu_result <= 32'h0;
      mem_wdata <= 32'h0;
      mem_en <= 1'b0;
      mem_wen <= 1'b0;
      rf_waddr <= 5'h0;
      rf_wen <= 1'b0;
    end else begin
      pc <= mem_pc_i;
      instr <= mem_instr_i;
      alu_result <= mem_alu_result_i;
      mem_wdata <= mem_mem_wdata_i;
      mem_en <= mem_mem_en_i;
      mem_wen <= mem_mem_wen_i;
      rf_waddr <= mem_rf_waddr_i;
      rf_wen <= mem_rf_wen_i;
    end
  end

  always_comb begin
    // regfile write data
    if (mem_en && !mem_wen) begin
      rf_wdata = mem_rdata;
    end else begin
      case (opcode)
        7'b110_1111, 7'b110_0111: begin  // jal, jalr
          rf_wdata = pc + 4;
        end
        default: begin
          rf_wdata = alu_result;
        end
      endcase
    end

    // mem busy signal
    mem_busy = mem_en & ~mem_state;

    // signals to WB stage
    wb_pc_o = pc;
    wb_instr_o = instr;
    wb_rf_wdata_o = rf_wdata;
    wb_rf_waddr_o = rf_waddr;
    wb_rf_wen_o = rf_wen;

    // mmu signals
    mmu_load_en_o  = mem_en & ~mem_wen & ~mem_state;
    mmu_store_en_o = mem_en &  mem_wen & ~mem_state;
    mmu_fetch_en_o = 1'b0;
    mmu_flush_en_o = 1'b0;
    mmu_v_addr_o = alu_result;
    case (funct3)
      3'b000: begin  // lb, sb
        mmu_sel_o = 4'b0001 << mmu_v_addr_o[1:0];
      end
      3'b001: begin  // lh, sh
        mmu_sel_o = 4'b0011 << mmu_v_addr_o[1:0];
      end
      3'b010: begin  // lw, sw
        mmu_sel_o = 4'b1111;
      end
      3'b100: begin  // lbu
        mmu_sel_o = 4'b0001 << mmu_v_addr_o[1:0];
      end
      3'b101: begin  // lhu
        mmu_sel_o = 4'b0011 << mmu_v_addr_o[1:0];
      end
      default: begin
        mmu_sel_o = 4'b0000;
      end
    endcase
    mmu_data_o = mem_wdata;

    // signals to forward unit
    mem_alu_result_o = alu_result;
    mem_rf_waddr_o = rf_waddr;
    mem_rf_wen_o = rf_wen;
    mem_mem_en_o = mem_en;
    mem_mem_wen_o = mem_wen;

    // signals to hazard detection unit
    mem_busy_o = mem_busy;
  end

endmodule