`include "../headers/alu.vh"
`include "../headers/csr.vh"
`include "../headers/exc.vh"
`include "../headers/privilege.vh"
module instr_decoder(
  input wire  [31:0] instr_i,
  input wire  [ 1:0] privilege_i,
  output reg  [31:0] imm_o,
  output reg         mem_en_o,
  output reg         mem_wen_o,
  output reg  [`ALU_OP_T_WIDTH-1:0] alu_op_o,
  output reg         alu_a_sel_o,  // 0: rs1, 1: pc
  output reg         alu_b_sel_o,  // 0: rs2, 1: imm
  output wire [ 4:0] rf_raddr_a_o,
  output wire [ 4:0] rf_raddr_b_o,
  output reg  [ 4:0] rf_waddr_o,
  output reg         rf_wen_o,
  output reg         instr_legal_o,
  output reg  [`SYS_INSTR_T_WIDTH-1:0] sys_instr_o
);
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [4:0] rs1, rs2, rd;

  always_comb begin
    opcode = instr_i[6:0];
    funct3 = instr_i[14:12];
    funct7 = instr_i[31:25];

    // register file address 
    rs1 = instr_i[19:15];
    rs2 = instr_i[24:20];
    rd  = instr_i[11:7];

    // default values
    sys_instr_o = SYS_INSTR_NOP;

    // alu operation, instruction legality and system instruction type
    case (opcode)
      7'b011_0111: begin  // lui
        alu_op_o = ALU_ADD;
        rs1 = 5'b00000;
        alu_a_sel_o = 1'b0;  // rs1 = x0
        alu_b_sel_o = 1'b1;  // imm
        instr_legal_o = 1'b1;
      end
      7'b001_0111: begin  // auipc
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b1;  // pc
        alu_b_sel_o = 1'b1;  // imm
        instr_legal_o = 1'b1;
      end
      7'b110_1111: begin  // jal
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b1;  // pc
        alu_b_sel_o = 1'b1;  // imm
        instr_legal_o = 1'b1;
      end
      7'b110_0111: begin  // jalr
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b0;  // rs1
        alu_b_sel_o = 1'b1;  // imm
        instr_legal_o = (funct3 == 3'b000) ? 1'b1 : 1'b0;
      end
      7'b110_0011: begin // branch
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b1;  // pc
        alu_b_sel_o = 1'b1;  // imm
        case (funct3)
          3'b000: instr_legal_o = 1'b1;  // beq
          3'b001: instr_legal_o = 1'b1;  // bne
          3'b100: instr_legal_o = 1'b1;  // blt
          3'b101: instr_legal_o = 1'b1;  // bge
          3'b110: instr_legal_o = 1'b1;  // bltu
          3'b111: instr_legal_o = 1'b1;  // bgeu
          default: instr_legal_o = 1'b0;
        endcase
      end
      7'b000_0011: begin  // load
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b0;  // rs1
        alu_b_sel_o = 1'b1;  // imm
        case (funct3)
          3'b000: instr_legal_o = 1'b1;  // lb
          3'b001: instr_legal_o = 1'b1;  // lh
          3'b010: instr_legal_o = 1'b1;  // lw
          3'b100: instr_legal_o = 1'b1;  // lbu
          3'b101: instr_legal_o = 1'b1;  // lhu
          default: instr_legal_o = 1'b0;
        endcase
      end
      7'b010_0011: begin  // store
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b0;  // rs1
        alu_b_sel_o = 1'b1;  // imm
        case (funct3)
          3'b000: instr_legal_o = 1'b1;  // sb
          3'b001: instr_legal_o = 1'b1;  // sh
          3'b010: instr_legal_o = 1'b1;  // sw
          default: instr_legal_o = 1'b0;
        endcase
      end
      7'b001_0011: begin  // immediate
        case (funct3)
          3'b000: begin  // addi
            alu_op_o = ALU_ADD;
            instr_legal_o = 1'b1;
          end
          3'b010: begin  // slti
            alu_op_o = ALU_SLT;
            instr_legal_o = 1'b1;
          end
          3'b011: begin  // sltiu
            alu_op_o = ALU_SLTU;
            instr_legal_o = 1'b1;
          end
          3'b100: begin  // xori
            alu_op_o = ALU_XOR;
            instr_legal_o = 1'b1;
          end
          3'b110: begin  // ori
            alu_op_o = ALU_OR;
            instr_legal_o = 1'b1;
          end
          3'b111: begin  // andi
            alu_op_o = ALU_AND;
            instr_legal_o = 1'b1;
          end
          3'b001: begin  // slli
            alu_op_o = ALU_SLL;
            instr_legal_o = (funct7 == 7'b000_0000) ? 1'b1 : 1'b0;
          end
          3'b101: begin
            case (funct7)
              7'b000_0000: begin  // srli
                alu_op_o = ALU_SRL;
                instr_legal_o = 1'b1;
              end
              7'b010_0000: begin  // srai
                alu_op_o = ALU_SRA;
                instr_legal_o = 1'b1;
              end
              default: begin
                alu_op_o = ALU_ADD;
                instr_legal_o = 1'b0;
              end
            endcase
          end
          default: begin
            alu_op_o = ALU_ADD;
            instr_legal_o = 1'b0;
          end
        endcase
        alu_a_sel_o = 1'b0;  // rs1
        alu_b_sel_o = 1'b1;  // imm
      end
      7'b011_0011: begin  // register
        case (funct3)
          3'b000: begin
            case (funct7)
              7'b000_0000: begin  // add
                alu_op_o = ALU_ADD;
                instr_legal_o = 1'b1;
              end
              7'b010_0000: begin  // sub
                alu_op_o = ALU_SUB;
                instr_legal_o = 1'b1;
              end
              default: begin
                alu_op_o = ALU_ADD;
                instr_legal_o = 1'b0;
              end
            endcase
          end
          3'b001: begin
            case (funct7)
              7'b000_0000: begin  // sll
                alu_op_o = ALU_SLL;
                instr_legal_o = 1'b1;
              end
              7'b010_0100: begin // sbclr
                alu_op_o = ALU_SBCLR;
                instr_legal_o = 1'b1;
              end
              default: begin
                alu_op_o = ALU_ADD;
                instr_legal_o = 1'b0;
              end
            endcase
          end
          3'b010: begin
            alu_op_o = ALU_SLT;  // slt
            instr_legal_o = (funct7 == 7'b000_0000) ? 1'b1 : 1'b0;
          end
          3'b011: begin
            alu_op_o = ALU_SLTU; // sltu
            instr_legal_o = (funct7 == 7'b000_0000) ? 1'b1 : 1'b0;
          end
          3'b100: begin
            case (funct7)
              7'b000_0000: begin  // xor
                alu_op_o = ALU_XOR;
                instr_legal_o = 1'b1;
              end
              7'b000_0101: begin  // min
                alu_op_o = ALU_MIN;
                instr_legal_o = 1'b1;
              end
              7'b000_0100: begin  // pack
                alu_op_o = ALU_PACK;
                instr_legal_o = 1'b1;
              end
              7'b001_0100: begin // XPERM8
                alu_op_o = ALU_XPERM8;
                instr_legal_o = 1'b1;
              end
              default: begin
                alu_op_o = ALU_ADD;
                instr_legal_o = 1'b0;
              end
            endcase
          end
          3'b101: begin
            case (funct7)
              7'b000_0000: begin  // srl
                alu_op_o = ALU_SRL;
                instr_legal_o = 1'b1;
              end
              7'b010_0000: begin  // sra
                alu_op_o = ALU_SRA;
                instr_legal_o = 1'b1;
              end
              default: begin
                alu_op_o = ALU_ADD;
                instr_legal_o = 1'b0;
              end
            endcase
          end
          3'b110: begin  // or
            alu_op_o = ALU_OR;
            instr_legal_o = (funct7 == 7'b000_0000) ? 1'b1 : 1'b0;
          end
          3'b111: begin  // and
            alu_op_o = ALU_AND;
            instr_legal_o = (funct7 == 7'b000_0000) ? 1'b1 : 1'b0;
          end
          default: begin
            alu_op_o = ALU_ADD;
            instr_legal_o = 1'b0;
          end
        endcase
        alu_a_sel_o = 1'b0;  // rs1
        alu_b_sel_o = 1'b0;  // rs2
      end
      // TODO: add support for csr illegal instruction exception check
      7'b111_0011: begin // system
        case (funct3)
          3'b000: begin  // ecall, ebreak, mret, sret, uret, wfi, sfence.vma
            case (funct7)
              7'b000_0000: begin  // ecall, ebreak, uret
                case (rs2)
                  5'b0_0000: begin  // ecall
                    instr_legal_o = (rs1 == 5'b0_0000 && rd == 5'b0_0000) ? 1'b1 : 1'b0;
                    sys_instr_o = SYS_INSTR_ECALL;
                  end
                  5'b0_0001: begin  // ebreak
                    instr_legal_o = (rs1 == 5'b0_0000 && rd == 5'b0_0000) ? 1'b1 : 1'b0;
                    sys_instr_o = SYS_INSTR_EBREAK;
                  end
                  5'b0_0010: begin  // uret
                    instr_legal_o = 1'b0;
                    // TODO: add support for uret
                    // instr_legal_o = (privilege_i == `PRIVILEGE_U && rs1 == 5'b0_0000 && rd == 5'b0_0000) ? 1'b1 : 1'b0;
                    sys_instr_o = SYS_INSTR_URET;
                  end
                  default: begin
                    instr_legal_o = 1'b0;
                    sys_instr_o = SYS_INSTR_NOP;
                  end
                endcase
              end
              7'b000_1000: begin  // sret, wfi
                case (rs2)
                  5'b0_0010: begin  // sret
                    instr_legal_o = (privilege_i >= `PRIVILEGE_S && rs1 == 5'b0_0000 && rd == 5'b0_0000) ? 1'b1 : 1'b0;
                    sys_instr_o = SYS_INSTR_SRET;
                  end
                  5'b0_0101: begin  // wfi
                    instr_legal_o = 1'b0;
                    sys_instr_o = SYS_INSTR_NOP;
                    // TODO: add support for wfi
                    // instr_legal_o = (rs1 == 5'b0_0000 && rd == 5'b0_0000) ? 1'b1 : 1'b0;
                    // sys_instr_o = SYS_INSTR_WFI;
                  end
                  default: begin
                    instr_legal_o = 1'b0;
                    sys_instr_o = SYS_INSTR_NOP;
                  end
                endcase
              end
              7'b001_1000: begin  // mret
                case (rs2)
                  5'b0_0010: begin  // mret
                    instr_legal_o = (privilege_i == `PRIVILEGE_M && rs1 == 5'b0_0000 && rd == 5'b0_0000) ? 1'b1 : 1'b0;
                    sys_instr_o = SYS_INSTR_MRET;
                  end
                  default: begin
                    instr_legal_o = 1'b0;
                    sys_instr_o = SYS_INSTR_NOP;
                  end
                endcase
              end
              7'b000_1001: begin  // sfence.vma
                instr_legal_o = (rd == 5'b0_0000) ? 1'b1 : 1'b0;
                sys_instr_o = SYS_INSTR_SFENCE_VMA;
              end
              default: begin
                instr_legal_o = 1'b0;
                sys_instr_o = SYS_INSTR_NOP;
              end
            endcase
          end
          3'b001: begin  // csrrw
            instr_legal_o = 1'b1;
            sys_instr_o = SYS_INSTR_CSRRW;
          end
          3'b010: begin  // csrrs
            instr_legal_o = 1'b1;
            sys_instr_o = SYS_INSTR_CSRRS;
          end
          3'b011: begin  // csrrc
            instr_legal_o = 1'b1;
            sys_instr_o = SYS_INSTR_CSRRC;
          end
          3'b101: begin  // csrrwi
            instr_legal_o = 1'b1;
            sys_instr_o = SYS_INSTR_CSRRWI;
          end
          3'b110: begin  // csrrsi
            instr_legal_o = 1'b1;
            sys_instr_o = SYS_INSTR_CSRRSI;
          end
          3'b111: begin  // csrrci
            instr_legal_o = 1'b1;
            sys_instr_o = SYS_INSTR_CSRRCI;
          end
          default: begin
            instr_legal_o = 1'b0;
            sys_instr_o = SYS_INSTR_NOP;
          end
        endcase
        alu_op_o = ALU_ADD;
        alu_a_sel_o = 1'b0;  // rs1
        alu_b_sel_o = 1'b0;  // rs2
      end
      default: begin
        alu_op_o = ALU_ADD;
        instr_legal_o = 1'b0;
        alu_a_sel_o = 1'b0;  // rs1
        alu_b_sel_o = 1'b0;  // rs2
      end
    endcase

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

    // register file write enable
    case (opcode)
      7'b011_0111: begin  // lui
        rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
      end
      7'b001_0111: begin  // auipc
        rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
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
      7'b111_0011: begin // system
        case (funct3)
          3'b000: begin  // ecall, ebreak, mret, sret, uret, wfi, sfence.vma
            rf_wen_o = 1'b0;
          end
          3'b001: begin  // csrrw
            rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
          end
          3'b010: begin  // csrrs
            rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
          end
          3'b011: begin  // csrrc
            rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
          end
          3'b101: begin  // csrrwi
            rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
          end
          3'b110: begin  // csrrsi
            rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
          end
          3'b111: begin  // csrrci
            rf_wen_o = (rd != 5'b00000) ? 1'b1 : 1'b0;
          end
          default: begin
            rf_wen_o = 1'b0;
          end
        endcase
      end
      default: begin
        rf_wen_o = 1'b0;
      end
    endcase
  end

  assign rf_raddr_a_o = rs1;
  assign rf_raddr_b_o = rs2;
  assign rf_waddr_o   = rd;
endmodule