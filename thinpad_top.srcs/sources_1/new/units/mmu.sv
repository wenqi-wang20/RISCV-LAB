`default_nettype none
`timescale 1ns / 1ps

`include "../headers/csr.vh"
`include "../headers/privilege.vh"

`define PAGE_SIZE       4096
`define PAGE_SIZE_SHIFT 12
`define PTE_SIZE        4
`define PTE_SIZE_SHIFT  2
`define LEVELS          2
`define TLB_TAG_WIDTH   5
`define TLB_INDEX_WIDTH 32-12-`TLB_TAG_WIDTH

`define INIT_TLB \
  tlb[0] <= 47'b0; \
  tlb[1] <= 47'b0; \
  tlb[2] <= 47'b0; \
  tlb[3] <= 47'b0; \
  tlb[4] <= 47'b0; \
  tlb[5] <= 47'b0; \
  tlb[6] <= 47'b0; \
  tlb[7] <= 47'b0; \
  tlb[8] <= 47'b0; \
  tlb[9] <= 47'b0; \
  tlb[10] <= 47'b0; \
  tlb[11] <= 47'b0; \
  tlb[12] <= 47'b0; \
  tlb[13] <= 47'b0; \
  tlb[14] <= 47'b0; \
  tlb[15] <= 47'b0; \
  tlb[16] <= 47'b0; \
  tlb[17] <= 47'b0; \
  tlb[18] <= 47'b0; \
  tlb[19] <= 47'b0; \
  tlb[20] <= 47'b0; \
  tlb[21] <= 47'b0; \
  tlb[22] <= 47'b0; \
  tlb[23] <= 47'b0; \
  tlb[24] <= 47'b0; \
  tlb[25] <= 47'b0; \
  tlb[26] <= 47'b0; \
  tlb[27] <= 47'b0; \
  tlb[28] <= 47'b0; \
  tlb[29] <= 47'b0; \
  tlb[30] <= 47'b0; \
  tlb[31] <= 47'b0;

`define SEND_WB_REQ \
  wb_cyc_o <= 1'b1; \
  wb_stb_o <= 1'b1; \
  wb_adr_o <= phy_addr; \
  wb_dat_o <= data_i; \
  wb_sel_o <= sel_i; \
  wb_we_o <= store_en_i;

`define PHY_ADDR_VALID \
  ((phy_addr >= 32'h1000_0000 && phy_addr <= 32'h1000_FFFF) || \
  phy_addr == `CSR_MTIMECMP_MEM_ADDR || phy_addr == `CSR_MTIMECMP_MEM_ADDR+4 || \
  phy_addr == `CSR_MTIME_MEM_ADDR || phy_addr == `CSR_MTIME_MEM_ADDR+4 || \
  (32'h8000_0000 <= phy_addr && phy_addr <= 32'h807F_FFFF) || \
  (32'h8100_0000 <= phy_addr && phy_addr <= 32'h81FF_FFFF) || \
  (32'h8300_0000 <= phy_addr && phy_addr <= 32'h83FF_FFFF) || \
  (32'h8400_0000 <= phy_addr && phy_addr <= 32'h84FF_FFFF) || \
  (32'h8500_0000 <= phy_addr && phy_addr <= 32'h85FF_FFFF) || \
  (32'h8600_0000 <= phy_addr && phy_addr <= 32'h86FF_FFFF))

module mmu (
  input wire clk_i,
  input wire rst_i,

  input wire [1:0] privilege_i,

  // Content of satp register, should persist during request
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

  output logic invalid_addr_o,

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
  csr_satp_t satp;
  assign v_addr = v_addr_t'(v_addr_i);
  assign satp = csr_satp_t'(satp_i);
  // ==== End type casting ====

  // ==== Begin TLB ====
  // TODO: Access control?
  typedef struct packed {
    logic [`TLB_INDEX_WIDTH-1:0] index;
    logic                 [21:0] ppn;
    logic                 [ 8:0] asid;
    logic                        valid;
  } tlb_entry_t;

  tlb_entry_t tlb[0:31]; // 2^5 entries

  // Utility signals
  wire [`TLB_TAG_WIDTH-1:0]  tlb_tag;
  tlb_entry_t                tlb_entry;
  wire                       tlb_hit;

  wire [`TLB_INDEX_WIDTH-1:0] v_addr_index;

  assign tlb_tag = v_addr_i[31:32-`TLB_TAG_WIDTH];
  assign tlb_entry = tlb[tlb_tag];
  assign v_addr_index = v_addr_i[31-`TLB_TAG_WIDTH:12];
  assign tlb_hit = tlb_entry.valid && tlb_entry.asid == satp.asid &&
                   tlb_entry.index == v_addr_index;
  // === End TLB ===

  /* Reference: Privileged Architecture Specification,
                4.3.2 Virtual Address Translation Process*/
  // ==== Begin address translation ====
  
  // Internal registers
  pte_t read_pte;
  reg pf_occur;
  assign load_pf_o = pf_occur & load_en_i;
  assign store_pf_o = pf_occur & store_en_i;
  assign fetch_pf_o = pf_occur & fetch_en_i;
  
  assign read_pte = pte_t'(wb_dat_i);

  // Utility signals
  wire r_en, w_en;
  assign r_en = load_en_i | fetch_en_i;
  assign w_en = store_en_i;
  wire direct;
  assign direct = satp.mode == 1'b0 || privilege_i == `PRIVILEGE_M;

  // Translation related signals
  wire [33:0] a;
  wire [31:0] pte_addr;
  reg         cur_level; // Current level

  assign a = cur_level == 1'b1 ? {12'b0, satp.ppn} << `PAGE_SIZE_SHIFT
                               : {12'b0, read_pte.ppn_1, read_pte.ppn_0} << `PAGE_SIZE_SHIFT;
  assign pte_addr = cur_level == 1'b1 ? a + ({12'b0, v_addr.vpn_1} << `PTE_SIZE_SHIFT)
                                      : a + ({12'b0, v_addr.vpn_0} << `PTE_SIZE_SHIFT);

  p_addr_t phy_addr;

  always_comb begin
    phy_addr = 34'b0;
    if (r_en | w_en) begin
      if (direct) begin
        phy_addr = v_addr;
      end else if (tlb_hit) begin
        phy_addr = {tlb_entry.ppn, v_addr.offset};
      end else begin
        phy_addr.ppn_1 = read_pte.ppn_1;
        phy_addr.ppn_0 = cur_level == 1'b1 ? v_addr.vpn_0 : read_pte.ppn_0;
        phy_addr.offset = v_addr.offset;
      end
    end
  end

  typedef enum logic [2:0] {
    STATE_FETCH_PTE      = 0,
    STATE_MEM_ACCESS     = 1,
    STATE_DONE           = 2
  } state_t;

  state_t state;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      // Internal registers
      state <= STATE_FETCH_PTE;
      cur_level <= 1'b1;
      pf_occur <= 1'b0;
      // Outputs
      ack_o <= 1'b0;
      // Wishbone
      wb_cyc_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_we_o <= 1'b0;
      invalid_addr_o <= 1'b0;

      `INIT_TLB
    end else begin
      case (state)
        STATE_FETCH_PTE: begin
          if (flush_en_i) begin
            `INIT_TLB

            ack_o <= 1'b1;
            state <= STATE_DONE;

          end else if (r_en | w_en) begin
            if (direct/*TODO: | tlb_hit*/) begin
              if (!`PHY_ADDR_VALID) begin
                invalid_addr_o <= 1'b1;
                ack_o <= 1'b1;
                state <= STATE_DONE;
              end else begin
                `SEND_WB_REQ
                state <= STATE_MEM_ACCESS;
              end
            end else begin
              // Send wishbone request to retrive PTE
              wb_cyc_o <= 1'b1;
              wb_stb_o <= 1'b1;
              wb_adr_o <= pte_addr;
              wb_sel_o <= 4'b1111;
              wb_we_o <= 1'b0;

              if (wb_ack_i) begin
                // End wishbone request
                wb_cyc_o <= 1'b0;
                wb_stb_o <= 1'b0;
                // Decode PTE
                if (~read_pte.v | (~read_pte.r & read_pte.w)) begin
                  // Invalid PTE, raise page fault
                  pf_occur <= 1'b1;
                  ack_o <= 1'b1;

                  state <= STATE_DONE;
                end else begin
                  // The PTE is valid
                  // TODO: Privilege mode checkings
                  if (read_pte.r | read_pte.x) begin
                    // Leaf PTE
                    if ((load_en_i & ~read_pte.r) |
                        (store_en_i & ~read_pte.w) |
                        (fetch_en_i & ~read_pte.x)) begin
                      // Illegal memory access, raise page fault
                      pf_occur <= 1'b1;
                      ack_o <= 1'b1;
                      state <= STATE_DONE;
                    end else if (cur_level == 1'b1 && read_pte.ppn_0 != 0) begin
                      // Misaligned superpage, raise page fault
                      pf_occur <= 1'b1;
                      ack_o <= 1'b1;
                      state <= STATE_DONE;
                    end /*else if (~read_pte.a | (store_en_i & ~read_pte.d)) begin
                      // According to the spec, we can either raise a page fault or update the PTE
                      // FIXME: Just raise a page fault here, I don't know if this works
                      pf_occur <= 1'b1;
                      ack_o <= 1'b1;
                      state <= STATE_DONE;
                    end*/ else begin
                      if (!`PHY_ADDR_VALID) begin
                        invalid_addr_o <= 1'b1;
                        ack_o <= 1'b1;
                        state <= STATE_DONE;
                      end else begin
                        // Valid memory access, update TLB
                        tlb[tlb_tag].index <= v_addr_index;
                        tlb[tlb_tag].ppn <= {read_pte.ppn_1, read_pte.ppn_0};
                        tlb[tlb_tag].asid <= satp.asid;
                        tlb[tlb_tag].valid <= 1'b1;

                        `SEND_WB_REQ
                        state <= STATE_MEM_ACCESS;
                      end
                    end
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
                    end
                  end
                end
              end
            end
          end
        end


        STATE_MEM_ACCESS: begin
          `SEND_WB_REQ

          if (wb_ack_i) begin
            // End wishbone request
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            wb_we_o <= 1'b0;
            data_o <= wb_dat_i;

            ack_o <= 1'b1;
            state <= STATE_DONE;
          end
        end

        STATE_DONE: begin
          // Reset signals
          pf_occur <= 1'b0;
          ack_o <= 1'b0;
          cur_level <= 1'b1;
          invalid_addr_o <= 1'b0;

          state <= STATE_FETCH_PTE;
        end
      endcase
    end
  end
  // ==== End address translation ====

endmodule