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

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      for (int i = 0; i < 32; i = i + 1) begin
        regfile[i] <= 32'h0000;
      end
    end else if (wen_i && waddr_i != 5'b00000) begin
      regfile[waddr_i] <= wdata_i;
    end
  end

  assign rdata_a_o = regfile[raddr_a_i];
  assign rdata_b_o = regfile[raddr_b_i];
endmodule