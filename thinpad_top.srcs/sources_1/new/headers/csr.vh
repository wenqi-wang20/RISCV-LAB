`ifndef CSR_HEADER
`define CSR_HEADER

// ==== Begin Accessibility and priviledge ====
`define CSR_READ_ONLY  2'b11

`define CSR_USER       2'b00
`define CSR_SUPERVISOR 2'b01
`define CSR_MACHINE    2'b11
// ===== End Accessibility and priviledge =====

// ==== Begin CSR Addresses ====
`define CSR_MSTATUS_ADDR  12'h300
`define CSR_MTVEC_ADDR    12'h305
`define CSR_MIE_ADDR      12'h304
`define CSR_MIP_ADDR      12'h344
`define CSR_MSCRATCH_ADDR 12'h340
`define CSR_MEPC_ADDR     12'h341
`define CSR_MCAUSE_ADDR   12'h342
`define CSR_MHARTID_ADDR  12'hf14
`define CSR_MEDELEG_ADDR  12'h302
`define CSR_MIDELEG_ADDR  12'h303
`define CSR_MTVAL_ADDR    12'h343

`define CSR_SSTATUS_ADDR  12'h100
`define CSR_SEPC_ADDR     12'h141
`define CSR_SCAUSE_ADDR   12'h142
`define CSR_STVAL_ADDR    12'h143
`define CSR_STVEC_ADDR    12'h105
`define CSR_SSCRATCH_ADDR 12'h140
`define CSR_SIE_ADDR      12'h104
`define CSR_SIP_ADDR      12'h144
`define CSR_SATP_ADDR     12'h180

// These are MMIO registers
`define CSR_MTIME_MEM_ADDR    32'h200bff8
`define CSR_MTIMECMP_MEM_ADDR 32'h2004000
// ===== End CSR Addresses =====

// ==== Begin CSR definitions ====
typedef logic [31:0] csr_mscratch_t;

// WARL: mepc[1:0] == 0 on IALIGN = 32
typedef logic [31:0] csr_mepc_t;

typedef struct packed {
  logic       sd;
  logic [7:0] _p_0;
  logic       tsr;
  logic       tw;
  logic       tvm;
  logic       mxr;
  logic       sum;
  logic       mprv;
  logic [1:0] xs;
  logic [1:0] fs;
  logic [1:0] mpp;
  logic [1:0] _p_1;
  logic       spp;
  logic       mpie;
  logic       _p_2;
  logic       spie;
  logic       upie;
  logic       mie;
  logic       _p_3;
  logic       sie;
  logic       uie;
} csr_mstatus_t;

typedef struct packed {
  /* WARL: must be 4-byte aligned */
  logic [29:0] base;
  logic [1:0] mode; 
} csr_mtvec_t;

typedef struct packed {
  logic [19:0] _p_0;
  logic        meip;
  logic        _p_1;
  logic        seip;
  logic        ueip;
  logic        mtip;
  logic        _p_2;
  logic        stip;
  logic        utip;
  logic        msip;
  logic        _p_3;
  logic        ssip;
  logic        usip;
} csr_mip_t;

typedef struct packed {
  logic [19:0] _p_0;
  logic        meie;
  logic        _p_1;
  logic        seie;
  logic        ueie;
  logic        mtie;
  logic        _p_2;
  logic        stie;
  logic        utie;
  logic        msie;
  logic        _p_3;
  logic        ssie;
  logic        usie;
} csr_mie_t;

typedef logic [63:0] csr_mtime_t;
typedef logic [63:0] csr_mtimecmp_t;

typedef struct packed {
  logic        interrupt;
  logic [30:0] exc_code; // WLRL, spec p37
} csr_mcause_t;

// No need for an actual register in a single-processor system.
typedef logic [31:0] csr_mhartid_t;

typedef logic [31:0] csr_mideleg_t;

typedef logic [31:0] csr_medeleg_t;

typedef logic [31:0] csr_mtval_t;

//////// S-mode registers

typedef struct packed {
  logic        sd;
  logic [10:0] _p_0;
  logic        mxr;
  logic        sum;
  logic        _p_1;
  logic  [1:0] xs;
  logic  [1:0] fs;
  logic  [3:0] _p_2;
  logic        spp;
  logic  [1:0] _p_3;
  logic        spie;
  logic        upie;
  logic  [1:0] _p_4;
  logic        sie;
  logic        uie;
} csr_sstatus_t;

typedef logic [31:0] csr_sepc_t;

typedef struct packed {
  logic        interrupt;
  logic [30:0] exc_code;
} csr_scause_t;

typedef logic [31:0] csr_stval_t;

typedef struct packed {
  logic [29:0] base;
  logic [ 1:0] mode;
} csr_stvec_t;

typedef logic [31:0] csr_sscratch_t;

typedef struct packed {
  logic [21:0] _p_0;
  logic        seip;
  logic        ueip;
  logic [ 1:0] _p_1;
  logic        stip;
  logic        utip;
  logic [ 1:0] _p_2;
  logic        ssip;
  logic        usip;
} csr_sip_t;

typedef struct packed {
  logic [21:0] _p_0;
  logic        seie;
  logic        ueie;
  logic [ 1:0] _p_1;
  logic        stie;
  logic        utie;
  logic [ 1:0] _p_2;
  logic        ssie;
  logic        usie;
} csr_sie_t;

typedef struct packed {
  logic        mode; // Mode 0: 'Bare' mode, 1: 'Sv32' mode
  logic [ 8:0] asid; // Address space identifier
  logic [21:0] ppn;  // the physical page number (PPN) of the root page table
} csr_satp_t;
// ===== End CSR definitions =====

`endif