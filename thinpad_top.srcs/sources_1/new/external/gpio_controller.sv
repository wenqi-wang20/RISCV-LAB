module gpio_controller #(
    parameter WISHBONE_DATA_WIDTH = 32,
    parameter WISHBONE_ADDR_WIDTH = 32
) (
    // clock and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [WISHBONE_ADDR_WIDTH-1:0] wb_adr_i,
    input wire [WISHBONE_DATA_WIDTH-1:0] wb_dat_i,
    output reg [WISHBONE_DATA_WIDTH-1:0] wb_dat_o,
    input wire [WISHBONE_DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // gpio interface
    input wire [31:0] dip_sw,
    input wire [3:0] touch_btn,
    input wire push_btn
);

    // 定义状态机
    typedef enum logic [1:0] {
        IDLE = 0,
        READ = 1,
        WRITE = 2
    } state_t;
    state_t state, next_state;

    // 状态转移
    always @(posedge clk_i) begin
        if (rst_i) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = IDLE;
        case(state)
            IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin  // write
                        next_state = WRITE;
                    end else begin  // read
                        next_state = READ;
                    end
                end
            end

            READ: begin
                next_state = IDLE;  // 两周期读
            end

            WRITE: begin
                next_state = IDLE;  // 两周期写
            end
        endcase
    end

    wire [WISHBONE_DATA_WIDTH-1:0] gpio_data;
    assign gpio_data = dip_sw;

    wire [WISHBONE_DATA_WIDTH-1:0] btn_data;
    assign btn_data = {27'b0, touch_btn, push_btn};

    logic [WISHBONE_DATA_WIDTH-1:0] wb_data_tmp;

    // 数据转移
    always_comb begin
        
        wb_data_tmp = gpio_data;

        // 根据不同的数据输出不同的数据
        if (wb_adr_i[3:0] == 4'h0) begin
            wb_data_tmp = gpio_data;
        end else if (wb_adr_i[3:0] == 4'h4) begin
            wb_data_tmp = btn_data;
        end else begin
            // if address is not valid, return 15
            wb_data_tmp = 32'h0000_1111;
        end
    end

    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            wb_ack_o <= 0;
        end

        case (state)
            IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if(!wb_we_i) begin          // only for read
                        wb_dat_o <= wb_data_tmp;
                        wb_ack_o <= 1;
                    end else begin              // not prehibit write but not support
                        wb_ack_o <= 1;
                    end
                end
            end

            READ: begin
                wb_ack_o <= 0;
            end

            WRITE: begin
                wb_ack_o <= 0;
            end
        endcase
    end

endmodule