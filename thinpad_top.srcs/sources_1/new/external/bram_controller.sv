module bram_controller #(
    parameter WISHBONE_DATA_WIDTH = 32,
    parameter WISHBONE_ADDR_WIDTH = 32,

    parameter BRAM_DATA_WIDTH = 32,
    parameter BRAM_ADDR_WIDTH = 17
)(
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

    // block ram interface
    input wire [BRAM_DATA_WIDTH-1:0] bram_data_i,
    output reg  [BRAM_DATA_WIDTH-1:0] bram_data_o,
    output reg  [BRAM_ADDR_WIDTH-1:0] bram_addr_a_o,
    output reg  [BRAM_ADDR_WIDTH-1:0] bram_addr_b_o,
    output reg  [BRAM_DATA_WIDTH/8-1:0] bram_wea_o

);
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

    // 四字节读取、写入，地址对齐
    wire [BRAM_ADDR_WIDTH-1:0] addr_a;
    wire [BRAM_ADDR_WIDTH-1:0] addr_b;
    wire [BRAM_DATA_WIDTH-1:0] w_data;
    assign addr_a = wb_adr_i[BRAM_ADDR_WIDTH-1:0];
    assign addr_b = wb_adr_i[BRAM_ADDR_WIDTH-1:0];
    assign w_data = wb_dat_i[31:24];

    // 读取数据
    logic [BRAM_DATA_WIDTH-1:0] data_reg;

    // 数据转移
    always_comb begin
        // 默认不写入字节，不读取字节
        // 将写数据硬连线到 bram 的写口
        // 将 bram 读数据硬连线到寄存器
        bram_wea_o = 0;
        bram_data_o = w_data;
        data_reg = bram_data_i;

        case(state)
            IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin  // write
                        bram_addr_a_o = addr_a;
                        bram_wea_o = 1;
                    end else begin      // read
                        bram_addr_b_o = addr_b;
                        bram_wea_o = 0;
                    end
                end
            end

            // 在读写期间时钟保持地址信号不变
            READ: begin
                bram_addr_a_o = addr_a;
                bram_wea_o = 0;
            end

            WRITE: begin
                bram_addr_b_o = addr_b;
                bram_wea_o = 1;
            end
        endcase
    end

    // 时序逻辑
    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            wb_ack_o <= 0;
        end

        case (state)
            IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if(!wb_we_i) begin      // read
                        wb_dat_o <= data_reg;
                    end
                    wb_ack_o <= 1;
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