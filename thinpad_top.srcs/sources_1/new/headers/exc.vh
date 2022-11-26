`ifndef EXC_HEADER
`define EXC_HEADER

// ===== System instruction type =====

`define SYS_INSTR_T_WIDTH 3

typedef enum logic [SYS_INSTR_T_WIDTH-1:0] {
  SYS_INSTR_CSRRW,
  SYS_INSTR_CSRRS,
  SYS_INSTR_CSRRC,
  SYS_INSTR_ECALL,
  SYS_INSTR_EBREAK,
  SYS_INSTR_NOP
} sys_instr_t;

// ===== End System instruction type =====

// ===== signals to Exception Unit =====

`define EXC_SIG_T_WIDTH 96

typedef struct packed {
  logic        exc_occur,
  logic [31:0] cur_pc,
  logic [30:0] sync_exc_code, // WLRL, spec p37
  logic [31:0] mtval
} exc_sig_t;

`define EXC_SIG_NULL {1'b0, 32'b0, 31'b0, 32'b0}

// ===== End signals to Exception Unit =====

// ===== Exception code =====

`define EXC_CODE_T_WIDTH 31
`define EXC_USER_SOFTWARE_INTERRUPT 31'd0
`define EXC_SUPERVISOR_SOFTWARE_INTERRUPT 31'd1
`define EXC_MACHINE_SOFTWARE_INTERRUPT 31'd3
`define EXC_USER_TIMER_INTERRUPT 31'd4
`define EXC_SUPERVISOR_TIMER_INTERRUPT 31'd5
`define EXC_MACHINE_TIMER_INTERRUPT 31'd7
`define EXC_USER_EXTERNAL_INTERRUPT 31'd8
`define EXC_SUPERVISOR_EXTERNAL_INTERRUPT 31'd9
`define EXC_MACHINE_EXTERNAL_INTERRUPT 31'd11
`define EXC_INSTRUCTION_ADDRESS_MISALIGNED 31'd0
`define EXC_INSTRUCTION_ACCESS_FAULT 31'd1
`define EXC_ILLEGAL_INSTRUCTION 31'd2
`define EXC_BREAKPOINT 31'd3
`define EXC_LOAD_ADDRESS_MISALIGNED 31'd4
`define EXC_LOAD_ACCESS_FAULT 31'd5
`define EXC_STORE_AMO_ADDRESS_MISALIGNED 31'd6
`define EXC_STORE_AMO_ACCESS_FAULT 31'd7
`define EXC_ECALL_FROM_U_MODE 31'd8
`define EXC_ECALL_FROM_S_MODE 31'd9
`define EXC_ECALL_FROM_M_MODE 31'd11
`define EXC_INSTRUCTION_PAGE_FAULT 31'd12
`define EXC_LOAD_PAGE_FAULT 31'd13
`define EXC_STORE_AMO_PAGE_FAULT 31'd15

// ===== End Exception code =====
`endif