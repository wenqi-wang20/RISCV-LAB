module instr_decoder(
  input wire [31:0] instr,
  output reg [ 4:0] rs1,
  output reg [ 4:0] rs2,
  output reg [ 4:0] rd,
  output reg [31:0] imm,
  output reg [ 4:0] shamt
);
  logic [6:0] opcode;
  always_comb begin  
    rs1 = instr[19:15];
    rs2 = instr[24:20];
    rd = instr[11:7];
    shamt = instr[24:20];
    opcode = instr[6:0];
    case (opcode)
      7'b011_0111,7'b001_0111: begin  // U-type
        imm = {instr[31:12], 12'b0};
      end
      7'b110_1111: begin  // J-type
        imm = $signed({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});
      end
      7'b110_0111, 7'b000_0011, 7'b001_0011: begin  // I-type
        imm = $signed({instr[31:20]});
      end
      7'b110_0011: begin  // B-type
        imm = $signed({instr[31], instr[7], instr[30:25], instr[11:8], 1'b0});
      end
      7'b010_0011: begin  // S-type
        imm = $signed({instr[31:25], instr[11:7]});
      end
      default: begin
        imm = 32'b0;
      end
    endcase
  end
endmodule