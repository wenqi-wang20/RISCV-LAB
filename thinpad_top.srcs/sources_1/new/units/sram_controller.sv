module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n,
    output reg sram_oe_n,
    output reg sram_we_n,
    output reg [SRAM_BYTES-1:0] sram_be_n
);

    // FSM state definition
    typedef enum logic [1:0] {STATE_IDLE, STATE_READ, STATE_WRITE, STATE_WRITE_2} state_t;
    state_t current_state, next_state;
    
    // FSM state transition
    always @(posedge clk_i) begin
        if (rst_i) begin
            current_state <= STATE_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM state output
    always_comb begin
        next_state = STATE_IDLE;  // default next state
        case (current_state)
            STATE_IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin  // write
                        next_state = STATE_WRITE;
                    end else begin  // read
                        next_state = STATE_READ;
                    end
                end
            end
            STATE_READ: begin
                next_state = STATE_IDLE;
            end
            STATE_WRITE: begin
                next_state = STATE_WRITE_2;
            end
            STATE_WRITE_2: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    wire [31:0]  sram_data_i_comb;
    reg  [31:0]  sram_data_o_comb;
    reg          sram_data_t_comb;

    assign sram_data = sram_data_t_comb ? 32'bz : sram_data_o_comb;
    assign sram_data_i_comb = sram_data;

    // FSM output
    always_comb begin
        sram_ce_n = 1'b1;
        sram_oe_n = 1'b1;
        sram_we_n = 1'b1;
        sram_be_n = ~wb_sel_i;  // debug this for too long 😅
        sram_addr = wb_adr_i[SRAM_ADDR_WIDTH+1:2];  // 4 bytes align
        sram_data_t_comb = 1'b0;
        case (current_state)
            STATE_IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin  // write
                        sram_ce_n = 1'b0;
                        sram_oe_n = 1'b1;
                        sram_we_n = 1'b1;
                        sram_data_t_comb = 1'b0;
                    end else begin // read
                        sram_ce_n = 1'b0;
                        sram_oe_n = 1'b0;
                        sram_we_n = 1'b1;
                        sram_data_t_comb = 1'b1;
                    end
                end
            end
            STATE_READ: begin
                sram_ce_n = 1'b0;
                sram_oe_n = 1'b0;
                sram_we_n = 1'b1;
                sram_data_t_comb = 1'b1;
            end
            STATE_WRITE: begin
                sram_ce_n = 1'b0;
                sram_oe_n = 1'b1;
                sram_we_n = 1'b0;
                sram_data_t_comb = 1'b0;
            end
            STATE_WRITE_2: begin
                sram_ce_n = 1'b0;
                sram_oe_n = 1'b1;
                sram_we_n = 1'b1;
                sram_data_t_comb = 1'b0;
            end
        endcase

        case (wb_sel_i)
            4'b0001: begin
                sram_data_o_comb = {24'b0, wb_dat_i[7:0]};
            end
            4'b0010: begin
                sram_data_o_comb = {16'b0, wb_dat_i[7:0], 8'b0};
            end
            4'b0100: begin
                sram_data_o_comb = {8'b0, wb_dat_i[7:0], 16'b0};
            end
            4'b1000: begin
                sram_data_o_comb = {wb_dat_i[7:0], 24'b0};
            end
            4'b1100: begin
                sram_data_o_comb = {wb_dat_i[15:0], 16'b0};
            end
            4'b0011: begin
                sram_data_o_comb = {16'b0, wb_dat_i[15:0]};
            end
            4'b1111: begin
                sram_data_o_comb = wb_dat_i;
            end
            default: begin
                sram_data_o_comb = wb_dat_i;
            end
        endcase
    end

    always@(posedge clk_i) begin
        if (rst_i) begin
            wb_ack_o <= 1'b0;  // reset ack
        end
        case (current_state)
            STATE_IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (!wb_we_i) begin  // read
                        wb_ack_o <= 1'b1;  // set ack
                        wb_dat_o <= sram_data_i_comb;
                    end
                end
            end
            STATE_READ: begin
                wb_ack_o <= 1'b0;  // clear ack
            end
            STATE_WRITE: begin 
                wb_ack_o <= 1'b1;  // set ack
            end
            STATE_WRITE_2: begin
                wb_ack_o <= 1'b0;  // clear ack
            end
        endcase
    end
endmodule
