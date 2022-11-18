typedef struct packed {
  /* WARL: must be 4-byte aligned */
  logic [29:0] base;
  /* WARL: 0 - direct, 1 - vectored, >=2: reserved
     When MODE=Direct, all traps into machine mode cause the pc to be set to
     the address in the BASE field. When MODE=Vectored, all synchronous
     exceptions into machine mode cause the pc to be set to the address
     in the BASE field, whereas interrupts cause the pc to be set to the
     address in the BASE field plus four times the interrupt cause number.*/
  logic [1:0] mode; 
} csr_mevec_t;

typedef logic [31:0] mscratch_t;

// WARL: mepc[1:0] == 0 on IALIGN = 32
typedef logic [31:0] mepc_t;

typedef struct packed {
  logic        interrupt;
  logic [30:0] exc_code; // WLRL, spec p37
} csr_mcause_t;

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
  logic [19:0] _p_0;
  logic        meip;
  logid        _p_1;
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

////////
typedef struct packed {
  logic        mode; // Mode 0: 'Bare' mode, 1: 'Sv32' mode
  logic [ 8:0] asid; // Address space identifier
  logic [21:0] ppn;  // the physical page number (PPN) of the root page table
} csr_satp_t;
