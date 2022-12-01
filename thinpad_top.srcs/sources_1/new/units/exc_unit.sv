`default_nettype none
`timescale 1ns / 1ps

`include "../headers/csr.vh"
`include "../headers/privilege.vh"
`include "../headers/exc.vh"

module exc_unit(
  input wire clk_i,
  input wire rst_i,

  input wire   exc_en_i,
  input wire   exc_ret_i,
  output logic interrupt_occur_o,
  output logic priv_privilege_o,
 
  input wire   [31:0] cur_pc_i,
  input wire   [30:0] sync_exc_code_i,
  input wire   [31:0] mtval_i,
  output logic [31:0] next_pc_o,

  input wire   [ 1:0] privilege_i,
  output reg   [ 1:0] nxt_privilege_o,
 
  output wire  [31:0] satp_o,
  input wire          mtip_set_en_i,
  input wire          mtip_clear_en_i,
 
  input wire   [11:0] csr_raddr_i,
  output reg   [31:0] csr_rdata_o,
  input wire   [11:0] csr_waddr_i,
  input wire   [31:0] csr_wdata_i,
  input wire          csr_we_i,
  output logic        invalid_r_o,
  output logic        invalid_w_o
);

// ===== CSR declarations =====
// M-mode CSRs (NOT including mtime and mtimecmp)
csr_mstatus_t  mstatus_reg;
csr_mtvec_t    mtvec_reg;
csr_mtval_t    mtval_reg;
csr_mip_t      mip_reg;
csr_mie_t      mie_reg;
csr_mscratch_t mscratch_reg;
csr_mepc_t     mepc_reg;
csr_mcause_t   mcause_reg;
csr_mhartid_t  mhartid_reg;
csr_medeleg_t  medeleg_reg;
csr_mideleg_t  mideleg_reg;

// S-mode CSRs
csr_sstatus_t  sstatus_reg;
csr_sepc_t     sepc_reg;
csr_scause_t   scause_reg;
csr_stval_t    stval_reg;
csr_stvec_t    stvec_reg;
csr_sscratch_t sscratch_reg;
csr_sie_t      sie_reg;
csr_sip_t      sip_reg;
csr_satp_t     satp_reg;

// The sie and sip are considered hard-wired subset of mie and mip
always_comb begin
  sie_reg = 0;
  sie_reg.seie = mie_reg.seie;
  sie_reg.ueie = mie_reg.ueie;
  sie_reg.stie = mie_reg.stie;
  sie_reg.utie = mie_reg.utie;
  sie_reg.ssie = mie_reg.ssie;
  sie_reg.usie = mie_reg.usie;
end

always_comb begin
  sip_reg = 0;
  sip_reg.seip = mip_reg.seip;
  sip_reg.ueip = mip_reg.ueip;
  sip_reg.stip = mip_reg.stip;
  sip_reg.utip = mip_reg.utip;
  sip_reg.ssip = mip_reg.ssip;
  sip_reg.usip = mip_reg.usip;
end

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

// ===== Hard-wired read registers =====
// Expose satp for mem access
assign satp_o = satp_reg;
// Output the privilege level prior to the exception
assign priv_privilege_o = mstatus_reg.mpp;

// ====== Read logic ======
always_comb begin
  case (csr_raddr_i)
    `CSR_MSTATUS_ADDR: csr_rdata_o = mstatus_reg;
    `CSR_MTVEC_ADDR: csr_rdata_o = mtvec_reg;
    `CSR_MIP_ADDR: csr_rdata_o = mip_reg;
    `CSR_MIE_ADDR: csr_rdata_o = mie_reg;
    `CSR_MSCRATCH_ADDR: csr_rdata_o = mscratch_reg;
    `CSR_MEPC_ADDR: csr_rdata_o = mepc_reg;
    `CSR_MCAUSE_ADDR: csr_rdata_o = mcause_reg;
    `CSR_MHARTID_ADDR: csr_rdata_o = mhartid_reg;
    `CSR_MEDELEG_ADDR: csr_rdata_o = medeleg_reg;
    `CSR_MIDELEG_ADDR: csr_rdata_o = mideleg_reg;
    `CSR_MTVAL_ADDR: csr_rdata_o = mtval_reg;
    `CSR_SSTATUS_ADDR: csr_rdata_o = sstatus_reg;
    `CSR_SEPC_ADDR: csr_rdata_o = sepc_reg;
    `CSR_SCAUSE_ADDR: csr_rdata_o = scause_reg;
    `CSR_STVAL_ADDR: csr_rdata_o = stval_reg;
    `CSR_STVEC_ADDR: csr_rdata_o = stvec_reg;
    `CSR_SSCRATCH_ADDR: csr_rdata_o = sscratch_reg;
    `CSR_SIE_ADDR: csr_rdata_o = sie_reg;
    `CSR_SIP_ADDR: csr_rdata_o = sip_reg;
    `CSR_SATP_ADDR: csr_rdata_o = satp_reg;
    default: csr_rdata_o = 32'h0; // FIXME: Do we need to do anything here?
  endcase
end

wire mei_occur, mti_occur, msi_occur,
     sei_occur, sti_occur, ssi_occur,
     uei_occur, uti_occur, usi_occur;
assign mei_occur = mie_reg.meie & mip_reg.meip;
assign mti_occur = mie_reg.mtie & mip_reg.mtip;
assign msi_occur = mie_reg.msie & mip_reg.msip;
assign sei_occur = mie_reg.seie & mip_reg.seip;
assign sti_occur = mie_reg.stie & mip_reg.stip;
assign ssi_occur = mie_reg.ssie & mip_reg.ssip;
assign uei_occur = mie_reg.ueie & mip_reg.ueip;
assign uti_occur = mie_reg.utie & mip_reg.utip;
assign usi_occur = mie_reg.usie & mip_reg.usip;

wire m_has_interrupt, s_has_interrupt, u_has_interrupt;
assign m_has_interrupt = mei_occur | mti_occur | msi_occur;
assign s_has_interrupt = sei_occur | sti_occur | ssi_occur;
assign u_has_interrupt = uei_occur | uti_occur | usi_occur;

logic [1:0] interrupt_level;

always_comb begin
  case (privilege_i)
    `PRIVILEGE_M: begin
      interrupt_occur_o = m_has_interrupt & mstatus_reg.mie;
    end
    `PRIVILEGE_S: begin
      interrupt_occur_o = m_has_interrupt |
                         (s_has_interrupt & mstatus_reg.sie);
    end
    `PRIVILEGE_U: begin
      interrupt_occur_o = m_has_interrupt | s_has_interrupt |
                         (u_has_interrupt & mstatus_reg.uie);
    end
    default: begin
      interrupt_occur_o = 1'b0;
    end
  endcase

  if (m_has_interrupt)
    interrupt_level = `PRIVILEGE_M;
  else if (s_has_interrupt)
    interrupt_level = `PRIVILEGE_S;
  else
    interrupt_level = `PRIVILEGE_U;
end

// Cause of the exception
logic [30:0] exc_code;

always_comb begin
  if (interrupt_occur_o) begin
    // Priority: MEI, MSI, MTI, SEI, SSI, STI, UEI, USI, UTI
    if (mei_occur)
      exc_code = `EXC_MACHINE_EXTERNAL_INTERRUPT;
    else if (msi_occur)
      exc_code = `EXC_MACHINE_SOFTWARE_INTERRUPT;
    else if (mti_occur)
      exc_code = `EXC_MACHINE_TIMER_INTERRUPT;
    else if (sei_occur)
      exc_code = `EXC_SUPERVISOR_EXTERNAL_INTERRUPT;
    else if (ssi_occur)
      exc_code = `EXC_SUPERVISOR_SOFTWARE_INTERRUPT;
    else if (sti_occur)
      exc_code = `EXC_SUPERVISOR_TIMER_INTERRUPT;
    else if (uei_occur)
      exc_code = `EXC_USER_EXTERNAL_INTERRUPT;
    else if (usi_occur)
      exc_code = `EXC_USER_SOFTWARE_INTERRUPT;
    else if (uti_occur)
      exc_code = `EXC_USER_TIMER_INTERRUPT;
    else
      exc_code = 0;
  end else begin
    exc_code = sync_exc_code_i;
  end
end

wire deleg_interrupt;
wire deleg_sync_exc;
assign deleg_interrupt = mideleg_reg[exc_code];
assign deleg_sync_exc = medeleg_reg[exc_code];

// ====== Write logic ======
always_ff @(posedge clk_i) begin
  if (rst_i) begin
    mstatus_reg <= 0;
    mtvec_reg <= 0;
    mip_reg <= 0;
    mie_reg <= 0;
    mscratch_reg <= 0;
    mepc_reg <= 0;
    mcause_reg <= 0;
    mtval_reg <= 0;
    mhartid_reg <= 0;
    medeleg_reg <= 0;
    mideleg_reg <= 0;

    sstatus_reg <= 0;
    sepc_reg <= 0;
    stvec_reg <= 0;
    scause_reg <= 0;
    stval_reg <= 0;
    stvec_reg <= 0;
    sscratch_reg <= 0;
    satp_reg <= 0;
  end else if (exc_en_i) begin
    // TODO: Delegation
    // Set cause
    mcause_reg <= {interrupt_occur_o, exc_code};
    // Set mtval
    mtval_reg <= mtval_i;

    // Save current state
    mstatus_reg.mpp <= privilege_i;
    mstatus_reg.mpie <= mstatus_reg.mie;
    mepc_reg <= {cur_pc_i[31:2], 2'b00};

    // Disable interrupts
    mstatus_reg.mie <= 1'b0;

    // Output exception handler pc
    next_pc_o <= mtvec_reg.mode == 1'b0 ?
                 mtvec_reg.base : /* direct */
                 mtvec_reg.base + (exc_code << 2); /* vectored */

  end else if (exc_ret_i) begin
    // Return from trap (privilege spec 3.1.6.1)
    mstatus_reg.mie <= mstatus_reg.mpie;
    mstatus_reg.mpie <= 1'b1;
    mstatus_reg.mpp <= `PRIVILEGE_U;
    nxt_privilege_o <= mstatus_reg.mpp;
    
  end else if (mtip_set_en_i | mtip_clear_en_i) begin
    mip_reg.mtip <= mtip_set_en_i;

  end else if (csr_we_i & ~invalid_w_o) begin
    case (csr_waddr_i)
      `CSR_MSTATUS_ADDR: begin
        mstatus_reg <= csr_wdata_i;
        // xPP: WARL, only holding levels lower than x
        if (csr_wdata_i[11:10] >= privilege_i) begin
          mstatus_reg.mpp <= mstatus_reg.mpp;
        end
      end
      `CSR_MTVEC_ADDR: begin
        // direct mode or vectored mode
        if (csr_wdata_i[1:0] < 2'b10) begin
          mtvec_reg <= csr_wdata_i;
        end
      end
      `CSR_MIP_ADDR: begin
        mip_reg <= csr_wdata_i;
        // The xyIP is writable for only level > x
        if (privilege_i <= `PRIVILEGE_M) begin
          mip_reg.meip <= mip_reg.meip;
          mip_reg.msip <= mip_reg.msip;
          mip_reg.mtip <= mip_reg.mtip;
        end
        if (privilege_i <= `PRIVILEGE_S) begin
          mip_reg.seip <= mip_reg.seip;
          mip_reg.ssip <= mip_reg.ssip;
          mip_reg.stip <= mip_reg.stip;
        end
        if (privilege_i <= `PRIVILEGE_U) begin
          mip_reg.ueip <= mip_reg.ueip;
          mip_reg.usip <= mip_reg.usip;
          mip_reg.utip <= mip_reg.utip;
        end
      end
      `CSR_MIE_ADDR: begin
        mie_reg <= csr_wdata_i;
      end
      `CSR_MSCRATCH_ADDR: begin
        mscratch_reg <= csr_wdata_i;
      end
      `CSR_MEPC_ADDR: begin
        // IALIGN=32, mask the lower 2 bits
        mepc_reg <= {csr_wdata_i[31:2], 2'b00};
      end
      `CSR_MCAUSE_ADDR: begin
        mcause_reg.interrupt <= csr_wdata_i[31];
        if (csr_wdata_i[30:0] < 16) begin
          mcause_reg.exc_code <= csr_wdata_i[30:0];
        end
      end
      `CSR_SATP_ADDR: begin
        satp_reg <= csr_wdata_i;
      end
      `CSR_MTVAL_ADDR: begin
        mtval_reg <= csr_wdata_i;
      end
      `CSR_MHARTID_ADDR: begin
        mhartid_reg <= csr_wdata_i;
      end
      `CSR_MEDELEG_ADDR: begin
        medeleg_reg <= csr_wdata_i;
      end
      `CSR_MIDELEG_ADDR: begin
        mideleg_reg <= csr_wdata_i;
      end
      // TODO: Other CSRs
      default: ;
    endcase
  end
end

endmodule