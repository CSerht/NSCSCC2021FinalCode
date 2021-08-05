`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/08/02 20:50:44
// Design Name:
// Module Name: mode_convert
// Project Name:
// Target Devices:
// Tool Versions:
// Description: CPU运行模式切换，在执行G命令的时候进入
//              Fast Mode，流水线全速运行
//              Normal Mode  <--> Fast Mode
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

module mode_convert(
           input wire clk,
           input wire rst_n,

           // CLOSE状态，保存v0，写入v0的时候，就保存起来
           input wire [4:0] mem_wb_rW_i,
           input wire [31:0] mem_wb_wdata_i,
           input wire mem_wb_reg_w_i,

           // 识别0x06信号
           input wire [31:0] id_G_start_i, // 识别指令 ori a0,zero,TIMERSET(0x06)
           output reg [31:0] prgm_start_addr_o, // 程序起始地址，也就是v0
           output reg lock_addr_o,// 若收到0x06通知仲裁模块锁住v0地址


           // 识别串口写
           /// 0x06 EX stage
           input wire id_ex_data_w_i,  // 应为1
           input wire [31:0] id_ex_data_addr_i, // 应为串口数据地址

           /// 0x07 MEM stage
           input wire ex_mem_data_w_i,  // 应为1
           input wire [31:0] ex_mem_data_addr_i, // 应为串口数据地址

           output reg bram_w_start_o, // 为1，则即将执行的程序写入到bram中
           (*mark_debug = "true"*)output reg trans_enable_o, // 若为0，串口发送器不工作
           output reg stall_entire_cpu_o,// 为1，暂停整个CPU，所有寄存器写disable

           // 即将切换到Fast Mode
           input wire bram_w_finish_i,  // 为1，写入bram完成
           (*mark_debug = "true"*)output reg fast_mode_start_o // 为1，切换到fast，为0则是noramlMode
       );

localparam CLOSE             = 7'b0000_001; // 关闭fast
localparam PREPARE_OPEN_G    = 7'b0000_010; // 识别G命令
localparam PREPARE_OPEN_INST = 7'b0000_100; // 准备写入指令到BRAM
localparam PREPARE_OPEN      = 7'b0001_000; // 写入完成后稳定期
localparam OPEN              = 7'b0010_000; // 开启Fast Mode
localparam PREPARE_CLOSE     = 7'b0100_000; // 识别0x07，准备关闭Fast Mode
localparam PREPARE_CLOSE_2   = 7'b1000_000; // 过渡
reg [6:0] state;  // 若增加状态，别忘记修改位宽！


wire is_write_v0 =
     (mem_wb_reg_w_i == `reg_write_enable) &&
     (mem_wb_rW_i == `reg_v0); // 为1代表即将写入到v0


// 记录之前识别的信号，为了区分ID和MEM阶段识别到的sb指令
localparam NO_SIGNAL  = 2'b00;
localparam SIGNAL_0x6 = 2'b01;
localparam SIGNAL_0x7 = 2'b10;
reg [1:0] current_signal;

// 为1，则是准备0x06信号指令
wire is_0x06 = (id_G_start_i == 32'h34040006);

wire is_0x07 = (id_G_start_i == 32'h34040007);


wire is_sb_serial_exstage = // 为1，则是写串口指令 0x06
     (id_ex_data_w_i == `data_w_enable)  &&
     (id_ex_data_addr_i[31:24] == 8'hBF) &&
     (current_signal == SIGNAL_0x6);

wire is_sb_serial_memstage = // 为1，则是写串口指令 0x07
     (ex_mem_data_w_i == `data_w_enable)  &&
     (ex_mem_data_addr_i[31:24] == 8'hBF) &&
     (current_signal == SIGNAL_0x7);

always @(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        state               <= CLOSE;
        prgm_start_addr_o   <= 32'h0000_0000;
        bram_w_start_o      <= `bram_write_disable;
        trans_enable_o      <= `transmitter_enable;
        fast_mode_start_o   <= `normal_mode;
        lock_addr_o         <= `lock_addr_disable;
        stall_entire_cpu_o  <= `all_reg_w_enable;
        current_signal      <= NO_SIGNAL;
    end
    else
    begin
        case(state)
            CLOSE:
            begin
                if(is_write_v0)
                begin
                    prgm_start_addr_o <= mem_wb_wdata_i;
                    state <= CLOSE;
                end
                else if(is_0x06) // 若识别到0x06启动信号
                begin
                    lock_addr_o     <= `lock_addr_enable;
                    state           <= PREPARE_OPEN_G;
                    current_signal  <= SIGNAL_0x6;
                end
            end

            PREPARE_OPEN_G:
            begin
                if(is_sb_serial_exstage) // 若写入0x06到串口buffer
                begin
                    bram_w_start_o     <= `bram_write_enable;
                    trans_enable_o     <= `transmitter_disable;
                    // trans_enable_o     <= `transmitter_enable;
                    stall_entire_cpu_o <= `all_reg_w_disable;
                    state              <= PREPARE_OPEN_INST;
                    current_signal     <= NO_SIGNAL;
                end
            end

            PREPARE_OPEN_INST:
            begin
                if(bram_w_finish_i == `bram_write_finish) // BRAM写入完成
                begin
                    fast_mode_start_o <= `fast_mode;

                    bram_w_start_o     <= `bram_write_disable;
                    trans_enable_o     <= `transmitter_enable;
                    // stall_entire_cpu_o <= `all_reg_w_enable;

                    state <= PREPARE_OPEN;
                end
            end

            PREPARE_OPEN: // 刚进入Fast Mode的过渡期
            begin
                stall_entire_cpu_o <= `all_reg_w_enable;

                state <= OPEN;
            end

            OPEN:
            begin
                if(is_0x07)
                begin
                    current_signal  <= SIGNAL_0x7;

                    state <= PREPARE_CLOSE;
                end
            end

            PREPARE_CLOSE:
            begin
                if(is_sb_serial_memstage)
                begin
                    lock_addr_o         <= `lock_addr_disable;
                    // fast_mode_start_o   <= `normal_mode;

                    current_signal      <= NO_SIGNAL;

                    state <= PREPARE_CLOSE_2;
                end
            end

            PREPARE_CLOSE_2:
            begin
                fast_mode_start_o   <= `normal_mode;
                state <= CLOSE;
            end
        endcase
    end
end


endmodule
