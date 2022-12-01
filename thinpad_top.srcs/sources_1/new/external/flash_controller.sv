module flash_controller #(
    .WISHBONE_DATA_WIDTH(32),
    .WISHBONE_ADDR_WIDTH(32),

    .FLASH_DATA_WIDTH(8),
    .FLASH_ADDR_WIDTH(23),
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

    // flash interface
    output reg [FLASH_DATA_WIDTH-1:0] flash_a_o,
    inout reg [FLASH_ADDR_WIDTH-1:0] flash_d,
    output reg flash_rp_o,
    output reg flash_ce_o,
    output reg flash_oe_o
);

    // flash 的 write 指令空转，不进行操作，两个周期后返回正常
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

    // 单字节读取，写入，不做地址对齐
    wire [FLASH_ADDR_WIDTH-1:0] flash_addr;
    assign flash_addr = wb_adr_i[FLASH_ADDR_WIDTH-1:0];

    wire [WISHBONE_DATA_WIDTH-1:0] flash_data_i_comb;
    reg [FLASH_DATA_WIDTH-1:0] flash_data_o_comb;
    reg flash_data_t_comb;

    assign flash_d = flash_data_t_comb ? 8'bz : flash_data_o_comb;
    assign flash_data_i_comb = flash_d;
    assign flash_data_t_comb = 1;


    // 数据转移
    always_comb begin
        // 规定不写入字节
        // 默认不读取字节
        flash_rp_o = 1;  // 暂时不管 flash 的 reset 按钮
        flash_oe_o = 1;
        flash_ce_o = 1;

        case(state) 
            IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if(wb_we_i) begin       // write
                        // pass
                    end else begin          // read
                        flash_oe_o = 0;
                        flash_ce_o = 0;
                        flash_a_o = flash_addr;
                    end
                end
            end

            READ: begin
                flash_oe_o = 0;
                flash_ce_o = 0;
                flash_a_o = flash_addr;
            end

            WRITE: begin
                // pass
            end
        endcase
    end


    // wishbone 数据输出
    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            wb_ack_o <= 0;
            // pass for flash reset
        end

        case(state)
            IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (wb_we_i) begin       // write
                        // pass
                    end else begin          // read
                        wb_dat_o <= flash_data_i_comb;
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