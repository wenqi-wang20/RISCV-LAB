`default_nettype none
`timescale 1ns / 1ps

`include "../headers/csr.vh"

module exc_unit(
  input wire clk_i,
  input wire rst_i,

  input wire         exc_occur_i,
  input wire  [31:0] cur_pc_i,
  input wire         interrupt_i,
  input wire  [30:0] exc_code_i,
  input wire  [31:0] mtval_i,
  output wire [31:0] next_pc_o,

  output wire [31:0] satp_o,
  input wire  [11:0] csr_raddr_i,
  output reg  [31:0] csr_rdata_o,
  input wire  [11:0] csr_waddr_i,
  input wire  [31:0] csr_wdata_i,
  input wire         csr_we_i,
  input wire  [1:0]  privilege_i,
  output wire        invalid_r_o,
  output wire        invalid_w_o
);

// ===== CSR declarations =====
// M-mode CSRs (NOT including mtime and mtimecmp)
csr_mstatus_t  mstatus_reg;
csr_mtvec_t    mtvec_reg;
csr_mip_t      mip_reg;
csr_mie_t      mie_reg;
csr_mscratch_t mscratch_reg;
csr_mepc_t     mepc_reg;
csr_mcause_t   mcause_reg;
// S-mode CSRs
csr_satp_t     satp_reg;

// ======== Decoding ========
wire [1:0] r_access;
wire [1:0] r_privilege;
wire [1:0] w_access;
wire [1:0] w_privilege;
assign r_access = csr_raddr_i[11:10];
assign r_privilege = csr_raddr_i[9:8];
assign w_access = csr_waddr_i[11:10];
assign w_privilege = csr_waddr_i[9:8];

// == Privilege and accessbility checking ==
always_comb begin
  invalid_r_o = ~r_access | (privilege_i < r_privilege);
  invalid_w_o = ~w_access | (privilege_i < w_privilege);
end

// ===== Special handling for satp =====
assign satp_o = satp_reg;

// ====== Read logic ======
always_comb begin
  case (csr_rddr_i)
    `CSR_MSATUS_ADDR: begin
      csr_rdata_o = mstatus_reg;
    end
    `CSR_MTVEC_ADDR: begin
      csr_rdata_o = mtvec_reg;
    end
    `CSR_MIP_ADDR: begin
      csr_rdata_o = mip_reg;
    end
    `CSR_MIE_ADDR: begin
      csr_rdata_o = mie_reg;
    end
    `CSR_MSCRATCH_ADDR: begin
      csr_rdata_o = mscratch_reg;
    end
    `CSR_MEPC_ADDR: begin
      csr_rdata_o = mepc_reg;
    end
    `CSR_MCAUSE_ADDR: begin
      csr_rdata_o = mcause_reg;
    end
    `CSR_SATP_ADDR: begin
      csr_rdata_o = satp_reg;
    end
    default: begin
      // TODO: Do we need to do anything here?
      csr_rdata_o = 32'h0;
    end
  endcase
end

// ====== Write logic ======
always_ff @(posedge clk_i) begin
  if (rst_i) begin
    mstatus_reg <= 0; // FIXME
    mtvec_reg <= 0;
    mip_reg <= 0;
    mie_reg <= 0;
    mscratch_reg <= 0;
    mepc_reg <= 0;
    mcause_reg <= 0
    satp_reg <= 0;
  end else if (exc_occur_i) begin
    // Handle exception.
    mepc_reg <= cur_pc_i;
    mcause_reg <= {interrupt_i, exc_code_i};
    mtval_reg <= mtval_i;
    
  end else if (csr_we_i & ~invalid_w_o) begin
    case (csr_waddr_i)
      `CSR_MSATUS_ADDR: begin
        // No Special Handling
        mstatus_reg <= csr_wdata_i;
      end
      `CSR_MTVEC_ADDR: begin
        // direct mode or vectored mode
        if (csr_wdata_i[1:0] < 2'b10) begin
          mtvec_reg.base <= csr_wdata_i[31:2];
          mtvec_reg.mode <= csr_wdata_i[1:0];
        end
      end
      `CSR_MIP_ADDR: begin
        mip_reg <= csr_wdata_i;
      end
      `CSR_MIE_ADDR: begin
        // MIE is WARL
        mie_reg <= csr_wdata_i;
      end
      `CSR_MSCRATCH_ADDR: begin
        // FIXME: No specification
        mscratch_reg <= csr_wdata_i;
      end
      `CSR_MEPC_ADDR: begin
        // IALIGN=32, mask the lower 2 bits
        mepc_reg <= {csr_wdata_i[31:2], 2'b00};
      end
      `CSR_MCAUSE_ADDR: begin
        mcause_reg.interrupt <= csr_wdata_i[31];
        if (csr_wdata_i[30:0] < 16) begin
          mcause_reg.exc_code <= csr_waddr_i[30:0];
        end
      end
      `CSR_SATP_ADDR: begin
        satp_reg <= csr_wdata_i;
      end
      default: ;
    endcase
  end
end

endmodule