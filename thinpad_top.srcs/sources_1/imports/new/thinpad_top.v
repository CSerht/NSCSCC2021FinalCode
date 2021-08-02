`default_nettype none

module thinpad_top(
           input wire clk_50M,           //50MHz 时钟输入
           input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

           input wire clock_btn,         //BTN5手动时钟按钮�?关，带消抖电路，按下时为1
           input wire reset_btn,         //BTN6手动复位按钮�?关，带消抖电路，按下时为1

           input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
           input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时�?1
           output wire[15:0] leds,       //16位LED，输出时1点亮
           output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
           output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

           //BaseRAM信号
           inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共�?
           (*mark_debug = "true"*)output wire[19:0] base_ram_addr, //BaseRAM地址
           (*mark_debug = "true"*)output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持�?0
           output wire base_ram_ce_n,       //BaseRAM片�?�，低有�?
           (*mark_debug = "true"*)output wire base_ram_oe_n,       //BaseRAM读使能，低有�?
           (*mark_debug = "true"*)output wire base_ram_we_n,       //BaseRAM写使能，低有�?

           //ExtRAM信号
           inout wire[31:0] ext_ram_data,  //ExtRAM数据
           (*mark_debug = "true"*)output wire[19:0] ext_ram_addr, //ExtRAM地址
           (*mark_debug = "true"*)output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持�?0
           output wire ext_ram_ce_n,       //ExtRAM片�?�，低有�?
           (*mark_debug = "true"*)output wire ext_ram_oe_n,       //ExtRAM读使能，低有�?
           (*mark_debug = "true"*)output wire ext_ram_we_n,       //ExtRAM写使能，低有�?

           //直连串口信号
           output wire txd,  //直连串口发�?�端
           input  wire rxd,  //直连串口接收�?

           //Flash存储器信号，参�?? JS28F640 芯片手册
           output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效�?16bit模式无意�?
           inout  wire [15:0]flash_d,      //Flash数据
           output wire flash_rp_n,         //Flash复位信号，低有效
           output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧�?
           output wire flash_ce_n,         //Flash片�?�信号，低有�?
           output wire flash_oe_n,         //Flash读使能信号，低有�?
           output wire flash_we_n,         //Flash写使能信号，低有�?
           output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash�?16位模式时请设�?1

           //图像输出信号
           output wire[2:0] video_red,    //红色像素�?3�?
           output wire[2:0] video_green,  //绿色像素�?3�?
           output wire[1:0] video_blue,   //蓝色像素�?2�?
           output wire video_hsync,       //行同步（水平同步）信�?
           output wire video_vsync,       //场同步（垂直同步）信�?
           output wire video_clk,         //像素时钟输出
           output wire video_de           //行数据有效信号，用于区分消隐�?
       );

/* =========== Demo code begin =========== */

// PLL分频示例
// wire locked, clk_10M, clk_20M;
wire locked;
wire clk_51M;
wire clk_50M_test;
pll_example clock_gen
            (
                // Clock in ports
                .clk_in1(clk_50M),  // 外部时钟输入
                // Clock out ports
                .clk_out1(clk_51M), // 时钟输出1，频率在IP配置界面中设�?
                .clk_out2(clk_50M_test), // 时钟输出2，频率在IP配置界面中设�?
                // Status and control signals
                .reset(reset_btn), // PLL复位输入
                .locked(locked)    // PLL锁定指示输出�?"1"表示时钟稳定�?
                // 后级电路复位信号应当由它生成（见下）
            );

reg reset_of_clk51M;
// 异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
always@(posedge clk_51M or negedge locked)
begin
    if(~locked)
        reset_of_clk51M <= 1'b1;
    else
        reset_of_clk51M <= 1'b0;
end

// always@(posedge clk_10M or posedge reset_of_clk10M)
// begin
//     if(reset_of_clk10M)
//     begin
//         // Your Code
//     end
//     else
//     begin
//         // Your Code
//     end
// end

// // 不使用内存�?�串口时，禁用其使能信号
// assign base_ram_ce_n = 1'b1;
// assign base_ram_oe_n = 1'b1;
// assign base_ram_we_n = 1'b1;

// assign ext_ram_ce_n = 1'b1;
// assign ext_ram_oe_n = 1'b1;
// assign ext_ram_we_n = 1'b1;

/****************************************************/
// 以下内容为自定义内容
/****************************************************/


//////////////////////////////////////////
///////////     CPU kernel     ///////////
//////////////////////////////////////////

// input
wire clk;
wire rst_n;
// assign clk = clk_50M;
// assign rst_n = reset_btn;

assign clk = clk_51M;
assign rst_n = reset_of_clk51M;

wire [31:0] inst_i;
wire [31:0] data_i;


wire baseram_busy_i_cpu;
wire inst_r_finish_i_cpu;
wire baseram_w_finish_i_cpu;

wire ram_busy_i_cpu;
wire data_r_finish_i_cpu;
wire data_w_finish_i_cpu;


// output
wire [31:0] pc_o_cpu;
wire [31:0] inst_o_cpu;
wire inst_w_o_cpu;
wire inst_r_o_cpu;
wire inst_ce_o_cpu;
wire [31:0] data_o_cpu;
wire [31:0] data_addr_o_cpu;
wire data_w_o_cpu;
wire data_r_o_cpu;
wire [1:0] mode_o_cpu;
wire data_ce_o_cpu;


my_cpu  u_my_cpu (
            .clk                     ( clk           ),
            .rst_n                   ( rst_n         ),
            .inst_i                  ( inst_i        ),
            .data_i                  ( data_i        ),

            .baseram_busy_i          ( baseram_busy_i_cpu    ),
            .inst_r_finish_i         ( inst_r_finish_i_cpu   ),
            .baseram_w_finish_i      ( baseram_w_finish_i_cpu   ),


            .ram_busy_i              ( ram_busy_i_cpu        ),
            .data_r_finish_i         ( data_r_finish_i_cpu   ),
            .data_w_finish_i         ( data_w_finish_i_cpu   ),

            .pc_o                    ( pc_o_cpu        ),
            .inst_o                  ( inst_o_cpu      ),
            .inst_w_o                ( inst_w_o_cpu    ),
            .inst_r_o                ( inst_r_o_cpu    ),
            .inst_ce_o               ( inst_ce_o_cpu   ),

            .data_o                  ( data_o_cpu      ),
            .data_addr_o             ( data_addr_o_cpu ),
            .data_w_o                ( data_w_o_cpu    ),
            .data_r_o                ( data_r_o_cpu    ),
            .mode_o                  ( mode_o_cpu      ),
            .data_ce_o               ( data_ce_o_cpu   )
        );


//////////////////////////////////////////
//////////      arbitration     //////////
//////////////////////////////////////////

// input
/// cpu
//// ext data ram
wire [1:0] mode_i;
wire data_w_i;
wire data_r_i;
wire data_ce_i;
wire [31:0] data_addr_i;
wire [31:0] data_i_arbit;


assign mode_i = mode_o_cpu;
assign data_w_i = data_w_o_cpu;
assign data_r_i = data_r_o_cpu;
assign data_ce_i = data_ce_o_cpu;
assign data_addr_i = data_addr_o_cpu;
assign data_i_arbit = data_o_cpu;

//// base inst ram
wire [0:0] inst_w_i;
wire [0:0] inst_r_i;
wire [0:0] inst_ce_i;
wire [31:0] pc_i;
wire [31:0] inst_i_arbit;

assign inst_w_i = inst_w_o_cpu;
assign inst_r_i = inst_r_o_cpu;
assign inst_ce_i = inst_ce_o_cpu;
assign pc_i = pc_o_cpu;
assign inst_i_arbit = inst_o_cpu;

//**************************
/// ext RAM
wire [31:0] ext_data_i;

wire extram_busy_i;
wire extdata_r_finish_i;
wire extdata_w_finish_i;

/// Serial port memory
wire [31:0] uart_data_i;

/// base inst ram
wire [31:0] base_data_i;

wire baseram_busy_i_arb;
wire inst_r_finish_i_arb;
wire inst_w_finish_i_arb;

// wire baseram_w_finish_i_arb;

//////////////////////////////////////////////////
// output
wire [31:0] data_addr_o;

/// cpu
//// ext data RAM
wire [31:0] data_o_arbit;
assign data_i = data_o_arbit;

wire ram_busy_o_arb;
wire data_r_finish_o_arb;
wire data_w_finish_o_arb;

//// base inst RAM
wire [31:0] inst_o_arbit;
assign inst_i = inst_o_arbit;

//**************************
/// ext RAM
wire [31:0] ext_data_o;
wire ext_data_w_o;
wire ext_data_r_o;
// wire [1:0] ext_mode_o;
wire [3:0] ext_data_be_o;

wire ext_data_ce_o;




/// Serial port memory
wire uart_data_r_o;
wire uart_data_w_o;
wire [31:0] uart_data_o;

/// base inst ram
wire [31:0] base_addr_o;
wire [31:0] base_data_o;
wire base_data_w_o;
wire base_data_r_o;

wire baseram_busy_o_arb;
wire inst_r_finish_o_arb;

wire baseram_w_finish_o_arb;

wire is_read_data_o;

// wire [1:0] base_mode_o;
wire [3:0] base_data_be_o;

wire base_data_ce_o;

arbitration  u_arbitration (
                 .rst_n                   ( rst_n            ),
                 // connect with CPU
                 /// ext data ram
                 .mode_i                  ( mode_i          ),
                 .data_w_i                ( data_w_i        ),
                 .data_r_i                ( data_r_i        ),
                 .data_ce_i               ( data_ce_i       ),
                 .data_addr_i             ( data_addr_i     ),
                 .data_i                  ( data_i_arbit    ),

                 .data_o                  ( data_o_arbit    ),

                 .ram_busy_o              ( ram_busy_o_arb      ),
                 .data_r_finish_o         ( data_r_finish_o_arb ),
                 .data_w_finish_o         ( data_w_finish_o_arb ),

                 /// base inst ram
                 .pc_i                    ( pc_i             ),
                 .inst_w_i                ( inst_w_i         ),
                 .inst_r_i                ( inst_r_i         ),
                 .inst_ce_i               ( inst_ce_i        ),
                 .inst_i                  ( inst_i_arbit     ),

                 .inst_o                  ( inst_o_arbit     ),

                 .baseram_busy_o          ( baseram_busy_o_arb   ),
                 .inst_r_finish_o         ( inst_r_finish_o_arb  ),
                 .baseram_w_finish_o      ( baseram_w_finish_o_arb ),

                 // extRAM and serialMemory 共用
                 .data_addr_o             ( data_addr_o     ),

                 // ext RAM
                 .extram_busy_i           ( extram_busy_i        ),
                 .extdata_r_finish_i      ( extdata_r_finish_i   ),
                 .extdata_w_finish_i      ( extdata_w_finish_i   ),


                 .ext_data_i              ( ext_data_i      ),

                 .ext_data_o              ( ext_data_o      ),
                 .ext_data_w_o            ( ext_data_w_o    ),
                 .ext_data_r_o            ( ext_data_r_o    ),
                 //  .ext_mode_o              ( ext_mode_o      ),
                 .ext_data_be_o           ( ext_data_be_o    ),

                 .ext_data_ce_o           ( ext_data_ce_o   ),

                 // serial port
                 .uart_data_i             ( uart_data_i     ),

                 .uart_data_r_o           ( uart_data_r_o   ),
                 .uart_data_w_o           ( uart_data_w_o   ),
                 .uart_data_o             ( uart_data_o     ),

                 // base inst ram
                 .baseram_busy_i          ( baseram_busy_i_arb       ),
                 .inst_r_finish_i         ( inst_r_finish_i_arb      ),
                 .inst_w_finish_i         ( inst_w_finish_i_arb      ),
                 //  .baseram_w_finish_i      ( baseram_w_finish_i_arb ),

                 .base_data_i             ( base_data_i      ),

                 .is_read_data_o          ( is_read_data_o   ),

                 .base_addr_o             ( base_addr_o      ),
                 .base_data_o             ( base_data_o      ),
                 .base_data_w_o           ( base_data_w_o    ),
                 .base_data_r_o           ( base_data_r_o    ),
                 //  .base_mode_o             ( base_mode_o      ),
                 .base_data_be_o          ( base_data_be_o   ),

                 .base_data_ce_o          ( base_data_ce_o   )
             );




assign baseram_busy_i_cpu  = baseram_busy_o_arb;
assign inst_r_finish_i_cpu = inst_r_finish_o_arb;
assign baseram_w_finish_i_cpu = baseram_w_finish_o_arb;

assign ram_busy_i_cpu      = ram_busy_o_arb;
assign data_r_finish_i_cpu = data_r_finish_o_arb;
assign data_w_finish_i_cpu = data_w_finish_o_arb;


//////////////////////////////////////////
//////////     ext data mem     //////////
//////////////////////////////////////////

// input
// wire [1:0] ext_mode_i;
wire [3:0] data_sel_i;

wire ext_data_w_i;
wire ext_data_r_i;
wire ext_data_ce_i;
wire [31:0] ext_data_addr_i;
wire [31:0] ext_data_from_arbit;


// assign ext_mode_i          = ext_mode_o;
assign data_sel_i = ext_data_be_o;

assign ext_data_w_i        = ext_data_w_o;
assign ext_data_r_i        = ext_data_r_o;
assign ext_data_ce_i       = ext_data_ce_o;
assign ext_data_addr_i     = data_addr_o;
assign ext_data_from_arbit = ext_data_o;

// output
wire [31:0] data_o_to_arbit;

assign ext_data_i = data_o_to_arbit;


wire extram__busy_o;
wire extdata_r_finish_o;
wire extdata_w_finish_o;

sram_ctl  u_ext_ram_ctl (
              .clk                      ( clk                 ),
              .rst_n                    ( rst_n               ),
              //  .mode_i                   ( ext_mode_i           ),
              .data_sel_i               ( data_sel_i           ),

              .data_w_i                 ( ext_data_w_i         ),
              .data_r_i                 ( ext_data_r_i         ),
              .data_ce_i                ( ext_data_ce_i        ),
              .data_addr_i              ( ext_data_addr_i      ),
              .data_i                   ( ext_data_from_arbit  ),



              .data_o                   ( data_o_to_arbit      ),

              .sram_ctl_busy_o         ( extram__busy_o        ),
              .data_r_finish_o         ( extdata_r_finish_o    ),
              .data_w_finish_o         ( extdata_w_finish_o    ),

              // ext data ram
              .sram_addr             ( ext_ram_addr     ),
              .sram_be_n             ( ext_ram_be_n     ),
              .sram_ce_n             ( ext_ram_ce_n     ),
              .sram_oe_n             ( ext_ram_oe_n     ),
              .sram_we_n             ( ext_ram_we_n     ),

              .sram_data             ( ext_ram_data     )
          );

assign extram_busy_i      = extram__busy_o;
assign extdata_r_finish_i = extdata_r_finish_o;
assign extdata_w_finish_i = extdata_w_finish_o;

//////////////////////////////////////////
//////////    base inst mem     //////////
//////////////////////////////////////////

// input
// wire [1:0] base_mode_i;
wire [3:0] inst_data_sel_i;

wire base_inst_w_i;
wire base_inst_r_i;
wire base_inst_ce_i;
wire [31:0] base_pc_i;
wire [31:0] base_inst_i;

// assign base_mode_i = base_mode_o;
assign inst_data_sel_i = base_data_be_o;

assign base_inst_w_i = base_data_w_o;
assign base_inst_r_i = base_data_r_o;
assign base_inst_ce_i = base_data_ce_o;
assign base_pc_i = base_addr_o;
assign base_inst_i = base_data_o;

wire is_read_data_i;
assign is_read_data_i = is_read_data_o;

// output
wire [31:0] base_inst_o;
assign base_data_i = base_inst_o;

wire baseram_busy_o_base;
wire inst_r_finish_o_base;
wire inst_w_finish_o_base;

base_ram_ctl  u_base_ram_ctl (
                  .clk                          ( clk              ),
                  .rst_n                        ( rst_n            ),

                  //   .base_mode_i                  ( base_mode_i      ),
                  .data_sel_i              ( inst_data_sel_i  ),

                  .data_w_i                     ( base_inst_w_i    ),
                  .data_r_i                     ( base_inst_r_i    ),
                  .data_ce_i                    ( base_inst_ce_i   ),
                  .data_addr_i                  ( base_pc_i        ),
                  .data_i                       ( base_inst_i      ),

                  .data_o                       ( base_inst_o      ),

                  .is_read_data_i          ( is_read_data_i        ),

                  .sram_ctl_busy_o              ( baseram_busy_o_base  ),
                  .data_r_finish_o              ( inst_r_finish_o_base ),
                  .data_w_finish_o              ( inst_w_finish_o_base ),

                  // base inst ram
                  .sram_addr                ( base_ram_addr    ),
                  .sram_be_n                ( base_ram_be_n    ),
                  .sram_ce_n                ( base_ram_ce_n    ),
                  .sram_oe_n                ( base_ram_oe_n    ),
                  .sram_we_n                ( base_ram_we_n    ),

                  .sram_data                ( base_ram_data    )
              );

assign baseram_busy_i_arb  = baseram_busy_o_base;
assign inst_r_finish_i_arb = inst_r_finish_o_base;
assign inst_w_finish_i_arb = inst_w_finish_o_base;

//////////////////////////////////////////
//////////    uart_buffer.v     //////////
//////////////////////////////////////////

// input
wire [31:0] uart_addr_i;
wire uart_data_r_i;
wire uart_data_w_i;
wire [31:0] uart_data_i_buf;

assign uart_data_w_i = uart_data_w_o;
assign uart_data_i_buf   = uart_data_o;

///////
wire [7:0] r_data_i;
wire r_data_w_i;

assign uart_addr_i = data_addr_o;
assign uart_data_r_i = uart_data_r_o;

///////
wire TxD_busy_i;

// output
wire [31:0] buffer_data_o;
assign uart_data_i = buffer_data_o;

wire TxD_start_o;
wire [7:0] TxD_data_o;

uart_buffer  u_uart_buffer (
                 .clk                     ( clk             ),
                 .rst_n                   ( rst_n           ),

                 // from cpu
                 .uart_addr_i             ( uart_addr_i     ),
                 .uart_data_i             ( uart_data_i_buf ),
                 .uart_data_r_i           ( uart_data_r_i   ),
                 .uart_data_w_i           ( uart_data_w_i   ),

                 // from receiver
                 .r_data_i                ( r_data_i        ),
                 .r_data_w_i              ( r_data_w_i      ),

                 // connect with transmitter
                 .TxD_busy_i              ( TxD_busy_i      ),

                 .TxD_start_o             ( TxD_start_o     ),
                 .TxD_data_o              ( TxD_data_o      ),

                 // for CPU or transmitter
                 .buffer_data_o           ( buffer_data_o   )
             );


//////////////////////////////////////////
//////////    uart receiver     //////////
//////////////////////////////////////////

// input
wire RxD_clear;
// reg RxD_clear;

// output
wire RxD_data_ready;
wire [7:0] RxD_data;

// 使得ready保留2个时钟周�?
// always @(posedge clk)
// begin
//     RxD_clear <= RxD_data_ready;
// end

assign RxD_clear = RxD_data_ready; // 接收成功保留�?个时钟周期就clear

// for uart buffer
assign r_data_i = RxD_data;
assign r_data_w_i = RxD_data_ready;

//接收模块�?9600无检验位
async_receiver #(
                   .ClkFrequency(50000000),
                   .Baud(9600)
               )
               ext_uart_r(
                   .clk             ( clk            ),  //外部时钟信号
                   .RxD             ( rxd            ),  //外部串行信号

                   .RxD_clear       ( RxD_clear      ),  //清除接收标志

                   .RxD_data_ready  ( RxD_data_ready ),  //数据接收到标�?
                   .RxD_data        ( RxD_data    )   //接收到的�?字节数据
               );


//////////////////////////////////////////
//////////   uart transmitter   //////////
//////////////////////////////////////////

// input
wire TxD_start;
wire [7:0] TxD_data;

assign TxD_start  = TxD_start_o;
assign TxD_data = TxD_data_o;

// output
wire TxD_busy;

assign TxD_busy_i = TxD_busy;

async_transmitter #(
                      .ClkFrequency ( 50000000 ),
                      .Baud         ( 9600   ))
                  u_async_transmitter (
                      .clk                     ( clk         ),
                      .TxD                     ( txd         ), // 发给PC

                      .TxD_start               ( TxD_start   ),
                      .TxD_data                ( TxD_data    ),

                      .TxD_busy                ( TxD_busy    )
                  );


/****************************************************/
// 以上内容为自定义内容
/****************************************************/

// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7段数码管译码器演示，将number�?16进制显示在数码管上面
// 两个七段数码管，能够显示全部ASCII字符对应�?16进制�?
// 每个ASCII字符�?2�?16进制�?2�?16进制数分别�?�过2个数码管显示出来
// wire[7:0] number; // 由串口发送，能够接收全部扩展的的ASCII�?

// SEG7_LUT segL(
//              .iDIG      ( number[3:0]   ),  // 4位二进制，能够显示数�? 0 ~ F

//              .oSEG1     ( dpy0          )   // dpy0是低位数码管，代表了7根管儿和1个小数点（小数点恒不亮）
//          );

// SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管

// reg[15:0] led_bits;
// assign leds = led_bits;

// always@(posedge clock_btn or posedge reset_btn)
// begin
//     if(reset_btn)
//     begin //复位按下，设置LED为初始�??
//         led_bits <= 16'h1;
//     end
//     else
//     begin //每次按下时钟按钮，LED循环左移
//         led_bits <= {led_bits[14:0],led_bits[15]};
//     end
// end

// //直连串口接收发�?�演示，从直连串口收到的数据再发送出�?
// // 注释中给出了【�?�辑功能】，还需要关注�?�时序问题�??
// // 以及，接收器和发送器，跟CPU和PC的连接，如何连？

// // 接收器和发�?�器
// // 仅仅完成 �?/�? 转换逻辑
// // 并给出握手信号，以示�? 转换完成与否
// // NOTE：�?�不要�?�将其作为缓存数据的器件



// //////////////////////////////////////
// //////////     receiver     //////////
// //////////////////////////////////////

// // 1. 发�?�一�?1�?1位的串行数据给接收器，共8�?
// // 2. 接收器将其转换位8位并行数据，并设置为“转换完成�?�状�?
// // 3. 转换完成之后�?8位并行数据会被写入到数据缓存区，并设置为“数据有效�??

// // input
// wire ext_uart_clear;

// // output
// wire ext_uart_ready;
// wire [7:0] ext_uart_rx;

// // 接收模块：发送端是PC，接收端是FPGA，�?�接收�?�的主语是FPGA
// // 对于发过来的多个字符，每个字符都会在串口停留�?个时钟周期（谁的时钟？）�?
// // 然后就会变成下一个字符了，就是一个个的接收，�?以接收到的字符必须被
// // 1. 暂存到buffer_data
// // 2. 及时使用，避免被覆盖或�?�丢�?
// async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //接收模块�?9600无检验位
//                ext_uart_r(
//                    .clk             ( clk_50M        ),  //外部时钟信号，串口工作频率还和比特率有关，在内部处理，可以不�?
//                    .RxD             ( rxd            ),  //外部串行信号输入，PC --> FPGA
//                    // 得到的并行数据被拿走了或者弃用，清除掉之前�?�接收成功�?�的信号，变成�?�未接收完成”状�?
//                    .RxD_clear       ( ext_uart_clear ),  //清除接收标志

//                    .RxD_data_ready  ( ext_uart_ready ),  //数据接收到标�?
//                    .RxD_data        ( ext_uart_rx    )   //接收到的�?字节数据
//                );

// // 只要数据被取走，就必须clear，否则串口数据的识别会出现问�?
// assign ext_uart_clear = ext_uart_ready; //收到数据的同时，清除标志，因为数据已取到ext_uart_buffer�?

// reg [7:0] ext_uart_buffer;
// reg ext_uart_avai;
// wire ext_uart_busy;

// always @(posedge clk_50M)
// begin //接收到缓冲区ext_uart_buffer
//     if(ext_uart_ready)
//     begin
//         ext_uart_buffer <= ext_uart_rx;
//         ext_uart_avai <= 1;
//     end
//     else if(!ext_uart_busy && ext_uart_avai)
//     begin
//         ext_uart_avai <= 0;
//     end
// end

// // 通过七段数码管显示当前串口数据的�?
// assign number = ext_uart_buffer;

// ////////////////////////////////////////////////////
// // 以下逻辑代表
// // 1. �?字节大小的数据缓冲区，并且示意是否有�?
// // 2. 如果缓冲区有数据，且数据有效，则将其连接到发送器
// // 3. 数据有效    -- 发�?�器�?始发送串行数�?
// //    8位并行数�? -- 转换�?1�?1位的串行数据

// reg [7:0] ext_uart_tx;
// reg ext_uart_start;

// always @(posedge clk_50M)
// begin //将缓冲区ext_uart_buffer发�?�出�?
//     if(!ext_uart_busy && ext_uart_avai)
//     begin
//         ext_uart_tx <= ext_uart_buffer;
//         ext_uart_start <= 1;
//     end
//     else
//     begin
//         ext_uart_start <= 0;
//     end
// end

// async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //发�?�模块，9600无检验位
//                   ext_uart_t(
//                       .clk          ( clk_50M        ),    //外部时钟信号
//                       .TxD_start    ( ext_uart_start ),    //�?始发送信�?
//                       .TxD_data     ( ext_uart_tx    ),    //待发送的数据

//                       .TxD          ( txd            ),    //串行信号输出  FPGA --> PC
//                       .TxD_busy     ( ext_uart_busy  )     //发�?�器忙状态指�?
//                   );



//图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
// wire [11:0] hdata;
// assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
// assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
// assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
// assign video_clk = clk_50M;
// vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
//         .clk(clk_50M),
//         .hdata(hdata), //横坐�?
//         .vdata(),      //纵坐�?
//         .hsync(video_hsync),
//         .vsync(video_vsync),
//         .data_enable(video_de)
//     );
/* =========== Demo code end =========== */

endmodule