`timescale  1ns/1ps


module vga_pic #(
    parameter WIDTH = 0,
    parameter HSIZE = 0,
    parameter VSIZE = 0,
    parameter BRAMADDR_WIDTH = 0        // bram 地址宽度
)(

    // 时钟模块
    input wire vga_clk,
    // 输入 vga 有效显示区的 x 坐标
    input wire [WIDTH-1:0] hdata,
    // 输入 vga 有效显示区的 y 坐标
    input wire [WIDTH-1:0] vdata,
    // vga 的放大倍数
    input wire [2:0] vga_scale,
    // 输出 vga 有效显示区的像素颜色
    output reg [7:0] pixel,
    
    // bram 初始读取地址
    input wire [BRAMADDR_WIDTH-1:0] r_addr_st,
    // bram 输出地址
    output reg [BRAMADDR_WIDTH-1:0] r_addr,
    // bram 输出数据
    input wire [7:0] r_data
);
    parameter RED = 8'hA0;
    parameter GREEN = 8'h08;
    parameter PURPLE = 8'hB7;
    parameter BLUE = 8'h53;
    parameter YELLOW = 8'hD5;
    parameter WHITE = 8'hFF;
    parameter BLACK = 8'h00;
    parameter ORANGE = 8'hE8;

    logic [9:0] picwidth;
    logic [9:0] picheight;
    logic [9:0] width_x;
    logic [9:0] height_y;

    // bram 横纵坐标
    assign picwidth = HSIZE >> vga_scale;
    assign picheight = VSIZE >> vga_scale;

    // 示意图如下
    // 左上角的像素插值 scale * scale 区域的像素
    // *-------*-------*-------*--------
    // |       |       |       |       |
    // |   1   |   2   |   3   |   4   |
    // |       |       |       |       |
    // *-------*-------*-------*--------
    // |       |       |       |       |
    // |   5   |   6   |   7   |   8   |
    // |       |       |       |       |
    // ---------------------------------

    always_comb begin
        width_x = hdata >> vga_scale;
        height_y = vdata >> vga_scale;

        r_addr = r_addr_st + (height_y * picwidth) + width_x;
    end

    always_ff @ (posedge vga_clk) begin
        if (hdata < HSIZE && vdata < VSIZE) begin
            pixel <= r_data;
        end else begin
            pixel <= WHITE;
        end
    end

endmodule