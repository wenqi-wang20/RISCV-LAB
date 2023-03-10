 `default_nettype none

module thinpad_top (
    input wire clk_50M,     // 50MHz 时钟输入
    input wire clk_11M0592, // 11.0592MHz 时钟输入（备用，可不用）

    input wire push_btn,  // BTN5 按钮�?关，带消抖电路，按下时为 1
    input wire reset_btn, // BTN6 复位按钮，带消抖电路，按下时�? 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4，按钮开关，按下时为 1
    input  wire [31:0] dip_sw,     // 32 位拨码开关，拨到“ON”时�? 1
    output wire [15:0] leds,       // 16 �? LED，输出时 1 点亮
    output wire [ 7:0] dpy0,       // 数码管低位信号，包括小数点，输出 1 点亮
    output wire [ 7:0] dpy1,       // 数码管高位信号，包括小数点，输出 1 点亮

    // CPLD 串口控制器信�?
    output wire uart_rdn,        // 读串口信号，低有�?
    output wire uart_wrn,        // 写串口信号，低有�?
    input  wire uart_dataready,  // 串口数据准备�?
    input  wire uart_tbre,       // 发�?�数据标�?
    input  wire uart_tsre,       // 数据发�?�完毕标�?

    // BaseRAM 信号
    inout wire [31:0] base_ram_data,  // BaseRAM 数据，低 8 位与 CPLD 串口控制器共�?
    output wire [19:0] base_ram_addr,  // BaseRAM 地址
    output wire [3:0] base_ram_be_n,  // BaseRAM 字节使能，低有效。如果不使用字节使能，请保持�? 0
    output wire base_ram_ce_n,  // BaseRAM 片�?�，低有�?
    output wire base_ram_oe_n,  // BaseRAM 读使能，低有�?
    output wire base_ram_we_n,  // BaseRAM 写使能，低有�?

    // ExtRAM 信号
    inout wire [31:0] ext_ram_data,  // ExtRAM 数据
    output wire [19:0] ext_ram_addr,  // ExtRAM 地址
    output wire [3:0] ext_ram_be_n,  // ExtRAM 字节使能，低有效。如果不使用字节使能，请保持�? 0
    output wire ext_ram_ce_n,  // ExtRAM 片�?�，低有�?
    output wire ext_ram_oe_n,  // ExtRAM 读使能，低有�?
    output wire ext_ram_we_n,  // ExtRAM 写使能，低有�?

    // 直连串口信号
    output wire txd,  // 直连串口发�?�端
    input  wire rxd,  // 直连串口接收�?

    // Flash 存储器信号，参�?? JS28F640 芯片手册
    output wire [22:0] flash_a,  // Flash 地址，a0 仅在 8bit 模式有效�?16bit 模式无意�?
    inout wire  [15:0] flash_d,  // Flash 数据
    output wire flash_rp_n,  // Flash 复位信号，低有效
    output wire flash_vpen,  // Flash 写保护信号，低电平时不能擦除、烧�?
    output wire flash_ce_n,  // Flash 片�?�信号，低有�?
    output wire flash_oe_n,  // Flash 读使能信号，低有�?
    output wire flash_we_n,  // Flash 写使能信号，低有�?
    output wire flash_byte_n, // Flash 8bit 模式选择，低有效。在使用 flash �? 16 位模式时请设�? 1

    // USB 控制器信号，参�?? SL811 芯片手册
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB 数据线与网络控制器的 dm9k_sd[7:0] 共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // 网络控制器信号，参�?? DM9000A 芯片手册
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // 图像输出信号
    output wire [2:0] video_red,    // 红色像素�?3 �?
    output wire [2:0] video_green,  // 绿色像素�?3 �?
    output wire [1:0] video_blue,   // 蓝色像素�?2 �?
    output wire       video_hsync,  // 行同步（水平同步）信�?
    output wire       video_vsync,  // 场同步（垂直同步）信�?
    output wire       video_clk,    // 像素时钟输出
    output wire       video_de      // 行数据有效信号，用于区分消隐�?
);

  /* =========== Demo code begin =========== 

  // PLL 分频示例
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // 外部时钟输入
      // Clock out ports
      .clk_out1(clk_10M),  // 时钟输出 1，频率在 IP 配置界面中设�?
      .clk_out2(clk_20M),  // 时钟输出 2，频率在 IP 配置界面中设�?
      // Status and control signals
      .reset(reset_btn),  // PLL 复位输入
      .locked(locked)  // PLL 锁定指示输出�?"1"表示时钟稳定�?
                       // 后级电路复位信号应当由它生成（见下）
  );

  logic reset_of_clk10M;
  // 异步复位，同步释放，�? locked 信号转为后级电路的复�? reset_of_clk10M
  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end

  always_ff @(posedge clk_10M or posedge reset_of_clk10M) begin
    if (reset_of_clk10M) begin
      // Your Code
    end else begin
      // Your Code
    end
  end

  // 不使用内存�?�串口时，禁用其使能信号
  assign base_ram_ce_n = 1'b1;
  assign base_ram_oe_n = 1'b1;
  assign base_ram_we_n = 1'b1;

  assign ext_ram_ce_n = 1'b1;
  assign ext_ram_oe_n = 1'b1;
  assign ext_ram_we_n = 1'b1;

  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  // 数码管连接关系示意图，dpy1 同理
  // p=dpy0[0] // ---a---
  // c=dpy0[1] // |     |
  // d=dpy0[2] // f     b
  // e=dpy0[3] // |     |
  // b=dpy0[4] // ---g---
  // a=dpy0[5] // |     |
  // f=dpy0[6] // e     c
  // g=dpy0[7] // |     |
  //           // ---d---  p

  // 7 段数码管译码器演示，�? number �? 16 进制显示在数码管上面
  logic [7:0] number;
  SEG7_LUT segL (
      .oSEG1(dpy0),
      .iDIG (number[3:0])
  );  // dpy0 是低位数码管
  SEG7_LUT segH (
      .oSEG1(dpy1),
      .iDIG (number[7:4])
  );  // dpy1 是高位数码管

  logic [15:0] led_bits;
  assign leds = led_bits;

  always_ff @(posedge push_btn or posedge reset_btn) begin
    if (reset_btn) begin  // 复位按下，设�? LED 为初始�??
      led_bits <= 16'h1;
    end else begin  // 每次按下按钮�?关，LED 循环左移
      led_bits <= {led_bits[14:0], led_bits[15]};
    end
  end

  // 直连串口接收发�?�演示，从直连串口收到的数据再发送出�?
  logic [7:0] ext_uart_rx;
  logic [7:0] ext_uart_buffer, ext_uart_tx;
  logic ext_uart_ready, ext_uart_clear, ext_uart_busy;
  logic ext_uart_start, ext_uart_avai;

  assign number = ext_uart_buffer;

  // 接收模块�?9600 无检验位
  async_receiver #(
      .ClkFrequency(50000000),
      .Baud(9600)
  ) ext_uart_r (
      .clk           (clk_50M),         // 外部时钟信号
      .RxD           (rxd),             // 外部串行信号输入
      .RxD_data_ready(ext_uart_ready),  // 数据接收到标�?
      .RxD_clear     (ext_uart_clear),  // 清除接收标志
      .RxD_data      (ext_uart_rx)      // 接收到的�?字节数据
  );

  assign ext_uart_clear = ext_uart_ready; // 收到数据的同时，清除标志，因为数据已取到 ext_uart_buffer �?
  always_ff @(posedge clk_50M) begin  // 接收到缓冲区 ext_uart_buffer
    if (ext_uart_ready) begin
      ext_uart_buffer <= ext_uart_rx;
      ext_uart_avai   <= 1;
    end else if (!ext_uart_busy && ext_uart_avai) begin
      ext_uart_avai <= 0;
    end
  end
  always_ff @(posedge clk_50M) begin  // 将缓冲区 ext_uart_buffer 发�?�出�?
    if (!ext_uart_busy && ext_uart_avai) begin
      ext_uart_tx <= ext_uart_buffer;
      ext_uart_start <= 1;
    end else begin
      ext_uart_start <= 0;
    end
  end

  // 发�?�模块，9600 无检验位
  async_transmitter #(
      .ClkFrequency(50000000),
      .Baud(9600)
  ) ext_uart_t (
      .clk      (clk_50M),         // 外部时钟信号
      .TxD      (txd),             // 串行信号输出
      .TxD_busy (ext_uart_busy),   // 发�?�器忙状态指�?
      .TxD_start(ext_uart_start),  // �?始发送信�?
      .TxD_data (ext_uart_tx)      // 待发送的数据
  );

  // 图像输出演示，分辨率 800x600@75Hz，像素时钟为 50MHz
  logic [11:0] hdata;
  assign video_red   = hdata < 266 ? 3'b111 : 0;  // 红色竖条
  assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0;  // 绿色竖条
  assign video_blue  = hdata >= 532 ? 2'b11 : 0;  // 蓝色竖条
  assign video_clk   = clk_50M;
  vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
      .clk        (clk_50M),
      .hdata      (hdata),        // 横坐�?
      .vdata      (),             // 纵坐�?
      .hsync      (video_hsync),
      .vsync      (video_vsync),
      .data_enable(video_de)
  );
  /* =========== Demo code end =========== */

  /* =========== Demo code begin =========== */

  // PLL 分频示例
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // 外部时钟输入
      // Clock out ports
      .clk_out1(clk_10M),  // 时钟输出 1，频率在 IP 配置界面中设�?
      .clk_out2(clk_20M),  // 时钟输出 2，频率在 IP 配置界面中设�?
      // Status and control signals
      .reset(reset_btn),  // PLL 复位输入
      .locked(locked)  // PLL 锁定指示输出�?"1"表示时钟稳定�?
                       // 后级电路复位信号应当由它生成（见下）
  );

  logic reset_of_clk10M;
  // 异步复位，同步释放，�? locked 信号转为后级电路的复�? reset_of_clk10M
  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end

  logic reset_of_clk20M;
  // 异步复位，同步释放，�? locked 信号转为后级电路的复�? reset_of_clk10M
  always_ff @(posedge clk_20M or negedge locked) begin
    if (~locked) reset_of_clk20M <= 1'b1;
    else reset_of_clk20M <= 1'b0;
  end

  /* =========== Demo code end =========== */

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_20M;
  assign sys_rst = reset_of_clk20M;

  // 本实验不使用 CPLD 串口，禁用防止�?�线冲突
  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  /* =========== Lab Controller begin =========== */
  // Lab Controller => Wishbone MUX (Slave)
  logic        wbm_cyc_o;
  logic        wbm_stb_o;
  logic        wbm_ack_i;
  logic [31:0] wbm_adr_o;
  logic [31:0] wbm_dat_o;
  logic [31:0] wbm_dat_i;
  logic [ 3:0] wbm_sel_o;
  logic        wbm_we_o;

  logic [31:0] mmu_satp;
  logic [31:0] mmu_v_addr;
  logic [31:0] mmu_wdata;
  logic [31:0] mmu_rdata;
  logic [ 3:0] mmu_sel;
  logic        mmu_ack;
  logic        mmu_load_en;
  logic        mmu_store_en;
  logic        mmu_fetch_en;
  logic        mmu_flush_en;
  logic        mmu_load_pf;
  logic        mmu_store_pf;
  logic        mmu_fetch_pf;
  logic        mmu_invalid_addr;

  logic [31:0] mmu0_v_addr;
  logic [31:0] mmu0_wdata;
  logic [31:0] mmu0_rdata;
  logic [ 3:0] mmu0_sel;
  logic        mmu0_ack;
  logic        mmu0_load_en;
  logic        mmu0_store_en;
  logic        mmu0_fetch_en;
  logic        mmu0_flush_en;
  logic        mmu0_load_pf;
  logic        mmu0_store_pf;
  logic        mmu0_fetch_pf;
  logic        mmu0_invalid_addr;

  logic [31:0] mmu1_v_addr;
  logic [31:0] mmu1_wdata;
  logic [31:0] mmu1_rdata;
  logic [ 3:0] mmu1_sel;
  logic        mmu1_ack;
  logic        mmu1_load_en;
  logic        mmu1_store_en;
  logic        mmu1_fetch_en;
  logic        mmu1_flush_en;
  logic        mmu1_load_pf;
  logic        mmu1_store_pf;
  logic        mmu1_fetch_pf;
  logic        mmu1_invalid_addr;

  logic [ 4:0] rf_raddr_a;
  logic [ 4:0] rf_raddr_b;
  logic [31:0] rf_rdata_a;
  logic [31:0] rf_rdata_b;
  logic [31:0] rf_wdata;
  logic [ 4:0] rf_waddr;
  logic        rf_wen;

  logic        exc_interrupt;
  logic [31:0] exc_csr_rdata;
  logic        exc_csr_invalid_r;
  logic        exc_csr_invalid_w;
  logic [11:0] exc_csr_raddr;
  logic [11:0] exc_csr_waddr;
  logic [31:0] exc_csr_wdata;
  logic        exc_csr_wen;
  logic        exc_exc_en;
  logic        exc_exc_ret;
  logic [31:0] exc_cur_pc;
  logic [30:0] exc_sync_exc_code;
  logic [31:0] exc_mtval;
  logic [ 1:0] exc_privilege;

  logic [31:0] exc_next_pc;
  logic [ 1:0] exc_nxt_privilege;
  logic mti_occur;
  logic mti_occur_n;

  mmu u_mmu(
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    // Content of satp register, should persist during request
    .satp_i(mmu_satp),
    .privilege_i(exc_privilege),

    // Data read and write
    .v_addr_i(mmu_v_addr),
    .data_i(mmu_wdata),
    .data_o(mmu_rdata),
    .sel_i(mmu_sel),
    .ack_o(mmu_ack),

    // Enabling signals
    .load_en_i(mmu_load_en),  // Load
    .store_en_i(mmu_store_en), // Store
    .fetch_en_i(mmu_fetch_en), // Fetch instruction
    .flush_en_i(mmu_flush_en), // Flush the TLB

    // Page faults
    .load_pf_o(mmu_load_pf),
    .store_pf_o(mmu_store_pf),
    .fetch_pf_o(mmu_fetch_pf),

    .invalid_addr_o(mmu_invalid_addr),

    // Wishbone master
    .wb_cyc_o(wbm_cyc_o),
    .wb_stb_o(wbm_stb_o),
    .wb_ack_i(wbm_ack_i),
    .wb_adr_o(wbm_adr_o),
    .wb_dat_o(wbm_dat_o),
    .wb_dat_i(wbm_dat_i),
    .wb_sel_o(wbm_sel_o),
    .wb_we_o(wbm_we_o)
  );

  mmu_arbiter_2 u_mmu_arbiter_2(
    .clk(sys_clk),
    .rst(sys_rst),

    /*
     * MMU master 0 input
     */

    // Data read and write
    .mmu0_v_addr_i(mmu0_v_addr),
    .mmu0_data_i(mmu0_wdata),
    .mmu0_data_o(mmu0_rdata),
    .mmu0_sel_i(mmu0_sel),
    .mmu0_ack_o(mmu0_ack),

    // Enabling signals
    .mmu0_load_en_i(mmu0_load_en),  // Load
    .mmu0_store_en_i(mmu0_store_en), // Store
    .mmu0_fetch_en_i(mmu0_fetch_en), // Fetch instruction
    .mmu0_flush_en_i(mmu0_flush_en), // Flush the TLB

    // Page faults
    .mmu0_load_pf_o(mmu0_load_pf),
    .mmu0_store_pf_o(mmu0_store_pf),
    .mmu0_fetch_pf_o(mmu0_fetch_pf),

    .mmu0_invalid_addr_o(mmu0_invalid_addr),

    /*
     * MMU master 1 input
     */

    // Data read and write
    .mmu1_v_addr_i(mmu1_v_addr),
    .mmu1_data_i(mmu1_wdata),
    .mmu1_data_o(mmu1_rdata),
    .mmu1_sel_i(mmu1_sel),
    .mmu1_ack_o(mmu1_ack),

    // Enabling signals
    .mmu1_load_en_i(mmu1_load_en),  // Load
    .mmu1_store_en_i(mmu1_store_en), // Store
    .mmu1_fetch_en_i(mmu1_fetch_en), // Fetch instruction
    .mmu1_flush_en_i(mmu1_flush_en), // Flush the TLB

    // Page faults
    .mmu1_load_pf_o(mmu1_load_pf),
    .mmu1_store_pf_o(mmu1_store_pf),
    .mmu1_fetch_pf_o(mmu1_fetch_pf),

    .mmu1_invalid_addr_o(mmu1_invalid_addr),

    /*
     * MMU slave output
     */

    // Data read and write
    .mmu_v_addr_o(mmu_v_addr),
    .mmu_data_o(mmu_wdata),
    .mmu_data_i(mmu_rdata),
    .mmu_sel_o(mmu_sel),
    .mmu_ack_i(mmu_ack),

    // Enabling signals
    .mmu_load_en_o(mmu_load_en),   // Load
    .mmu_store_en_o(mmu_store_en), // Store
    .mmu_fetch_en_o(mmu_fetch_en), // Fetch instruction
    .mmu_flush_en_o(mmu_flush_en), // Flush the TLB

    // Page faults
    .mmu_load_pf_i(mmu_load_pf),
    .mmu_store_pf_i(mmu_store_pf),
    .mmu_fetch_pf_i(mmu_fetch_pf),

    .mmu_invalid_addr_i(mmu_invalid_addr)
  );

  regfile u_regfile(
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    .raddr_a_i(rf_raddr_a),
    .raddr_b_i(rf_raddr_b),
    .rdata_a_o(rf_rdata_a),
    .rdata_b_o(rf_rdata_b),
    .wdata_i(rf_wdata),
    .waddr_i(rf_waddr),
    .wen_i(rf_wen)
  );

  pipeline u_pipeline(
    .clk_i(sys_clk),
    .rst_i(sys_rst),


    /* ========== MMU signals ========== */
    // .mmu_satp_o(mmu_satp),

    // MEM-stage: load/store data
    .mmu0_data_i(mmu0_rdata),
    .mmu0_ack_i(mmu0_ack),
    .mmu0_v_addr_o(mmu0_v_addr),
    .mmu0_sel_o(mmu0_sel),
    .mmu0_data_o(mmu0_wdata),

    .mmu0_load_en_o(mmu0_load_en),
    .mmu0_store_en_o(mmu0_store_en),
    .mmu0_fetch_en_o(mmu0_fetch_en),
    .mmu0_flush_en_o(mmu0_flush_en),

    .mmu0_load_pf_i(mmu0_load_pf),
    .mmu0_store_pf_i(mmu0_store_pf),
    .mmu0_fetch_pf_i(mmu0_fetch_pf),
    .mmu0_invalid_addr_i(mmu0_invalid_addr),

    // IF-stage: instruction fetch
    .mmu1_data_i(mmu1_rdata),
    .mmu1_ack_i(mmu1_ack),
    .mmu1_v_addr_o(mmu1_v_addr),
    .mmu1_sel_o(mmu1_sel),
    .mmu1_data_o(mmu1_wdata),

    .mmu1_load_en_o(mmu1_load_en),
    .mmu1_store_en_o(mmu1_store_en),
    .mmu1_fetch_en_o(mmu1_fetch_en),
    .mmu1_flush_en_o(mmu1_flush_en),

    .mmu1_load_pf_i(mmu1_load_pf),
    .mmu1_store_pf_i(mmu1_store_pf),
    .mmu1_fetch_pf_i(mmu1_fetch_pf),
    .mmu1_invalid_addr_i(mmu1_invalid_addr),

    /* ========== regfile signals ========== */
    .rf_rdata_a_i(rf_rdata_a),
    .rf_rdata_b_i(rf_rdata_b),
    .rf_raddr_a_o(rf_raddr_a),
    .rf_raddr_b_o(rf_raddr_b),
    .rf_waddr_o(rf_waddr),
    .rf_wdata_o(rf_wdata),
    .rf_wen_o(rf_wen),

    /* ========== exception unit signals ========== */
    .exc_interrupt_i(exc_interrupt),
    .exc_csr_rdata_i(exc_csr_rdata),
    .exc_csr_invalid_r_i(exc_csr_invalid_r),
    .exc_csr_invalid_w_i(exc_csr_invalid_w),
    .exc_csr_raddr_o(exc_csr_raddr),
    .exc_csr_waddr_o(exc_csr_waddr),
    .exc_csr_wdata_o(exc_csr_wdata),
    .exc_csr_wen_o(exc_csr_wen),
    .exc_exc_en_o(exc_exc_en),
    .exc_exc_ret_o(exc_exc_ret),
    .exc_cur_pc_o(exc_cur_pc),
    .exc_sync_exc_code_o(exc_sync_exc_code),
    .exc_mtval_o(exc_mtval),
    .exc_privilege_o(exc_privilege),

    .exc_next_pc_i(exc_next_pc),
    .exc_nxt_privilege_i(exc_nxt_privilege)
  );

  exc_unit u_exc_unit(
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    .exc_en_i(exc_exc_en),
    .exc_ret_i(exc_exc_ret),
    .interrupt_occur_o(exc_interrupt),
 
    .cur_pc_i(exc_cur_pc),
    .sync_exc_code_i(exc_sync_exc_code),
    .mtval_i(exc_mtval),
    .next_pc_o(exc_next_pc),

    .privilege_i(exc_privilege),
    .nxt_privilege_o(exc_nxt_privilege),
 
    .satp_o(mmu_satp),
    .mtip_set_en_i(mti_occur),
    .mtip_clear_en_i(mti_occur_n),
 
    .csr_raddr_i(exc_csr_raddr),
    .csr_rdata_o(exc_csr_rdata),
    .csr_waddr_i(exc_csr_waddr),
    .csr_wdata_i(exc_csr_wdata),
    .csr_we_i(exc_csr_wen),
    .invalid_r_o(exc_csr_invalid_r),
    .invalid_w_o(exc_csr_invalid_w)
  );

  /* =========== Lab Controller end =========== */

  /* =========== Wishbone MUX begin =========== */
  // Wishbone MUX (Masters) => bus slaves

  // for baseram
  logic wbs0_cyc_o;
  logic wbs0_stb_o;
  logic wbs0_ack_i;
  logic [31:0] wbs0_adr_o;
  logic [31:0] wbs0_dat_o;
  logic [31:0] wbs0_dat_i;
  logic [3:0] wbs0_sel_o;
  logic wbs0_we_o;

  // for extraram
  logic wbs1_cyc_o;
  logic wbs1_stb_o;
  logic wbs1_ack_i;
  logic [31:0] wbs1_adr_o;
  logic [31:0] wbs1_dat_o;
  logic [31:0] wbs1_dat_i;
  logic [3:0] wbs1_sel_o;
  logic wbs1_we_o;

  // for uart
  logic wbs2_cyc_o;
  logic wbs2_stb_o;
  logic wbs2_ack_i;
  logic [31:0] wbs2_adr_o;
  logic [31:0] wbs2_dat_o;
  logic [31:0] wbs2_dat_i;
  logic [3:0] wbs2_sel_o;
  logic wbs2_we_o;

  // for blockram 0
  logic wbs3_cyc_o;
  logic wbs3_stb_o;
  logic wbs3_ack_i;
  logic [31:0] wbs3_adr_o;
  logic [31:0] wbs3_dat_o;
  logic [31:0] wbs3_dat_i;
  logic [3:0] wbs3_sel_o;
  logic wbs3_we_o;

  // for flash
  logic wbs4_cyc_o;
  logic wbs4_stb_o;
  logic wbs4_ack_i;
  logic [31:0] wbs4_adr_o;
  logic [31:0] wbs4_dat_o;
  logic [31:0] wbs4_dat_i;
  logic [3:0] wbs4_sel_o;
  logic wbs4_we_o;

  // for blockram 1
  logic wbs5_cyc_o;
  logic wbs5_stb_o;
  logic wbs5_ack_i;
  logic [31:0] wbs5_adr_o;
  logic [31:0] wbs5_dat_o;
  logic [31:0] wbs5_dat_i;
  logic [3:0] wbs5_sel_o;
  logic wbs5_we_o;

  // for GPIO
  logic wbs6_cyc_o;
  logic wbs6_stb_o;
  logic wbs6_ack_i;
  logic [31:0] wbs6_adr_o;
  logic [31:0] wbs6_dat_o;
  logic [31:0] wbs6_dat_i;
  logic [3:0] wbs6_sel_o;
  logic wbs6_we_o;

  // for vgacashe
  logic wbs7_cyc_o;
  logic wbs7_stb_o;
  logic wbs7_ack_i;
  logic [31:0] wbs7_adr_o;
  logic [31:0] wbs7_dat_o;
  logic [31:0] wbs7_dat_i;
  logic [3:0] wbs7_sel_o;
  logic wbs7_we_o;

  // for CSR mtime, mtimecmp
  logic wbs8_cyc_o;
  logic wbs8_stb_o;
  logic wbs8_ack_i;
  logic [31:0] wbs8_adr_o;
  logic [31:0] wbs8_dat_o;
  logic [31:0] wbs8_dat_i;
  logic [3:0] wbs8_sel_o;
  logic wbs8_we_o;

  wb_mux_9 wb_mux (
      .clk(sys_clk),
      .rst(sys_rst),

      // Master interface (to Lab5 master)
      .wbm_adr_i(wbm_adr_o),
      .wbm_dat_i(wbm_dat_o),
      .wbm_dat_o(wbm_dat_i),
      .wbm_we_i (wbm_we_o),
      .wbm_sel_i(wbm_sel_o),
      .wbm_stb_i(wbm_stb_o),
      .wbm_ack_o(wbm_ack_i),
      .wbm_err_o(),
      .wbm_rty_o(),
      .wbm_cyc_i(wbm_cyc_o),

      // Slave interface 0 (to BaseRAM controller)
      // Address range: 0x8000_0000 ~ 0x803F_FFFF
      .wbs0_addr    (32'h8000_0000),
      .wbs0_addr_msk(32'hFFC0_0000),

      .wbs0_adr_o(wbs0_adr_o),
      .wbs0_dat_i(wbs0_dat_i),
      .wbs0_dat_o(wbs0_dat_o),
      .wbs0_we_o (wbs0_we_o),
      .wbs0_sel_o(wbs0_sel_o),
      .wbs0_stb_o(wbs0_stb_o),
      .wbs0_ack_i(wbs0_ack_i),
      .wbs0_err_i('0),
      .wbs0_rty_i('0),
      .wbs0_cyc_o(wbs0_cyc_o),

      // Slave interface 1 (to ExtRAM controller)
      // Address range: 0x8040_0000 ~ 0x807F_FFFF
      .wbs1_addr    (32'h8040_0000),
      .wbs1_addr_msk(32'hFFC0_0000),

      .wbs1_adr_o(wbs1_adr_o),
      .wbs1_dat_i(wbs1_dat_i),
      .wbs1_dat_o(wbs1_dat_o),
      .wbs1_we_o (wbs1_we_o),
      .wbs1_sel_o(wbs1_sel_o),
      .wbs1_stb_o(wbs1_stb_o),
      .wbs1_ack_i(wbs1_ack_i),
      .wbs1_err_i('0),
      .wbs1_rty_i('0),
      .wbs1_cyc_o(wbs1_cyc_o),

      // Slave interface 2 (to UART controller)
      // Address range: 0x1000_0000 ~ 0x1000_FFFF
      .wbs2_addr    (32'h1000_0000),
      .wbs2_addr_msk(32'hFFFF_0000),

      .wbs2_adr_o(wbs2_adr_o),
      .wbs2_dat_i(wbs2_dat_i),
      .wbs2_dat_o(wbs2_dat_o),
      .wbs2_we_o (wbs2_we_o),
      .wbs2_sel_o(wbs2_sel_o),
      .wbs2_stb_o(wbs2_stb_o),
      .wbs2_ack_i(wbs2_ack_i),
      .wbs2_err_i('0),
      .wbs2_rty_i('0),
      .wbs2_cyc_o(wbs2_cyc_o),

      // Slave interface 3 (to block ram 0)
      // Address range: 0x8100_0000 ~ 0x81FF_FFFF
      .wbs3_addr    (32'h8100_0000),
      .wbs3_addr_msk(32'hFF00_0000),

      .wbs3_adr_o(wbs3_adr_o),
      .wbs3_dat_i(wbs3_dat_i),
      .wbs3_dat_o(wbs3_dat_o),
      .wbs3_we_o (wbs3_we_o),
      .wbs3_sel_o(wbs3_sel_o),
      .wbs3_stb_o(wbs3_stb_o),
      .wbs3_ack_i(wbs3_ack_i),
      .wbs3_err_i('0),
      .wbs3_rty_i('0),
      .wbs3_cyc_o(wbs3_cyc_o),

      // Slave interface 4 (to flash)
      // Address range: 0x8300_0000 ~ 0x83FF_FFFF
      .wbs4_addr    (32'h8300_0000),
      .wbs4_addr_msk(32'hFF00_0000),

      .wbs4_adr_o(wbs4_adr_o),
      .wbs4_dat_i(wbs4_dat_i),
      .wbs4_dat_o(wbs4_dat_o),
      .wbs4_we_o (wbs4_we_o),
      .wbs4_sel_o(wbs4_sel_o),
      .wbs4_stb_o(wbs4_stb_o),
      .wbs4_ack_i(wbs4_ack_i),
      .wbs4_err_i('0),
      .wbs4_rty_i('0),
      .wbs4_cyc_o(wbs4_cyc_o),

      // Slave interface 5 (to block ram 1)
      // Address range: 0x8400_0000 ~ 0x84FF_FFFF
      .wbs5_addr    (32'h8400_0000),
      .wbs5_addr_msk(32'hFF00_0000),

      .wbs5_adr_o(wbs5_adr_o),
      .wbs5_dat_i(wbs5_dat_i),
      .wbs5_dat_o(wbs5_dat_o),
      .wbs5_we_o (wbs5_we_o),
      .wbs5_sel_o(wbs5_sel_o),
      .wbs5_stb_o(wbs5_stb_o),
      .wbs5_ack_i(wbs5_ack_i),
      .wbs5_err_i('0),
      .wbs5_rty_i('0),
      .wbs5_cyc_o(wbs5_cyc_o), 
  
      // Slave interface 6 (to gpio)
      // Address range: 0x8500_0000 ~ 0x85FF_FFFF
      .wbs6_addr    (32'h8500_0000),
      .wbs6_addr_msk(32'hFF00_0000),

      .wbs6_adr_o(wbs6_adr_o),
      .wbs6_dat_i(wbs6_dat_i),
      .wbs6_dat_o(wbs6_dat_o),
      .wbs6_we_o (wbs6_we_o),
      .wbs6_sel_o(wbs6_sel_o),
      .wbs6_stb_o(wbs6_stb_o),
      .wbs6_ack_i(wbs6_ack_i),
      .wbs6_err_i('0),
      .wbs6_rty_i('0),
      .wbs6_cyc_o(wbs6_cyc_o), 
  
      // Slave interface 7 (to vgacache register)
      // Address range: 0x8600_0000 ~ 0x86FF_FFFF
      .wbs7_addr    (32'h8600_0000),
      .wbs7_addr_msk(32'hFF00_0000),

      .wbs7_adr_o(wbs7_adr_o),
      .wbs7_dat_i(wbs7_dat_i),
      .wbs7_dat_o(wbs7_dat_o),
      .wbs7_we_o (wbs7_we_o),
      .wbs7_sel_o(wbs7_sel_o),
      .wbs7_stb_o(wbs7_stb_o),
      .wbs7_ack_i(wbs7_ack_i),
      .wbs7_err_i('0),
      .wbs7_rty_i('0),
      .wbs7_cyc_o(wbs7_cyc_o),

      // Slave interface 3 (to Memory-mapped CSRs)
      .wbs8_addr    (32'h0200_0000),
      .wbs8_addr_msk(32'h03ff_0000),

      .wbs8_adr_o(wbs8_adr_o),
      .wbs8_dat_i(wbs8_dat_i),
      .wbs8_dat_o(wbs8_dat_o),
      .wbs8_we_o (wbs8_we_o),
      .wbs8_sel_o(wbs8_sel_o),
      .wbs8_stb_o(wbs8_stb_o),
      .wbs8_ack_i(wbs8_ack_i),
      .wbs8_err_i('0),
      .wbs8_rty_i('0),
      .wbs8_cyc_o(wbs8_cyc_o)
  );

  /* =========== Wishbone MUX end =========== */

  /* =========== Wishbone Slaves begin =========== */
  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_base (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs0_cyc_o),
      .wb_stb_i(wbs0_stb_o),
      .wb_ack_o(wbs0_ack_i),
      .wb_adr_i(wbs0_adr_o),
      .wb_dat_i(wbs0_dat_o),
      .wb_dat_o(wbs0_dat_i),
      .wb_sel_i(wbs0_sel_o),
      .wb_we_i (wbs0_we_o),

      // To SRAM chip
      .sram_addr(base_ram_addr),
      .sram_data(base_ram_data),
      .sram_ce_n(base_ram_ce_n),
      .sram_oe_n(base_ram_oe_n),
      .sram_we_n(base_ram_we_n),
      .sram_be_n(base_ram_be_n)
  );

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_ext (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs1_cyc_o),
      .wb_stb_i(wbs1_stb_o),
      .wb_ack_o(wbs1_ack_i),
      .wb_adr_i(wbs1_adr_o),
      .wb_dat_i(wbs1_dat_o),
      .wb_dat_o(wbs1_dat_i),
      .wb_sel_i(wbs1_sel_o),
      .wb_we_i (wbs1_we_o),

      // To SRAM chip
      .sram_addr(ext_ram_addr),
      .sram_data(ext_ram_data),
      .sram_ce_n(ext_ram_ce_n),
      .sram_oe_n(ext_ram_oe_n),
      .sram_we_n(ext_ram_we_n),
      .sram_be_n(ext_ram_be_n)
  );

  // 串口控制器模�?
  // NOTE: 如果修改系统时钟频率，也�?要修改此处的时钟频率参数
  uart_controller #(
      .CLK_FREQ(20_000_000),
      .BAUD    (115200)
  ) uart_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .wb_cyc_i(wbs2_cyc_o),
      .wb_stb_i(wbs2_stb_o),
      .wb_ack_o(wbs2_ack_i),
      .wb_adr_i(wbs2_adr_o),
      .wb_dat_i(wbs2_dat_o),
      .wb_dat_o(wbs2_dat_i),
      .wb_sel_i(wbs2_sel_o),
      .wb_we_i (wbs2_we_o),

      // to UART pins
      .uart_txd_o(txd),
      .uart_rxd_i(rxd)
  );

  // Memory-mapped CSRs
  csr_mtime u_csr_mtime(
    .clk_i(sys_clk),
    .rst_i(sys_rst),

    .wb_cyc_i(wbs8_cyc_o),
    .wb_stb_i(wbs8_stb_o),
    .wb_ack_o(wbs8_ack_i),
    .wb_adr_i(wbs8_adr_o),
    .wb_dat_i(wbs8_dat_o),
    .wb_dat_o(wbs8_dat_i),
    .wb_sel_i(wbs8_sel_o),
    .wb_we_i (wbs8_we_o),

    // machine timer interrupt signals to the CPU
    .mti_occur_o(mti_occur),
    .mti_occur_n_o(mti_occur_n)
  );

  // blockram_0 控制信号
  logic [7:0] bram_0_rdata;
  logic [7:0] bram_0_wdata;
  logic [16:0] bram_0_raddr;
  logic [16:0] bram_0_waddr;
  logic bram_0_wea;
  logic bram_0_ena;

  // blockram_1 控制信号
  logic [7:0] bram_1_rdata;
  logic [7:0] bram_1_wdata;
  logic [16:0] bram_1_raddr;
  logic [16:0] bram_1_waddr;
  logic bram_1_wea;
  logic bram_1_ena;


  // block RAM 控制器模�?
  bram_controller #(
      .WISHBONE_DATA_WIDTH(32),
      .WISHBONE_ADDR_WIDTH(32),

      .BRAM_DATA_WIDTH(8),
      .BRAM_ADDR_WIDTH(17)
  ) bram_controller_0 (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs3_cyc_o),
      .wb_stb_i(wbs3_stb_o),
      .wb_ack_o(wbs3_ack_i),
      .wb_adr_i(wbs3_adr_o),
      .wb_dat_i(wbs3_dat_o),
      .wb_dat_o(wbs3_dat_i),
      .wb_sel_i(wbs3_sel_o),
      .wb_we_i (wbs3_we_o),

      // To BRAM chip
      .bram_data_i(bram_0_rdata),
      .bram_data_o(bram_0_wdata),
      .bram_addr_a_o(bram_0_waddr),
      .bram_addr_b_o(bram_0_raddr),
      .bram_wea_o(bram_0_wea)
  );

  // block RAM 控制器模
  bram_controller #(
      .WISHBONE_DATA_WIDTH(32),
      .WISHBONE_ADDR_WIDTH(32),

      .BRAM_DATA_WIDTH(8),
      .BRAM_ADDR_WIDTH(17)
  ) bram_controller_1 (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs5_cyc_o),
      .wb_stb_i(wbs5_stb_o),
      .wb_ack_o(wbs5_ack_i),
      .wb_adr_i(wbs5_adr_o),
      .wb_dat_i(wbs5_dat_o),
      .wb_dat_o(wbs5_dat_i),
      .wb_sel_i(wbs5_sel_o),
      .wb_we_i (wbs5_we_o),

      // To BRAM chip
      .bram_data_i(bram_1_rdata),
      .bram_data_o(bram_1_wdata),
      .bram_addr_a_o(bram_1_waddr),
      .bram_addr_b_o(bram_1_raddr),
      .bram_wea_o(bram_1_wea)
  );

  // flash 控制信号
  assign flash_vpen = 1'b1;
  assign flash_we_n = 1'b1;
  assign flash_byte_n = 1'b0;
  
  flash_controller #(
      .WISHBONE_DATA_WIDTH(32),
      .WISHBONE_ADDR_WIDTH(32),

      .FLASH_DATA_WIDTH(8),
      .FLASH_ADDR_WIDTH(23)
  ) flash_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs4_cyc_o),
      .wb_stb_i(wbs4_stb_o),
      .wb_ack_o(wbs4_ack_i),
      .wb_adr_i(wbs4_adr_o),
      .wb_dat_i(wbs4_dat_o),
      .wb_dat_o(wbs4_dat_i),
      .wb_sel_i(wbs4_sel_o),
      .wb_we_i (wbs4_we_o),

      // To flash chip
      .flash_a_o(flash_a),
      .flash_d(flash_d),
      .flash_rp_o(flash_rp_n),
      .flash_ce_o(flash_ce_n),
      .flash_oe_o(flash_oe_n)
  );

  // GPIO 控制信号
  gpio_controller #(
      .WISHBONE_DATA_WIDTH(32),
      .WISHBONE_ADDR_WIDTH(32)
  ) gpio_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs6_cyc_o),
      .wb_stb_i(wbs6_stb_o),
      .wb_ack_o(wbs6_ack_i),
      .wb_adr_i(wbs6_adr_o),
      .wb_dat_i(wbs6_dat_o),
      .wb_dat_o(wbs6_dat_i),
      .wb_sel_i(wbs6_sel_o),
      .wb_we_i (wbs6_we_o),

      // To GPIO chip
      .dip_sw(dip_sw),
      .touch_btn(touch_btn),
      .push_btn(push_btn)
  );


  /* =========== Wishbone Slaves end =========== */

  /* =========== VGA begin =========== */
  // 图像输出演示，分辨率 800x600@75Hz，像素时钟为 50MHz
  logic [11:0] hdata;
  logic [11:0] vdata;
  logic [ 7:0] rdata;
  logic [7:0] pixel;
  logic vga_de;
  // 图片的放大�?�数，默认为 2^3 �?
  logic vga_end;
  logic [2:0] vga_scale;     
  logic [16:0] bram_addr_st = 17'b0;

  // block ram 信号，目前的数据宽度�? 8bit，地�?宽度�? 19bit
  logic bram_ena_i = 1'b1;
  logic bram_enb_i  = 1'b1;
  logic bram_wea_i = 4'b0000;
  logic [16:0] bram_addra_i = 19'b0;
  logic [7:0] bram_data_i = 32'b0;
  logic [16:0] bram_addrb_i;

  // 不同 block ram 的数据读取
  logic [7:0] bram_0_data_o;
  logic [7:0] bram_1_data_o;
  logic [7:0] real_bram_data;



  assign video_red   = pixel[7:5];  // 红色
  assign video_green = pixel[4:2];  // 绿色
  assign video_blue  = pixel[1:0];  // 蓝色
  assign video_clk   = clk_50M;
  assign vga_de = video_de;


  vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
      .clk        (clk_50M),
      .hdata      (hdata),             // 横向周期计数
      .vdata      (vdata),             // 纵向周期计数
      .hsync      (video_hsync),
      .vsync      (video_vsync),
      .data_enable(video_de)
  );

  vga_selector #(
      .WISHBONE_DATA_WIDTH(32),
      .WISHBONE_ADDR_WIDTH(32)
  ) vga_selector (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs7_cyc_o),
      .wb_stb_i(wbs7_stb_o),
      .wb_ack_o(wbs7_ack_i),
      .wb_adr_i(wbs7_adr_o),
      .wb_dat_i(wbs7_dat_o),
      .wb_dat_o(wbs7_dat_i),
      .wb_sel_i(wbs7_sel_o),
      .wb_we_i (wbs7_we_o),

      // vga interface
      .vga_scale(vga_scale),
      .vga_end(vga_end),

      // bram read interface
      .bram_0_data(bram_0_data_o),
      .bram_1_data(bram_1_data_o),
      .real_bram_data(real_bram_data)
  );


  vga_pic #(12, 800, 600, 1040, 666, 17) pic (
      .vga_clk    (clk_50M),
      .hdata      (hdata),
      .vdata      (vdata),
      .vga_scale  (vga_scale),
      .pixel      (pixel),
      .r_addr_st  (bram_addr_st),
      .r_addr     (bram_addrb_i),
      .r_data     (real_bram_data),
      .vga_end    (vga_end)
  );

  pic_bram pic_mem_0 (
    .clka         (sys_clk),
    .ena          (bram_ena_i),
    .wea          (bram_0_wea),
    .addra        (bram_0_waddr),
    .dina         (bram_0_wdata),
    .clkb         (clk_50M),
    .enb          (bram_enb_i),
    .addrb        (bram_addrb_i),
    .doutb        (bram_0_data_o)
  );

  pic_mem_1 pic_mem_1 (
    .clka         (sys_clk),
    .ena          (bram_ena_i),
    .wea          (bram_1_wea),
    .addra        (bram_1_waddr),
    .dina         (bram_1_wdata),
    .clkb         (clk_50M),
    .enb          (bram_enb_i),
    .addrb        (bram_addrb_i),
    .doutb        (bram_1_data_o)
  );

  /* =========== VGA end =========== */
  

endmodule
