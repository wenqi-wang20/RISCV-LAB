`timescale  1ns/1ps

module vga_pic #(
    parameter WIDTH = 0,
    parameter HSIZE = 0,
    parameter VSIZE = 0
)(

    // 时钟模块
    input wire vga_clk,
    // 输入 vga 有效显示区的 x 坐标
    input wire [WIDTH-1:0] hdata,
    // 输入 vga 有效显示区的 y 坐标
    input wire [WIDTH-1:0] vdata,
    // 输出 vga 有效显示区的像素颜色
    output reg [7:0] pixel

);
    parameter RED = 8'hA0;
    parameter GREEN = 8'h08;
    parameter PURPLE = 8'hB7;
    parameter BLUE = 8'h53;
    parameter YELLOW = 8'hD5;
    parameter WHITE = 8'hFF;
    parameter BLACK = 8'h00;
    parameter ORANGE = 8'hE8;

    always_ff @ (posedge vga_clk) begin
        if (hdata < HSIZE/2) begin
            if (vdata < VSIZE/2) begin
                pixel <= RED;
            end else begin
                pixel <= GREEN;
            end
        end else begin
            if (vdata < VSIZE/2) begin
                pixel <= PURPLE;
            end else begin
                pixel <= BLUE;
            end
        end
    end

endmodule