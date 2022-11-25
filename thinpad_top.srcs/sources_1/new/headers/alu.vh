`ifndef ALU_HEADER
`define ALU_HEADER
`define ALU_OP_T_WIDTH 4
// alu_op type
typedef enum logic [ALU_OP_T_WIDTH-1:0] {
  ALU_ADD,
  ALU_SUB,
  ALU_SLL,
  ALU_SRL,
  ALU_SRA,
  ALU_AND,
  ALU_OR,
  ALU_XOR,
  ALU_SLT,
  ALU_SLTU,
  ALU_SBCLR,
  ALU_MIN,
  ALU_PACK
} alu_op_t;
`endif