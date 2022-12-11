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
 
  input wire   [31:0] cur_pc_i,
  input wire   [30:0] sync_exc_code_i,
  input wire   [31:0] mtval_i,
  output logic [31:0] next_pc_o,

  input wire   [ 1:0] privilege_i,
  output logic [ 1:0] nxt_privilege_o,
 
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

csr_time_t     time_reg;

// The sstatus, sie and sip are considered hard-wired subset of
// mstatus, mie and mip, respectively
always_comb begin
  sstatus_reg = 0;
  sstatus_reg.sd = mstatus_reg.sd;
  sstatus_reg.mxr = mstatus_reg.mxr;
  sstatus_reg.sum = mstatus_reg.sum;
  sstatus_reg.xs = mstatus_reg.xs;
  sstatus_reg.fs = mstatus_reg.fs;
  sstatus_reg.spp = mstatus_reg.spp;
  sstatus_reg.spie = mstatus_reg.spie;
  sstatus_reg.upie = mstatus_reg.upie;
  sstatus_reg.sie = mstatus_reg.sie;
  sstatus_reg.uie = mstatus_reg.uie;
end

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
wire [1:0] r_privilege;
wire [1:0] w_access;
wire [1:0] w_privilege;
assign r_privilege = csr_raddr_i[9:8];
assign w_access = csr_waddr_i[11:10];
assign w_privilege = csr_waddr_i[9:8];

// == Privilege and accessbility checking ==
always_comb begin
  invalid_r_o = (privilege_i < r_privilege);
  invalid_w_o = (w_access == 2'b11) | (privilege_i < w_privilege);
end

// ===== Hard-wired read registers =====
// Expose satp for mem access
assign satp_o = satp_reg;

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
    `CSR_TIME_ADDR: csr_rdata_o = time_reg[31:0];
    `CSR_TIMEH_ADDR: csr_rdata_o = time_reg[63:32];
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
logic       interrupt_occur;
assign interrupt_occur_o = interrupt_occur;

always_comb begin
  case (privilege_i)
    `PRIVILEGE_M: begin
      interrupt_occur = m_has_interrupt & mstatus_reg.mie;
    end
    `PRIVILEGE_S: begin
      interrupt_occur = m_has_interrupt |
                        (s_has_interrupt & mstatus_reg.sie);
    end
    `PRIVILEGE_U: begin
      interrupt_occur = m_has_interrupt | s_has_interrupt |
                        (u_has_interrupt & mstatus_reg.uie);
    end
    default: begin
      interrupt_occur = 1'b0;
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

logic deleg_exc;
always_comb begin
  if (privilege_i == `PRIVILEGE_M) begin
    // Traps never transition from a more-privileged mode to a
    // less-privileged mode
    deleg_exc = 1'b0;
  end else if (interrupt_occur) begin
    deleg_exc = mideleg_reg[exc_code];
  end else begin
    deleg_exc = medeleg_reg[exc_code];
  end
end

always_comb begin
  next_pc_o = 0;
  nxt_privilege_o = 0;
  if (exc_en_i) begin
    if (!deleg_exc) begin
      next_pc_o = mtvec_reg.mode == 2'b00 ?
                  {mtvec_reg.base, 2'b00} : /* direct */
                  {mtvec_reg.base, 2'b00} + (exc_code << 2); /* vectored */
      nxt_privilege_o = `PRIVILEGE_M;
    end else begin
      next_pc_o = stvec_reg.mode == 2'b00 ?
                  {stvec_reg.base, 2'b00} : /* direct */
                  {stvec_reg.base, 2'b00} + (exc_code << 2); /* vectored */
      nxt_privilege_o = `PRIVILEGE_S;
    end
  end else if (exc_ret_i) begin
    if (privilege_i == `PRIVILEGE_M) begin
      nxt_privilege_o = mstatus_reg.mpp;
      next_pc_o = mepc_reg;
    end else if (privilege_i == `PRIVILEGE_S) begin
      nxt_privilege_o = mstatus_reg.spp;
      next_pc_o = sepc_reg;
    end
  end
end

always_ff @(posedge clk_i) begin
  if (rst_i) begin
    time_reg <= 0;
  end else begin
    time_reg <= time_reg + 1;
  end
end

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

    sepc_reg <= 0;
    stvec_reg <= 0;
    scause_reg <= 0;
    stval_reg <= 0;
    stvec_reg <= 0;
    sscratch_reg <= 0;
    satp_reg <= 0;
  end else if (exc_en_i) begin
    if (!deleg_exc) begin
      // Set cause
      mcause_reg <= {interrupt_occur, exc_code};
      // Set mtval
      mtval_reg <= mtval_i;

      // Save current state
      mstatus_reg.mpp <= privilege_i;
      mstatus_reg.mpie <= mstatus_reg.mie;
      mepc_reg <= {cur_pc_i[31:2], 2'b00};

      // Disable interrupts
      mstatus_reg.mie <= 1'b0;
    end else begin
      // Delegate to S-mode
      scause_reg <= {interrupt_occur, exc_code};
      stval_reg <= mtval_i;

      mstatus_reg.spp <= privilege_i;
      mstatus_reg.spie <= mstatus_reg.sie;
      sepc_reg <= {cur_pc_i[31:2], 2'b00};

      mstatus_reg.sie <= 1'b0;
    end

  end else if (exc_ret_i) begin
    // Return from trap (privilege spec 3.1.6.1)
    if (privilege_i == `PRIVILEGE_M) begin
      // mret
      mstatus_reg.mie <= mstatus_reg.mpie;
      mstatus_reg.mpie <= 1'b1;
      mstatus_reg.mpp <= `PRIVILEGE_U;
    end else if (privilege_i == `PRIVILEGE_S) begin
      // sret
      mstatus_reg.sie <= mstatus_reg.spie;
      mstatus_reg.spie <= 1'b1;
      mstatus_reg.spp <= `PRIVILEGE_U;
    end else begin
      // We do not support uret...
    end
    
  end else if (csr_we_i & ~invalid_w_o) begin
    case (csr_waddr_i)
      `CSR_MSTATUS_ADDR: begin
        mstatus_reg <= csr_wdata_i;
      end
      `CSR_MTVEC_ADDR: begin
        // direct mode or vectored mode
        if (csr_wdata_i[1:0] < 2'b10) begin
          mtvec_reg <= csr_wdata_i;
        end
      end
      `CSR_MIP_ADDR: begin
        // Only MTIP and STIP is implemented. MTIP is read-only to software,
        // and only privilege level > S can write SxIP
        if (privilege_i == `PRIVILEGE_M) begin
          mip_reg.stip <= csr_wdata_i[5];
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
      `CSR_MTVAL_ADDR: begin
        mtval_reg <= csr_wdata_i;
      end
      `CSR_MHARTID_ADDR: begin
        mhartid_reg <= csr_wdata_i;
      end
      `CSR_MEDELEG_ADDR: begin
        medeleg_reg <= csr_wdata_i;
        // medeleg[11] is hardwired to 0
        medeleg_reg[11] <= 1'b0;
      end
      `CSR_MIDELEG_ADDR: begin
        mideleg_reg <= csr_wdata_i;
      end
      `CSR_SSTATUS_ADDR: begin
        mstatus_reg.spp <= csr_wdata_i[8];
        mstatus_reg.spie <= csr_wdata_i[5];
        mstatus_reg.upie <= csr_wdata_i[4];
        mstatus_reg.sie <= csr_wdata_i[1];
        mstatus_reg.uie <= csr_wdata_i[0];
      end
      `CSR_SEPC_ADDR: begin
        sepc_reg <= {csr_wdata_i[31:2], 2'b00};
      end
      `CSR_SCAUSE_ADDR: begin
        scause_reg.interrupt <= csr_wdata_i[31];
        if (csr_wdata_i[30:0] < 16) begin
          scause_reg.exc_code <= csr_wdata_i[30:0];
        end
      end
      `CSR_STVAL_ADDR: begin
        stval_reg <= csr_wdata_i;
      end
      `CSR_STVEC_ADDR: begin
        // Direct mode or vectored mode
        if (csr_wdata_i[1:0] < 2'b10) begin
          stvec_reg <= csr_wdata_i;
        end
      end
      `CSR_SSCRATCH_ADDR: begin
        sscratch_reg <= csr_wdata_i;
      end
      `CSR_SIE_ADDR: begin
        // Map sie write to mie
        mie_reg.seie = csr_wdata_i[9];
        mie_reg.ueie = csr_wdata_i[8];
        mie_reg.stie = csr_wdata_i[5];
        mie_reg.utie = csr_wdata_i[4];
        mie_reg.seie = csr_wdata_i[1];
        mie_reg.ueie = csr_wdata_i[0];
      end
      `CSR_SIP_ADDR: begin
        // STIP is read-only through sip
        // Do nothing as we are only implementing STIP
      end
      `CSR_SATP_ADDR: begin
        satp_reg <= csr_wdata_i;
      end
      default: ;
    endcase
  end

  else if (mtip_set_en_i | mtip_clear_en_i) begin
    mip_reg.mtip <= mtip_set_en_i;
  end
end

endmodule