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
  logic [31:0] slt_result;
  logic [31:0] sltu_result;
  logic [31:0] sbclr_result;
  logic [31:0] min_result;
  logic [31:0] pack_result;

  always_comb begin
    add_result = a + b;
    sub_result = a - b;
    sll_result = a << b[4:0];
    srl_result = a >> b[4:0];
    sra_result = $signed(a) >>> b[4:0];
    and_result = a & b;
    or_result  = a | b;
    xor_result = a ^ b;
    slt_result = $signed(a) < $signed(b);
    sltu_result = a < b;
    sbclr_result = a & ~({31'b0, 1'b1} << (b[4:0]));
    min_result = $signed(a) < $signed(b) ? a : b;
    pack_result = {b[15:0], a[15:0]};
  end

  assign result = op == ALU_ADD ? add_result
                : op == ALU_SUB ? sub_result
                : op == ALU_SLL ? sll_result
                : op == ALU_SRL ? srl_result
                : op == ALU_SRA ? sra_result
                : op == ALU_AND ? and_result
                : op == ALU_OR  ? or_result
                : op == ALU_XOR ? xor_result
                : op == ALU_SLT ? slt_result
                : op == ALU_SLTU ? sltu_result
                : op == ALU_SBCLR ? sbclr_result
                : op == ALU_MIN ? min_result
                : op == ALU_PACK ? pack_result
                : 32'b0;
endmodule