`include "../headers/alu.vh"
module alu(
  input wire  [31:0] a,
  input wire  [31:0] b,
  input wire  [ 3:0] op,
  output wire [31:0] result
);
  logic [31:0] add_result;
  logic [31:0] sub_result;
  logic [31:0] sll_result;
  logic [31:0] srl_result;
  logic [31:0] sra_result;
  logic [31:0] and_result;
  logic [31:0] or_result;
  logic [31:0] xor_result;
  logic [31:0] eq_result;
  logic [31:0] neq_result;
  logic [31:0] lt_result;
  logic [31:0] ltu_result;
  logic [31:0] ge_result;
  logic [31:0] geu_result;

  always_comb begin
    add_result = a + b;
    sub_result = a - b;
    sll_result = a << b[4:0];
    srl_result = a >> b[4:0];
    sra_result = $signed(a) >>> b[4:0];
    and_result = a & b;
    or_result  = a | b;
    xor_result = a ^ b;
    eq_result  = (a == b) ? 1 : 0;
    neq_result = (a != b) ? 1 : 0;
    lt_result  = ($signed(a)   <  $signed(b))   ? 1 : 0;
    ltu_result = ($unsigned(a) <  $unsigned(b)) ? 1 : 0;
    ge_result  = ($signed(a)   >= $signed(b))   ? 1 : 0;
    geu_result = ($unsigned(a) >= $unsigned(b)) ? 1 : 0;
  end

  assign result = opcode == ALU_ADD ? add_result
                : opcode == ALU_SUB ? sub_result
                : opcode == ALU_SLL ? sll_result
                : opcode == ALU_SRL ? srl_result
                : opcode == ALU_SRA ? sra_result
                : opcode == ALU_AND ? and_result
                : opcode == ALU_OR  ? or_result
                : opcode == ALU_XOR ? xor_result
                : opcode == ALU_EQ  ? eq_result
                : opcode == ALU_NEQ ? neq_result
                : opcode == ALU_LT  ? lt_result
                : opcode == ALU_LTU ? ltu_result
                : opcode == ALU_GE  ? ge_result
                : opcode == ALU_GEU ? geu_result
                : 32'b0;
endmodule