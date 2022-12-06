`timescale 1ns / 1ps
//
// 12: WIDTH: bits in register hdata & vdata
// 800: HSIZE: horizontal size of visible field 
// 856: HFP: horizontal front of pulse
// 976: HSP: horizontal stop of pulse
// 1040: HMAX: horizontal max size of value
// 600: VSIZE: vertical size of visible field 
// 637: VFP: vertical front of pulse
// 643:VSP: vertical stop of pulse
// 666: VMAX: vertical max size of value
// 1: HSPP: horizontal synchro pulse polarity (0 - negative, 1 - positive)
// 1: VSPP: vertical synchro pulse polarity (0 - negative, 1 - positive)
//
module vga #(
    parameter WIDTH = 0,
    HSIZE = 0,
    HFP = 0,
    HSP = 0,
    HMAX = 0,
    VSIZE = 0,
    VFP = 0,
    VSP = 0,
    VMAX = 0,
    HSPP = 0,
    VSPP = 0
) (
    // 时钟信号
    input wire clk,
    // 行同步信号
    output wire hsync,
    // 场同步信号
    output wire vsync,
    // 扫描的横坐标
    output reg [WIDTH - 1:0] hdata,
    // 扫描的纵坐标
    output reg [WIDTH - 1:0] vdata,
    // 行有效信号
    output wire data_enable
);

  // hdata
  always @(posedge clk) begin
    if (hdata == (HMAX - 1)) hdata <= 0;
    else hdata <= hdata + 1;
  end

  // vdata
  always @(posedge clk) begin
    if (hdata == (HMAX - 1)) begin
      if (vdata == (VMAX - 1)) vdata <= 0;
      else vdata <= vdata + 1;
    end
  end

  // hsync & vsync & blank
  assign hsync = ((hdata >= HFP) && (hdata < HSP)) ? HSPP : !HSPP;
  assign vsync = ((vdata >= VFP) && (vdata < VSP)) ? VSPP : !VSPP;
  assign data_enable = ((hdata < HSIZE) & (vdata < VSIZE));

endmodule
