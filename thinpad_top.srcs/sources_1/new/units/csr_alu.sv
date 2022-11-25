`default_nettype none
`timescale 1ns / 1ps

`include "../headers/csr.vh"

module csr_alu (
  input wire  [1:0]  privilege_i,
  output wire        invalid_r_o,
  output wire        invalid_w_o,
);

always_comb begin
  case ()
end

endmodule