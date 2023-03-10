module vga_selector #(
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

    // vga interface
    output reg [2:0] vga_scale,
    input wire vga_end,

    // bram read interface
    input wire [7:0] bram_0_data,
    input wire [7:0] bram_1_data,    
    output reg [7:0] real_bram_data
);

    // 状态转移
    typedef enum logic [1:0] {
        IDLE = 0,
        READ = 1,
        WRITE = 2,
        WRITE_2 = 3
    } state_t;
    state_t state, next_state;

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
                if(vga_end) begin
                    next_state = WRITE_2;
                end else begin
                    next_state = WRITE;
                end
            end

            WRITE_2: begin
                next_state = IDLE;  // 多周期写（等待 vga end 信号）
            end
        endcase
    end


    // 0x8600_0000 - 0x8600_0004 vga scale register (3 or 1)
    reg [31:0] vga_scale_reg = 32'h0000_0003;
    // 0x8600_0004 - 0x8600_0008 bram address register (0 or 1)
    reg [31:0] bram_sele_reg = 32'h0000_0000;

    logic sele_sync = 0;
    logic [2:0] vga_scale_sync = 3'b001;

    assign vga_scale = vga_scale_sync;
    assign real_bram_data = sele_sync ? bram_1_data : bram_0_data;

    logic [WISHBONE_DATA_WIDTH-1:0] wb_dat_o_tmp;

    // 根据行渲染结束信号来切换渲染地址

    // 此处应该使用时序逻辑
    // always_comb begin
    //     // 在这里，切换分辨率和切换渲染地址在逻辑上是同步的
    //     // 但是在实际的硬件中，这两个操作是异步的
    //     // 需要再设计一层缓存来实现同时更新
    //     if (vga_end) begin
    //         if(bram_sele_reg[0] == 0 && sele_sync == 1) begin
    //             sele_sync = 0;
    //             vga_scale_sync = vga_scale_reg;
    //         end else if (bram_sele_reg[0] == 1 && sele_sync == 0) begin
    //             sele_sync = 1;
    //             vga_scale_sync = vga_scale_reg;
    //         end
    //     end
    // end

    // 数据转移
    always_comb begin
        
        // 输出数据
        wb_dat_o_tmp = vga_scale_reg;

        // 根据不同地址，选择不同的寄存器
        if(wb_adr_i[7:0] == 8'h00) begin
            wb_dat_o_tmp = vga_scale_reg;
        end else if(wb_adr_i[7:0] == 8'h04) begin
            wb_dat_o_tmp = bram_sele_reg;
        end else begin
            // if address is not valid, return 15 
            wb_dat_o_tmp = 32'h0000_1111;
        end
    end

    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            wb_ack_o <= 0;

            vga_scale_reg <= 32'h0000_0001;
            bram_sele_reg <= 32'h0000_0001;

            sele_sync <= 1;
            vga_scale_sync <= 3'b001;
        end

        case(state)
            IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    if (!wb_we_i) begin  // read
                        wb_dat_o <= wb_dat_o_tmp;
                        wb_ack_o <= 1;
                    end else begin       // write
                        if (wb_adr_i[7:0] == 8'h00) begin
                            vga_scale_reg <= wb_dat_i;
                        end else if(wb_adr_i[7:0] == 8'h04) begin
                            bram_sele_reg <= wb_dat_i;
                        end
                        wb_ack_o <= 0;
                    end
                end
            end

            READ: begin
                wb_ack_o <= 0;
            end

            WRITE: begin
                if(vga_end) begin
                    wb_ack_o <= 1;

                    // 时序逻辑修改
                    sele_sync <= bram_sele_reg[0];
                    vga_scale_sync <= vga_scale_reg[2:0];
                end else begin 
                    wb_ack_o <= 0;
                end
            end

            WRITE_2: begin
                wb_ack_o <= 0;
            end
        endcase
    end

endmodule