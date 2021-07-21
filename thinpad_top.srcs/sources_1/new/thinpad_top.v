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
           output wire[19:0] base_ram_addr, //BaseRAM��ַ
           output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
           output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
           output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
           output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

           //ExtRAM�ź�
           inout wire[31:0] ext_ram_data,  //ExtRAM����
           output wire[19:0] ext_ram_addr, //ExtRAM��ַ
           output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
           output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
           output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
           output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

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
wire locked, clk_10M, clk_20M;
pll_example clock_gen
            (
                // Clock in ports
                .clk_in1(clk_50M),  // �ⲿʱ������
                // Clock out ports
                .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������
                .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
                // Status and control signals
                .reset(reset_btn), // PLL��λ����
                .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
                // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
            );

reg reset_of_clk10M;
// �첽��λ��ͬ���ͷţ���locked�ź�תΪ�󼶵�·�ĸ�λreset_of_clk10M
always@(posedge clk_10M or negedge locked)
begin
    if(~locked)
        reset_of_clk10M <= 1'b1;
    else
        reset_of_clk10M <= 1'b0;
end

always@(posedge clk_10M or posedge reset_of_clk10M)
begin
    if(reset_of_clk10M)
    begin
        // Your Code
    end
    else
    begin
        // Your Code
    end
end

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
//////////     ext data mem     //////////
//////////////////////////////////////////

// input
wire [1:0] mode_i;
wire data_w_i;
wire data_r_i;
wire data_ce_i;
wire [31:0] data_addr_i;
wire [31:0] data_i_ext;

assign mode_i = mode_o_cpu;
assign data_w_i = data_w_o_cpu;
assign data_r_i = data_r_o_cpu;
assign data_ce_i = data_ce_o_cpu;
assign data_addr_i = data_addr_o_cpu;
assign data_i_ext = data_o_cpu;

// output
wire [31:0] data_o_ext;
assign data_i = data_o_ext;



ext_ram_ctl  u_ext_ram_ctl (
                 .mode_i                   ( mode_i           ),
                 .data_w_i                 ( data_w_i         ),
                 .data_r_i                 ( data_r_i         ),
                 .data_ce_i                ( data_ce_i        ),
                 .data_addr_i              ( data_addr_i      ),
                 .data_i                   ( data_i_ext       ),

                 .data_o                   ( data_o_ext       ),
                 // ext data ram
                 .ext_ram_addr             ( ext_ram_addr     ),
                 .ext_ram_be_n             ( ext_ram_be_n     ),
                 .ext_ram_ce_n             ( ext_ram_ce_n     ),
                 .ext_ram_oe_n             ( ext_ram_oe_n     ),
                 .ext_ram_we_n             ( ext_ram_we_n     ),

                 .ext_ram_data             ( ext_ram_data     )
             );


//////////////////////////////////////////
//////////    base inst mem     //////////
//////////////////////////////////////////

// input
wire [0:0] inst_w_i;
wire [0:0] inst_r_i;
wire [0:0] inst_ce_i;
wire [31:0] pc_i;
wire [31:0] inst_i_base;

assign inst_w_i = inst_w_o_cpu;
assign inst_r_i = inst_r_o_cpu;
assign inst_ce_i = inst_ce_o_cpu;
assign pc_i = pc_o_cpu;
assign inst_i_base = inst_o_cpu;

// output
wire [31:0] inst_o;
assign inst_i = inst_o;

base_ram_ctl  u_base_ram_ctl (
                  .inst_w_i                     ( inst_w_i         ),
                  .inst_r_i                     ( inst_r_i         ),
                  .inst_ce_i                    ( inst_ce_i        ),
                  .pc_i                         ( pc_i             ),
                  .inst_i                       ( inst_i_base      ),

                  .inst_o                       ( inst_o           ),
                  // base inst ram
                  .base_ram_addr_o              ( base_ram_addr    ),
                  .base_ram_be_o                ( base_ram_be_n    ),
                  .base_ram_ce_o                ( base_ram_ce_n    ),
                  .base_ram_oe_o                ( base_ram_oe_n    ),
                  .base_ram_we_o                ( base_ram_we_n    ),

                  .base_ram_data_io             ( base_ram_data    )
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
wire[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����

reg[15:0] led_bits;
assign leds = led_bits;

always@(posedge clock_btn or posedge reset_btn)
begin
    if(reset_btn)
    begin //��λ���£�����LEDΪ��ʼֵ
        led_bits <= 16'h1;
    end
    else
    begin //ÿ�ΰ���ʱ�Ӱ�ť��LEDѭ������
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;

assign number = ext_uart_buffer;

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
               ext_uart_r(
                   .clk(clk_50M),                       //�ⲿʱ���ź�
                   .RxD(rxd),                           //�ⲿ�����ź�����
                   .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
                   .RxD_clear(ext_uart_clear),       //������ձ�־
                   .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
               );

assign ext_uart_clear = ext_uart_ready; //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��
always @(posedge clk_50M)
begin //���յ�������ext_uart_buffer
    if(ext_uart_ready)
    begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end
    else if(!ext_uart_busy && ext_uart_avai)
    begin
        ext_uart_avai <= 0;
    end
end
always @(posedge clk_50M)
begin //��������ext_uart_buffer���ͳ�ȥ
    if(!ext_uart_busy && ext_uart_avai)
    begin
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end
    else
    begin
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
                  ext_uart_t(
                      .clk(clk_50M),                  //�ⲿʱ���ź�
                      .TxD(txd),                      //�����ź����
                      .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
                      .TxD_start(ext_uart_start),    //��ʼ�����ź�
                      .TxD_data(ext_uart_tx)        //�����͵�����
                  );

//ͼ�������ʾ���ֱ���800x600@75Hz������ʱ��Ϊ50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //��ɫ����
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //��ɫ����
assign video_blue = hdata >= 532 ? 2'b11 : 0; //��ɫ����
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
        .clk(clk_50M),
        .hdata(hdata), //������
        .vdata(),      //������
        .hsync(video_hsync),
        .vsync(video_vsync),
        .data_enable(video_de)
    );
/* =========== Demo code end =========== */

endmodule
