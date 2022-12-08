`include "../../headers/exc.vh"
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
  input  wire        mmu_load_pf_i,
  input  wire        mmu_store_pf_i,
  input  wire        mmu_fetch_pf_i,
  input  wire        mmu_invalid_addr_i,

  // signals from EXE stage
  input wire [31:0] mem_pc_i,
  input wire [31:0] mem_instr_i,
  input wire [31:0] mem_mem_wdata_i,
  input wire        mem_mem_en_i,
  input wire        mem_mem_wen_i,
  input wire [31:0] mem_alu_result_i,
  input wire [ 4:0] mem_rf_waddr_i,
  input wire        mem_rf_wen_i,
  input wire [31:0] mem_csr_rs1_data_i,
  input wire [ 4:0] mem_csr_rs1_addr_i,
  input wire [`SYS_INSTR_T_WIDTH-1:0] mem_sys_instr_i,
  input wire [  `EXC_SIG_T_WIDTH-1:0] mem_exc_sig_i,

  // control signals
  input wire        stall_i,
  input wire        flush_i,

  // signals from CPU
  input wire [ 1:0]  privilege_i,

  // signals to WB(write back) stage
  output reg [31:0] wb_pc_o,
  output reg [31:0] wb_instr_o,
  output reg [31:0] wb_rf_wdata_o,
  output reg [ 4:0] wb_rf_waddr_o,
  output reg        wb_rf_wen_o,

  // signals to forward unit
  output reg [31:0] mem_rf_wdata_o,
  output reg [ 4:0] mem_rf_waddr_o,
  output reg        mem_rf_wen_o,
  output reg        mem_mem_en_o,
  output reg        mem_mem_wen_o,

  // signals to hazard detection unit
  output reg        mem_busy_o,
  output reg        mem_tlb_flush_or_satp_update_o,

  // signals from/to exception unit
  input wire [31:0] csr_rdata_i,
  input wire        csr_invalid_r_i,
  input wire        csr_invalid_w_i,
  output reg [11:0] csr_raddr_o,
  output reg [11:0] csr_waddr_o,
  output reg [31:0] csr_wdata_o,
  output reg        csr_wen_o,

  // signals to exception handler
  output reg [`EXC_SIG_T_WIDTH-1:0] exc_sig_o
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
  logic [31:0] csr_rs1_data;
  logic [ 4:0] csr_rs1_addr;
  sys_instr_t  sys_instr;
  exc_sig_t    exc_sig;

  // internal registers
  logic        mem_enable_exact;    // enable memory access (mem_en & ~exc_sig_bf_mem_gen.exc_occur)
  logic [31:0] mem_rdata;
  exc_sig_t    exc_sig_mem_gen;     // exception occur when accessing memory
  exc_sig_t    exc_sig_sys_gen;     // exception occur when execute SYSTEM instruction
  exc_sig_t    exc_sig_csr_gen;     // exception occur when accessing CSR
  exc_sig_t    exc_sig_gen;         // exception occur


  // internal signals
  logic [31:0] rf_wdata;
  logic        mem_busy;
  logic [ 2:0] funct3;
  logic [ 6:0] opcode;
  logic        addr_misaligned;
  logic [11:0] csr_addr;
  logic        csr_wen;
  logic        csr_rf_wdata_sel;
  logic        tlb_flush_en;
  logic        satp_update_en;

  assign funct3   = instr[14:12];
  assign opcode   = instr[ 6: 0];
  assign csr_addr = instr[31:20];

  /* ========== BEGIN: Memory Access FSM ========== */
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      mem_state <= MEM_ACCESS;
      mem_rdata <= 32'h0000_0000;
      exc_sig_mem_gen <= `EXC_SIG_NULL;
    end else begin
      mem_state <= mem_next_state;
      if (mem_enable_exact) begin
        if (addr_misaligned) begin
          mem_rdata <= 32'h0000_0000;
          exc_sig_mem_gen.exc_occur <= 1'b1;
          exc_sig_mem_gen.cur_pc <= pc;
          exc_sig_mem_gen.mtval <= alu_result;
          if (mem_wen) begin
            exc_sig_mem_gen.sync_exc_code  <= `EXC_STORE_AMO_ADDRESS_MISALIGNED;
          end else begin
            exc_sig_mem_gen.sync_exc_code <= `EXC_LOAD_ADDRESS_MISALIGNED;
          end
        end else if (mmu_load_pf_i) begin
          mem_rdata <= 32'h0000_0000;
          exc_sig_mem_gen.exc_occur <= 1'b1;
          exc_sig_mem_gen.cur_pc <= pc;
          exc_sig_mem_gen.sync_exc_code <= `EXC_LOAD_PAGE_FAULT;
          exc_sig_mem_gen.mtval <= alu_result;
        end else if (mmu_store_pf_i) begin
          mem_rdata <= 32'h0000_0000;
          exc_sig_mem_gen.exc_occur <= 1'b1;
          exc_sig_mem_gen.cur_pc <= pc;
          exc_sig_mem_gen.sync_exc_code <= `EXC_STORE_AMO_PAGE_FAULT;
          exc_sig_mem_gen.mtval <= alu_result;
        end else if (mmu_invalid_addr_i) begin
          mem_rdata <= 32'h0000_0000;
          exc_sig_mem_gen.exc_occur <= 1'b1;
          exc_sig_mem_gen.cur_pc <= pc;
          exc_sig_mem_gen.mtval <= alu_result;
          if (mem_wen) begin
            exc_sig_mem_gen.sync_exc_code <= `EXC_STORE_AMO_ACCESS_FAULT;
          end else begin
            exc_sig_mem_gen.sync_exc_code <= `EXC_LOAD_ACCESS_FAULT;
          end
        end else if (mmu_ack_i) begin
          exc_sig_mem_gen <= `EXC_SIG_NULL;
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
  end

  always_comb begin
    if (mem_enable_exact) begin
      case (mem_state)
        MEM_ACCESS: begin
          mem_next_state = (mmu_ack_i || addr_misaligned || mmu_invalid_addr_i || mmu_load_pf_i || mmu_store_pf_i) ? MEM_DONE : MEM_ACCESS;
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

  /* ========== END: Memory Access FSM ========== */

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
      csr_rs1_data <= 32'b0;
      csr_rs1_addr <= 5'b0;
      sys_instr <= SYS_INSTR_NOP;
      exc_sig <= `EXC_SIG_NULL;
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
      csr_rs1_data <= 32'b0;
      csr_rs1_addr <= 5'b0;
      sys_instr <= SYS_INSTR_NOP;
      exc_sig <= `EXC_SIG_NULL;
    end else begin
      pc <= mem_pc_i;
      instr <= mem_instr_i;
      alu_result <= mem_alu_result_i;
      mem_wdata <= mem_mem_wdata_i;
      mem_en <= mem_mem_en_i;
      mem_wen <= mem_mem_wen_i;
      rf_waddr <= mem_rf_waddr_i;
      rf_wen <= mem_rf_wen_i;
      csr_rs1_data <= mem_csr_rs1_data_i;
      csr_rs1_addr <= mem_csr_rs1_addr_i;
      sys_instr <= sys_instr_t'(mem_sys_instr_i);
      exc_sig <= mem_exc_sig_i;
    end
  end

  always_comb begin
    mem_enable_exact = mem_en & ~exc_sig;

    // ECALL, EBREAK, MRET, SRET, URET, SFENCE.VMA
    tlb_flush_en = (sys_instr == SYS_INSTR_SFENCE_VMA) && (!exc_sig.exc_occur);
    exc_sig_sys_gen = `EXC_SIG_NULL;
    if (!exc_sig.exc_occur) begin
      case (sys_instr)
        SYS_INSTR_ECALL: begin
          exc_sig_sys_gen.exc_occur = 1'b1;
          exc_sig_sys_gen.exc_ret = 1'b0;
          exc_sig_sys_gen.cur_pc = pc;
          exc_sig_sys_gen.mtval = 32'h0;
          case (privilege_i)
            `PRIVILEGE_M: begin
              exc_sig_sys_gen.sync_exc_code = `EXC_ECALL_FROM_M_MODE;
            end
            `PRIVILEGE_S: begin
              exc_sig_sys_gen.sync_exc_code = `EXC_ECALL_FROM_S_MODE;
            end
            `PRIVILEGE_U: begin
              exc_sig_sys_gen.sync_exc_code = `EXC_ECALL_FROM_U_MODE;
            end
            default: begin
              exc_sig_sys_gen.sync_exc_code = `EXC_ECALL_FROM_M_MODE;
            end
          endcase
        end
        SYS_INSTR_EBREAK: begin
          exc_sig_sys_gen.exc_occur = 1'b1;
          exc_sig_sys_gen.exc_ret = 1'b0;
          exc_sig_sys_gen.cur_pc = pc;
          exc_sig_sys_gen.sync_exc_code = `EXC_BREAKPOINT;
          exc_sig_sys_gen.mtval = 32'h0;
        end
        SYS_INSTR_MRET, SYS_INSTR_SRET, SYS_INSTR_URET: begin
          exc_sig_sys_gen.exc_occur = 1'b0;
          exc_sig_sys_gen.exc_ret = 1'b1;
          exc_sig_sys_gen.cur_pc = pc;
          exc_sig_sys_gen.sync_exc_code = 31'h0;
          exc_sig_sys_gen.mtval = 32'h0;
        end
        default: begin
          exc_sig_sys_gen = exc_sig;
        end
      endcase
    end else begin
      exc_sig_sys_gen = exc_sig;
    end

    // CSR read/write
    csr_raddr_o = csr_addr;
    csr_waddr_o = csr_addr;
    case (sys_instr)
      SYS_INSTR_CSRRW: begin
        csr_wen = (!exc_sig.exc_occur) && (!stall_i);
        satp_update_en = csr_wen && (csr_addr == `CSR_SATP_ADDR);
        csr_rf_wdata_sel = 1'b1;
        csr_wen_o = csr_wen;
        csr_wdata_o = csr_rs1_data;
      end
      SYS_INSTR_CSRRS: begin
        csr_wen = (!exc_sig.exc_occur) && (csr_rs1_addr != 5'b0_0000) && (!stall_i);
        satp_update_en = csr_wen && (csr_addr == `CSR_SATP_ADDR);
        csr_rf_wdata_sel = 1'b1;
        csr_wen_o = csr_wen;
        csr_wdata_o = csr_rdata_i | csr_rs1_data;
      end
      SYS_INSTR_CSRRC: begin
        csr_wen = (!exc_sig.exc_occur) && (csr_rs1_addr != 5'b0_0000) && (!stall_i);
        satp_update_en = csr_wen && (csr_addr == `CSR_SATP_ADDR);
        csr_rf_wdata_sel = 1'b1;
        csr_wen_o = csr_wen;
        csr_wdata_o = csr_rdata_i & ~csr_rs1_data;
      end
      SYS_INSTR_CSRRWI: begin
        csr_wen = (!exc_sig.exc_occur) && (!stall_i);
        satp_update_en = csr_wen && (csr_addr == `CSR_SATP_ADDR);
        csr_rf_wdata_sel = 1'b1;
        csr_wen_o = csr_wen;
        csr_wdata_o = $unsigned(csr_rs1_addr);
      end
      SYS_INSTR_CSRRSI: begin
        csr_wen = (!exc_sig.exc_occur) && (csr_rs1_addr != 5'b0_0000) && (!stall_i);
        satp_update_en = csr_wen && (csr_addr == `CSR_SATP_ADDR);
        csr_rf_wdata_sel = 1'b1;
        csr_wen_o = csr_wen;
        csr_wdata_o = csr_rdata_i | {27'b0, csr_rs1_addr};
      end
      SYS_INSTR_CSRRCI: begin
        csr_wen = (!exc_sig.exc_occur) && (csr_rs1_addr != 5'b0_0000) && (!stall_i);
        satp_update_en = csr_wen && (csr_addr == `CSR_SATP_ADDR);
        csr_rf_wdata_sel = 1'b1;
        csr_wen_o = csr_wen;
        csr_wdata_o = csr_rdata_i & ~{27'b0, csr_rs1_addr};
      end
      default: begin
        csr_wen = 1'b0;
        satp_update_en = 1'b0;
        csr_rf_wdata_sel = 1'b0;
        csr_wen_o = 1'b0;
        csr_wdata_o = 32'h0000_0000;
      end
    endcase
    exc_sig_csr_gen = `EXC_SIG_NULL;
    if (csr_invalid_r_i || (csr_invalid_w_i && csr_wen_o)) begin
      exc_sig_csr_gen.exc_occur = 1'b1;
      exc_sig_csr_gen.exc_ret = 1'b0;
      exc_sig_csr_gen.cur_pc = pc;
      exc_sig_csr_gen.sync_exc_code = `EXC_ILLEGAL_INSTRUCTION;
      exc_sig_csr_gen.mtval = 32'h0;
    end else begin
      exc_sig_csr_gen = exc_sig;
    end

    exc_sig_gen = exc_sig.exc_occur ? exc_sig :
                  (mem_enable_exact && exc_sig_mem_gen.exc_occur) ? exc_sig_mem_gen :
                  (exc_sig_sys_gen.exc_occur || exc_sig_sys_gen.exc_ret) ? exc_sig_sys_gen :
                  exc_sig_csr_gen.exc_occur ? exc_sig_csr_gen : `EXC_SIG_NULL;

    exc_sig_o = exc_sig_gen;

    // regfile write data
    if (mem_en && !mem_wen) begin
      rf_wdata = mem_rdata;
    end else if (csr_rf_wdata_sel) begin
      rf_wdata = csr_rdata_i;
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
    mem_busy = mem_enable_exact & ~mem_state;

    // signals to WB stage
    wb_pc_o = pc;
    wb_instr_o = instr;
    wb_rf_wdata_o = rf_wdata;
    wb_rf_waddr_o = rf_waddr;
    wb_rf_wen_o = rf_wen;

    // mmu signals
    mmu_v_addr_o = alu_result;
    case (funct3)
      3'b000: begin  // lb, sb
        mmu_sel_o = 4'b0001 << mmu_v_addr_o[1:0];
        addr_misaligned = 1'b0;
      end
      3'b001: begin  // lh, sh
        mmu_sel_o = 4'b0011 << mmu_v_addr_o[1:0];
        addr_misaligned = mmu_v_addr_o[0];
      end
      3'b010: begin  // lw, sw
        mmu_sel_o = 4'b1111;
        addr_misaligned = (mmu_v_addr_o[1:0] != 2'b00) ? 1'b1 : 1'b0;
      end
      3'b100: begin  // lbu
        mmu_sel_o = 4'b0001 << mmu_v_addr_o[1:0];
        addr_misaligned = 1'b0;
      end
      3'b101: begin  // lhu
        mmu_sel_o = 4'b0011 << mmu_v_addr_o[1:0];
        addr_misaligned = mmu_v_addr_o[0];
      end
      default: begin
        mmu_sel_o = 4'b0000;
        addr_misaligned = 1'b0;
      end
    endcase
    mmu_load_en_o  = mem_en & ~mem_wen & ~mem_state & ~addr_misaligned;
    mmu_store_en_o = mem_en &  mem_wen & ~mem_state & ~addr_misaligned;
    mmu_fetch_en_o = 1'b0;
    mmu_flush_en_o = tlb_flush_en;
    mmu_data_o = mem_wdata;

    // signals to forward unit
    mem_rf_wdata_o = rf_wdata;
    mem_rf_waddr_o = rf_waddr;
    mem_rf_wen_o = rf_wen;
    mem_mem_en_o = mem_en;
    mem_mem_wen_o = mem_wen;

    // signals to hazard detection unit
    mem_busy_o = mem_busy;
    mem_tlb_flush_or_satp_update_o = tlb_flush_en | satp_update_en;
  end

endmodule