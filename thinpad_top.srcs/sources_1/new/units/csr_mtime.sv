`default_nettype none
`timescale 1ns / 1ps

`include "../headers/csr.vh"

module (
  input wire clk_i,
  input wire rst_i,

  // Wishbone slave
  input wire wb_cyc_i,
  input wire wb_stb_i,
  output reg wb_ack_o,
  input wire [31:0] wb_adr_i,
  input wire [31:0] wb_dat_i,
  output reg [31:0] wb_dat_o,
  input wire [ 3:0] wb_sel_i,
  input wire wb_we_i
);

csr_mtime_t mtime_reg;
csr_mtimecmp_t mtimecmp_reg;

// ==== Begin read hardwire ====
always_comb begin
  wb_dat_o = 64'b0;
  case (wb_adr_i)
    `CSR_MTIME_MEM_ADDR:
      wb_dat_o = mtime_reg[31:0];
    `CSR_MTIME_MEM_ADDR+4:
      wb_dat_o = mtime_reg[63:32];
    `CSR_MTIMECMP_MEM_ADDR:
      wb_dat_o = mtimecmp_reg[31:0];
    `CSR_MTIMECMP_MEM_ADDR+4:
      wb_dat_o = mtimecmp_reg[63:32];
  endcase
end
// ===== End read hardwire =====

typedef enum logic[1:0] {
  STATE_IDLE,
  STATE_DONE
} state_t;

state_t state;

// ==== Begin write/read logic ====
always_ff @(posedge clk_i) begin
  if (rst_i) begin
    mtime_reg <= 64'b0;
    mtimecmp_reg <= 64'b0;
    state <= STATE_IDLE;
  end else begin
    case (state)
      STATE_IDLE: begin
        if (wb_cyc_i & wb_stb_i) begin
          if (wb_we_i) begin
            // Write
            case (wb_adr_i)
              `CSR_MTIME_MEM_ADDR:
                mtime_reg[31:0] <= wb_dat_i;
              `CSR_MTIME_MEM_ADDR+4:
                mtime_reg[63:32] <= wb_dat_i;
              `CSR_MTIMECMP_MEM_ADDR:
                mtimecmp_reg[31:0] <= wb_dat_i;
              `CSR_MTIMECMP_MEM_ADDR+4:
                mtimecmp_reg[63:32] <= wb_dat_i;
              default: ;
            endcase
          end

          ack_o <= 1'b1;
          state <= STATE_DONE;
        end
      end

      STATE_DONE: begin
        ack_o <= 1'b0;
        state <= STATE_IDLE;
      end
    endcase
  end
end
// ===== End write/read logic =====

endmodule