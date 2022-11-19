`include "../../headers/alu.vh"
module instr_decoder(
  input wire  [31:0] instr_i,
  output reg  [31:0] imm_o,
  output reg         mem_en_o,
  output reg         mem_wen_o,
  output reg  [ 3:0] alu_op_o,
  output reg         alu_a_sel_o,  // 0: rs1, 1: pc
  output reg         alu_b_sel_o,  // 0: rs2, 1: imm
  output wire [ 4:0] rf_raddr_a_o,
  output wire [ 4:0] rf_raddr_b_o,
  output reg  [ 4:0] rf_waddr_o,
  output reg         rf_wen_o
);
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [4:0] rs1, rs2, rd;

  assign rf_raddr_a_o = rs1;
  assign rf_raddr_b_o = rs2;
  assign rf_waddr_o  = rd;

  always_comb begin  
    rs1  = instr_i[19:15];
    rs2  = instr_i[24:20];
    rd   = instr_i[11:7];
    opcode = instr_i[6:0];
    funct3 = instr_i[14:12];
    funct7 = instr_i[31:25];
    
    // immediate generation
    case (opcode)
      7'b011_0111, 7'b001_0111: begin  // U-type
        imm_o = {instr_i[31:12], 12'b0};
      end
      7'b110_1111: begin  // J-type
        imm_o = $signed({instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0});
      end
      7'b110_0111, 7'b000_0011, 7'b001_0011: begin  // I-type
        imm_o = $signed({instr_i[31:20]});
      end
      7'b110_0011: begin  // B-type
        imm_o = $signed({instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0});
      end
      7'b010_0011: begin  // S-type
        imm_o = $signed({instr_i[31:25], instr_i[11:7]});
      end
      default: begin
        imm_o = 32'b0;
      end
    endcase

    // memory enable
    case (opcode)
      7'b000_0011: begin // load
        mem_en_o = (rd != 5'b000000) ? 1'b1 : 1'b0;
        mem_wen_o = 1'b0;
      end
      7'b010_0011: begin // store
        mem_en_o = 1'b1;
        mem_wen_o = 1'b1;
      end
      default: begin
        mem_en_o = 1'b0;
        mem_wen_o = 1'b0;
      end
    endcase

    // alu operation
    case (opcode)
      7'b011_0111: begin  // lui
        alu_op_o = ALU_NOP;
        alu_a_sel_o = 1'b0;
        alu_b_sel_o = 1'b0;
      end
      7'b001_0111: begin  // auipc
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b1;
        alu_b_sel_o = 1'b1;
      end
      7'b110_1111: begin  // jal
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b1;
        alu_b_sel_o = 1'b1;
      end
      7'b110_0111: begin  // jalr
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b0;
        alu_b_sel_o = 1'b1;
      end
      7'b110_0011: begin // branch
        case (funct3)
          3'b000: alu_op_o = ALU_EQ;  // beq
          3'b001: alu_op_o = ALU_NE;  // bne
          3'b100: alu_op_o = ALU_LT;  // blt
          3'b101: alu_op_o = ALU_GE;  // bge
          3'b110: alu_op_o = ALU_LTU; // bltu
          3'b111: alu_op_o = ALU_GEU; // bgeu
          default: alu_op_o = ALU_NOP;
        endcase
        alu_a_sel_o = 1'b0;
        alu_b_sel_o = 1'b0;
      end
      7'b000_0011: begin  // load
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b0;
        alu_b_sel_o = 1'b1;
      end
      7'b010_0011: begin  // store
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b0;
        alu_b_sel_o = 1'b1;
      end
      7'b001_0011: begin  // immediate
        case (funct3)
          3'b000: alu_op_o = ALU_ADD;  // addi
          3'b010: alu_op_o = ALU_SLT;  // slti
          3'b011: alu_op_o = ALU_SLTU; // sltiu
          3'b100: alu_op_o = ALU_XOR;  // xori
          3'b110: alu_op_o = ALU_OR;   // ori
          3'b111: alu_op_o = ALU_AND;  // andi
          3'b001: alu_op_o = ALU_SLL;  // slli
          3'b101: begin
            case (funct7)
              7'b000_0000: alu_op_o = ALU_SRL;  // srli
              7'b010_0000: alu_op_o = ALU_SRA;  // srai
              default: alu_op_o = ALU_NOP;
            endcase
          end
          default: alu_op_o = ALU_NOP;
        endcase
        alu_a_sel_o = 1'b0;
        alu_b_sel_o = 1'b1;
      end
      7'b011_0011: begin  // register
        case (funct3)
          3'b000: begin
            case (funct7)
              7'b000_0000: alu_op_o = ALU_ADD;  // add
              7'b010_0000: alu_op_o = ALU_SUB;  // sub
              default: alu_op_o = ALU_NOP;
            endcase
          end
          3'b001: alu_op_o = ALU_SLL;  // sll
          3'b010: alu_op_o = ALU_SLT;  // slt
          3'b011: alu_op_o = ALU_SLTU; // sltu
          3'b100: alu_op_o = ALU_XOR;  // xor
          3'b101: begin
            case (funct7)
              7'b000_0000: alu_op_o = ALU_SRL;  // srl
              7'b010_0000: alu_op_o = ALU_SRA;  // sra
              default: alu_op_o = ALU_NOP;
            endcase
          end
          3'b110: alu_op_o = ALU_OR;   // or
          3'b111: alu_op_o = ALU_AND;  // and
          default: alu_op_o = ALU_NOP;
        endcase
        alu_a_sel_o = 1'b0;
        alu_b_sel_o = 1'b0;
      end
      default: begin
        alu_op_o = ALU_NOP;
        alu_a_sel_o = 1'b0;
        alu_b_sel_o = 1'b0;
      end
    endcase

    // register file write enable
    case (opcode)
      7'b011_0111: begin  // lui
        rf_wen_o = 1'b0;
      end
      7'b001_0111: begin  // auipc
        rf_wen_o = 1'b0;
      end
      7'b110_1111: begin  // jal
        rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
      end
      7'b110_0111: begin  // jalr
        rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
      end
      7'b110_0011: begin // branch
        rf_wen_o = 1'b0;
      end
      7'b000_0011: begin  // load
        rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
      end
      7'b010_0011: begin  // store
        rf_wen_o = 1'b0;
      end
      7'b001_0011: begin  // immediate
        rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
      end
      7'b011_0011: begin  // register
        rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
      end
      default: begin
        rf_wen_o = 1'b0;
      end
    endcase
  end
endmodule