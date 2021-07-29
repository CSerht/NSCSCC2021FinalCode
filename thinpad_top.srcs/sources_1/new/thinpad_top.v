`default_nettype none

module thinpad_top(
           input wire clk_50M,           //50MHz ʱ������
           input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�

           input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
           input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

           input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
           input  wire[31:0] dip_sw,     //32λ���뿪�أ�������ON��ʱΪ1
           output wire[15:0] leds,       //16λLED�����ʱ1����
           output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
           output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

           //BaseRAM�ź�
           inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
           (*mark_debug = "true"*)output wire[19:0] base_ram_addr, //BaseRAM��ַ
           (*mark_debug = "true"*)output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
           output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
           (*mark_debug = "true"*)output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
           (*mark_debug = "true"*)output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

           //ExtRAM�ź�
           inout wire[31:0] ext_ram_data,  //ExtRAM����
           (*mark_debug = "true"*)output wire[19:0] ext_ram_addr, //ExtRAM��ַ
           (*mark_debug = "true"*)output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
           output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
           (*mark_debug = "true"*)output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
           (*mark_debug = "true"*)output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

           //ֱ�������ź�
           output wire txd,  //ֱ�����ڷ��Ͷ�
           input  wire rxd,  //ֱ�����ڽ��ն�

           //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
           output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
           inout  wire [15:0]flash_d,      //Flash����
           output wire flash_rp_n,         //Flash��λ�źţ�����Ч
           output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
           output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
           output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
           output wire flash_we_n,         //Flashдʹ���źţ�����Ч
           output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

           //ͼ������ź�
           output wire[2:0] video_red,    //��ɫ���أ�3λ
           output wire[2:0] video_green,  //��ɫ���أ�3λ
           output wire[1:0] video_blue,   //��ɫ���أ�2λ
           output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
           output wire video_vsync,       //��ͬ������ֱͬ�����ź�
           output wire video_clk,         //����ʱ�����
           output wire video_de           //��������Ч�źţ���������������
       );

/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
// wire locked, clk_10M, clk_20M;
// pll_example clock_gen
//             (
//                 // Clock in ports
//                 .clk_in1(clk_50M),  // �ⲿʱ������
//                 // Clock out ports
//                 .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������
//                 .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
//                 // Status and control signals
//                 .reset(reset_btn), // PLL��λ����
//                 .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
//                 // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
//             );

// reg reset_of_clk10M;
// �첽��λ��ͬ���ͷţ���locked�ź�תΪ�󼶵�·�ĸ�λreset_of_clk10M
// always@(posedge clk_10M or negedge locked)
// begin
//     if(~locked)
//         reset_of_clk10M <= 1'b1;
//     else
//         reset_of_clk10M <= 1'b0;
// end

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

// // ��ʹ���ڴ桢����ʱ��������ʹ���ź�
// assign base_ram_ce_n = 1'b1;
// assign base_ram_oe_n = 1'b1;
// assign base_ram_we_n = 1'b1;

// assign ext_ram_ce_n = 1'b1;
// assign ext_ram_oe_n = 1'b1;
// assign ext_ram_we_n = 1'b1;

/****************************************************/
// ��������Ϊ�Զ�������
/****************************************************/


//////////////////////////////////////////
///////////     CPU kernel     ///////////
//////////////////////////////////////////

// input
wire clk;
wire rst_n;
assign clk = clk_50M;
assign rst_n = reset_btn;

wire [31:0] inst_i;
wire [31:0] data_i;


wire baseram_busy_i_cpu;
wire inst_r_finish_i_cpu;
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

                 // extRAM and serialMemory ����
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

// ʹ��ready����2��ʱ������
// always @(posedge clk)
// begin
//     RxD_clear <= RxD_data_ready;
// end

assign RxD_clear = RxD_data_ready; // ���ճɹ�����һ��ʱ�����ھ�clear

// for uart buffer
assign r_data_i = RxD_data;
assign r_data_w_i = RxD_data_ready;

//����ģ�飬9600�޼���λ
async_receiver #(
                   .ClkFrequency(50000000),
                   .Baud(9600)
               )
               ext_uart_r(
                   .clk             ( clk            ),  //�ⲿʱ���ź�
                   .RxD             ( rxd            ),  //�ⲿ�����ź�

                   .RxD_clear       ( RxD_clear      ),  //������ձ�־

                   .RxD_data_ready  ( RxD_data_ready ),  //���ݽ��յ���־
                   .RxD_data        ( RxD_data    )   //���յ���һ�ֽ�����
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
                      .TxD                     ( txd         ), // ����PC

                      .TxD_start               ( TxD_start   ),
                      .TxD_data                ( TxD_data    ),

                      .TxD_busy                ( TxD_busy    )
                  );


/****************************************************/
// ��������Ϊ�Զ�������
/****************************************************/

// ��������ӹ�ϵʾ��ͼ��dpy1ͬ��
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7���������������ʾ����number��16������ʾ�����������
// �����߶�����ܣ��ܹ���ʾȫ��ASCII�ַ���Ӧ��16������
// ÿ��ASCII�ַ�ռ2��16���ƣ�2��16�������ֱ�ͨ��2���������ʾ����
// wire[7:0] number; // �ɴ��ڷ��ͣ��ܹ�����ȫ����չ�ĵ�ASCII��

// SEG7_LUT segL(
//              .iDIG      ( number[3:0]   ),  // 4λ�����ƣ��ܹ���ʾ���� 0 ~ F

//              .oSEG1     ( dpy0          )   // dpy0�ǵ�λ����ܣ�������7���ܶ���1��С���㣨С����㲻����
//          );

// SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����

// reg[15:0] led_bits;
// assign leds = led_bits;

// always@(posedge clock_btn or posedge reset_btn)
// begin
//     if(reset_btn)
//     begin //��λ���£�����LEDΪ��ʼֵ
//         led_bits <= 16'h1;
//     end
//     else
//     begin //ÿ�ΰ���ʱ�Ӱ�ť��LEDѭ������
//         led_bits <= {led_bits[14:0],led_bits[15]};
//     end
// end

// //ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
// // ע���и����ˡ��߼����ܡ�������Ҫ��ע��ʱ�����⡿
// // �Լ����������ͷ���������CPU��PC�����ӣ��������

// // �������ͷ�����
// // ������� ��/�� ת���߼�
// // �����������źţ���ʾ�� ת��������
// // NOTE������Ҫ��������Ϊ�������ݵ�����



// //////////////////////////////////////
// //////////     receiver     //////////
// //////////////////////////////////////

// // 1. ����һ��1λ1λ�Ĵ������ݸ�����������8λ
// // 2. ����������ת��λ8λ�������ݣ�������Ϊ��ת����ɡ�״̬
// // 3. ת�����֮��8λ�������ݻᱻд�뵽���ݻ�������������Ϊ��������Ч��

// // input
// wire ext_uart_clear;

// // output
// wire ext_uart_ready;
// wire [7:0] ext_uart_rx;

// // ����ģ�飺���Ͷ���PC�����ն���FPGA�������ա���������FPGA
// // ���ڷ������Ķ���ַ���ÿ���ַ������ڴ���ͣ��һ��ʱ�����ڣ�˭��ʱ�ӣ�����
// // Ȼ��ͻ�����һ���ַ��ˣ�����һ�����Ľ��գ����Խ��յ����ַ����뱻
// // 1. �ݴ浽buffer_data
// // 2. ��ʱʹ�ã����ⱻ���ǻ��߶�ʧ
// async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
//                ext_uart_r(
//                    .clk             ( clk_50M        ),  //�ⲿʱ���źţ����ڹ���Ƶ�ʻ��ͱ������йأ����ڲ��������Բ���
//                    .RxD             ( rxd            ),  //�ⲿ�����ź����룬PC --> FPGA
//                    // �õ��Ĳ������ݱ������˻������ã������֮ǰ�����ճɹ������źţ���ɡ�δ������ɡ�״̬
//                    .RxD_clear       ( ext_uart_clear ),  //������ձ�־

//                    .RxD_data_ready  ( ext_uart_ready ),  //���ݽ��յ���־
//                    .RxD_data        ( ext_uart_rx    )   //���յ���һ�ֽ�����
//                );

// // ֻҪ���ݱ�ȡ�ߣ��ͱ���clear�����򴮿����ݵ�ʶ����������
// assign ext_uart_clear = ext_uart_ready; //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��

// reg [7:0] ext_uart_buffer;
// reg ext_uart_avai;
// wire ext_uart_busy;

// always @(posedge clk_50M)
// begin //���յ�������ext_uart_buffer
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

// // ͨ���߶��������ʾ��ǰ�������ݵ�ֵ
// assign number = ext_uart_buffer;

// ////////////////////////////////////////////////////
// // �����߼�����
// // 1. һ�ֽڴ�С�����ݻ�����������ʾ���Ƿ���Ч
// // 2. ��������������ݣ���������Ч���������ӵ�������
// // 3. ������Ч    -- ��������ʼ���ʹ�������
// //    8λ�������� -- ת��Ϊ1λ1λ�Ĵ�������

// reg [7:0] ext_uart_tx;
// reg ext_uart_start;

// always @(posedge clk_50M)
// begin //��������ext_uart_buffer���ͳ�ȥ
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

// async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
//                   ext_uart_t(
//                       .clk          ( clk_50M        ),    //�ⲿʱ���ź�
//                       .TxD_start    ( ext_uart_start ),    //��ʼ�����ź�
//                       .TxD_data     ( ext_uart_tx    ),    //�����͵�����

//                       .TxD          ( txd            ),    //�����ź����  FPGA --> PC
//                       .TxD_busy     ( ext_uart_busy  )     //������æ״ָ̬ʾ
//                   );



//ͼ�������ʾ���ֱ���800x600@75Hz������ʱ��Ϊ50MHz
// wire [11:0] hdata;
// assign video_red = hdata < 266 ? 3'b111 : 0; //��ɫ����
// assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //��ɫ����
// assign video_blue = hdata >= 532 ? 2'b11 : 0; //��ɫ����
// assign video_clk = clk_50M;
// vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
//         .clk(clk_50M),
//         .hdata(hdata), //������
//         .vdata(),      //������
//         .hsync(video_hsync),
//         .vsync(video_vsync),
//         .data_enable(video_de)
//     );
/* =========== Demo code end =========== */

endmodule
