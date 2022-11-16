`default_nettype none
`timescale 1ns / 1ps

`define PAGE_SIZE       4096
`define PAGE_SIZE_SHIFT 12
`define PTE_SIZE        4
`define PTE_SIZE_SHIFT  2
`define LEVELS          2

module mmu (
  input wire clk_i,
  input wire rst_i,

  // Content of satp register
  input wire [31:0] satp_i,

  // Data read and write
  input  wire [31:0] v_addr_i,
  input  wire [31:0] data_i,
  output reg  [31:0] data_o,
  input  wire [ 3:0] sel_i,
  output reg         ack_o,

  // Enabling signals
  input wire load_en_i,  // Load
  input wire store_en_i, // Store
  input wire fetch_en_i, // Fetch instruction
  input wire flush_en_i, // Flush the TLB

  // Page faults
  output reg load_pf_o,
  output reg store_pf_o,
  output reg fetch_pf_o,

  // Wishbone master
  output reg         wb_cyc_o,
  output reg         wb_stb_o,
  input  wire        wb_ack_i,
  output reg  [31:0] wb_adr_o,
  output reg  [31:0] wb_dat_o,
  input  wire [31:0] wb_dat_i,
  output reg  [ 3:0] wb_sel_o,
  output reg         wb_we_o
);
  // satp register
  typedef struct packed {
    logic        mode; // Ignored...
    logic [ 8:0] asid; // Address space identifier
    logic [21:0] ppn;  // the physical page number (PPN) of the root page table
  } satp_reg_t;

  // Virtual address
  typedef struct packed {
    logic [ 9:0] vpn_1;
    logic [ 9:0] vpn_0;
    logic [11:0] offset;
  } v_addr_t;

  // Physical address
  typedef struct packed {
    logic [11:0] ppn_1;
    logic [ 9:0] ppn_0;
    logic [11:0] offset;
  } p_addr_t;

  // Page table entry (PTE)
  typedef struct packed {
    logic [11:0] ppn_1;
    logic [ 9:0] ppn_0;
    logic [ 1:0] rsw;
    /* Dirty bit */
    logic d;
    /* Accessed bit */
    logic a;
    /* Global mapping */
    logic g;
    /* Accessibility to user mode */
    logic u;
    /* Permission bits
       000: Pointer to next level of page table.
       001: Read-only page.
       010: Reserved for future use.
       011: Read-write page.
       100: Execute-only page.
       101: Read-execute page.
       110: Reserved for future use.
       111: Read-write-execute page. */
    logic x;
    logic w;
    logic r;
    /* Valid bit
       if it is 0, all other bits in the PTE are don’t-cares and may
       be used freely by software. */
    logic v;
  } pte_t;

  // ==== Begin type casting ====
  v_addr_t v_addr;
  satp_reg_t satp;

  assign v_addr = v_addr_t'(v_addr_i);
  assign satp = satp_reg_t'(satp_i);
  // ==== End type casting ====


  // ==== Begin address translation ====
  // Reference: Privileged Architecture Specification,
  //            4.3.2 Virtual Address Translation Process
  
  // Internal registers
  pte_t read_pte;
  logic pf_occur;
  assign load_pf_o = pf_occur & load_en_i;
  assign store_pf_o = pf_occur & store_en_i;
  assign fetch_pf_o = pf_occur & fetch_en_i;

  // Utility signals
  logic r_en, w_en;

  assign r_en = load_en_i | fetch_en_i;
  assign w_en = store_en_i;

  // Translation related signals
  logic [31:0] a;
  logic [31:0] pte_addr;
  logic        cur_level; // Current level

  assign a = cur_level == 1'b1 ? satp.ppn << `PAGE_SIZE_SHIFT
                               : {read_pte.ppn_1, read_pte.ppn_0} << `PAGE_SIZE_SHIFT;
  assign pte_addr = cur_level == 1'b1 ? a + (v_addr_i.vpn_1 << `PTE_SIZE_SHIFT)
                                      : a + (v_addr_i.vpn_0 << `PTE_SIZE_SHIFT);

  typedef enum logic [2:0] {
    STATE_FETCH_PTE = 0,
    STATE_DECODE_PTE = 1,
    STATE_MEM_ACCESS = 2,
    STATE_DONE = 3
  } state_t;

  state_t state;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      // Internal registers
      state <= STATE_IDLE;
      cur_level <= 1'b1;
      pf_occur <= 1'b0;
      // Outputs
      ack_o <= 1'b0;
      // Wishbone
      wb_cyc_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_we_o <= 1'b0;
    end else begin
      case (state)
        STATE_FETCH_PTE: begin
          // Initiate translation on enabling signals
          if (r_en | w_en) begin
            // Send wishbone request
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            wb_adr_o <= pte_addr;
            wb_sel_o <= 4'b1111;
            wb_we_o <= 1'b0;

            if (wb_ack_i) begin
              // End wishbone request
              wb_cyc_o <= 1'b0;
              wb_stb_o <= 1'b0;
              // Store the read PTE
              read_pte <= pte_t'(wb_dat_i);
              
              state <= STATE_DECODE_PTE;
            end
          end
        end

        STATE_DECODE_PTE: begin
          // Check PTE
          if (~pte.v | (~pte.r & pte.w)) begin
            // Invalid PTE, raise page fault
            pf_occur <= 1'b1;
            ack_o <= 1'b1;

            state <= STATE_DONE;
          end else begin
            // The PTE is valid
            if (pte.r | pte.x) begin
              // Leaf PTE, access memory
              state <= STATE_MEM_ACCESS;
            end else begin
              // Non-leaf PTE
              if (cur_level == 1'b0) begin
                // Raise page fault on level == 0
                pf_occur <= 1'b1;
                ack_o <= 1'b1;

                state <= STATE_DONE;
              end else begin
                // Fetch next level PTE
                cur_level <= 1'b0;
                state <= STATE_FETCH_PTE;
              end
            end
          end
        end

        STATE_MEM_ACCESS: begin
          // Not implementing privilege mode checking here
          if ((load_pf_o & ~pte.r) |
              (store_pf_o & ~pte.w) |
              (fetch_pf_o & ~pte.x)) begin
            // Illegal memory access, raise page fault
            pf_occur <= 1'b1;
            ack_o <= 1'b1;
            state <= STATE_DONE;
          end else if (cur_level == 1'b1 && pte.ppn_0 != 0) begin
            // Misaligned superpage, raise page fault
            pf_occur <= 1'b1;
            ack_o <= 1'b1;
            state <= STATE_DONE;
          end else if (~pte.a | (store_en_i & ~pte.d)) begin
            // According to the spec, we can either raise a page fault or update the PTE
            // FIXME: Just raise a page fault here, I don't know if this works
            pf_occur <= 1'b1;
            ack_o <= 1'b1;
            state <= STATE_DONE;
          end else begin
            // Finally, we can access the memory
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            wb_adr_o <= {read_pte.ppn_1,
                         cur_level == 1'b1 ? v_addr_i.vpn_0 : 10'b0,
                         v_addr_i.offset};
            wb_dat_o <= data_i;
            wb_sel_o <= sel_i;
            wb_we_o <= store_en_i;
          end

          if (wb_ack_i) begin
              // End wishbone request
              wb_cyc_o <= 1'b0;
              wb_stb_o <= 1'b0;
              wb_we_o <= 1'b0;
              data_o <= wb_dat_i;

              ack_o <= 1'b1;
              state <= STATE_DECODE_PTE;
          end
        end

        STATE_DONE: begin
          // Reset signals
          pf_occur <= 1'b0;
          ack_o <= 1'b0;
          cur_level <= 1'b1;

          state <= STATE_FETCH_PTE;
        end
      endcase
    end
  end
  // ==== End address translation ====

endmodule
