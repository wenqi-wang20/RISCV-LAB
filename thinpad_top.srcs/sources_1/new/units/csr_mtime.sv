`default_nettype none
`timescale 1ns / 1ps

`include "../headers/csr.vh"

module csr_mtime(
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
  input wire wb_we_i,

  // machine timer interrupt signals to the CPU
  output wire mti_occur_o,
  output wire mti_occur_n_o
);

csr_mtime_t mtime_reg;
csr_mtimecmp_t mtimecmp_reg;

assign mti_occur_o = (mtime_reg >= mtimecmp_reg);
assign mti_occur_n_o = ~mti_occur_o;

// ==== Begin read hardwire ====
always_comb begin
  wb_dat_o = 64'b0;
  case (wb_adr_i)
    `CSR_MTIME_MEM_ADDR: begin
      wb_dat_o = mtime_reg[31:0];
    end
    `CSR_MTIME_MEM_ADDR+4: begin
      wb_dat_o = mtime_reg[63:32];
    end
    `CSR_MTIMECMP_MEM_ADDR: begin
      wb_dat_o = mtimecmp_reg[31:0];
    end
    `CSR_MTIMECMP_MEM_ADDR+4: begin
      wb_dat_o = mtimecmp_reg[63:32];
    end
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
    wb_ack_o <= 1'b0;
  end else begin
    case (state)
      STATE_IDLE: begin
        if (wb_cyc_i & wb_stb_i) begin
          if (wb_we_i) begin
            // Write
            case (wb_adr_i)
              `CSR_MTIME_MEM_ADDR: begin
                mtime_reg[31:0] <= wb_dat_i;
              end
              `CSR_MTIME_MEM_ADDR+4: begin
                mtime_reg[63:32] <= wb_dat_i;
              end
              `CSR_MTIMECMP_MEM_ADDR: begin
                mtimecmp_reg[31:0] <= wb_dat_i;
                mtime_reg <= mtime_reg + 64'b1;
              end
              `CSR_MTIMECMP_MEM_ADDR+4: begin
                mtimecmp_reg[63:32] <= wb_dat_i;
                mtime_reg <= mtime_reg + 64'b1;
              end
              default: begin
                mtime_reg <= mtime_reg + 64'b1;
              end
            endcase
          end else begin
            mtime_reg <= mtime_reg + 64'b1;
          end
          wb_ack_o <= 1'b1;
          state <= STATE_DONE;
        end else begin
          mtime_reg <= mtime_reg + 64'b1;
        end
      end

      STATE_DONE: begin
        wb_ack_o <= 1'b0;
        state <= STATE_IDLE;
        mtime_reg <= mtime_reg + 64'b1;
      end
    endcase
  end
end
// ===== End write/read logic =====

endmodule