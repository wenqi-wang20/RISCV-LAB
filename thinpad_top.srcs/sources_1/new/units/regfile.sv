module regfile(
  input wire clk_i,
  input wire rst_i,

  input  wire [ 4:0] raddr_a_i,
  input  wire [ 4:0] raddr_b_i,
  input  wire [ 4:0] waddr_i,
  input  wire [31:0] wdata_i,
  input  wire        wen_i,
  output wire [31:0] rdata_a_o,
  output wire [31:0] rdata_b_o
);
  reg [31:0] regfile[31:0];
  logic bypass_a;
  logic bypass_b;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      regfile[0] <= 32'h0000;
      regfile[32'hA] <= 32'h0000;
      regfile[32'hB] <= 32'h0000;
    end else if (wen_i && waddr_i != 5'b00000) begin
      regfile[waddr_i] <= wdata_i;
    end
  end

  always_comb begin
    bypass_a = wen_i && waddr_i == raddr_a_i && raddr_a_i != 5'b00000;
    bypass_b = wen_i && waddr_i == raddr_b_i && raddr_b_i != 5'b00000;
  end

  assign rdata_a_o = bypass_a ? wdata_i : regfile[raddr_a_i];
  assign rdata_b_o = bypass_b ? wdata_i : regfile[raddr_b_i];
endmodule