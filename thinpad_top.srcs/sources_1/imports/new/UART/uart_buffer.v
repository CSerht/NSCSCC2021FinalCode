`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/22 13:09:03
// Design Name:
// Module Name: uart_buffer
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 用于存储串口数据，以及串口状态
//              属于数据内存空间
//              【输入的地址范围】0xBFD0_03F8 - 0xBFD0_03FD
//              假定该模块接收到的地址，就是符合范围的32位地址，其他的事情交给地址仲裁模块
//
//  0xBFD0_03F8 - 0xBFD0_03FD  <=映射=> 0x0 - 0x7
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

// 其实这个类似于reg files
`include "../define.v"
module uart_buffer(
           input wire clk,
           input wire rst_n,

           // 为0时，锁死buffer数据，禁止任何写入，同时禁止开启发送器
           input wire trans_enable_i,

           // from cpu
           (*mark_debug = "true"*)input wire [31:0] uart_addr_i,
           (*mark_debug = "true"*)input wire [31:0] uart_data_i,
           (*mark_debug = "true"*)input wire uart_data_r_i,   // read data,high level active
           (*mark_debug = "true"*)input wire uart_data_w_i,

           // from receiver
           input wire [7:0] r_data_i,   // receiver's data
           input wire r_data_w_i,       // ready = 1 => can write

           // to transmitter
           (*mark_debug = "true"*)input wire TxD_busy_i,
           (*mark_debug = "true"*)output reg TxD_start_o,
           (*mark_debug = "true"*)output wire [7:0] TxD_data_o,

           // to cpu
           (*mark_debug = "true"*)output wire [31:0] buffer_data_o
       );


// transform address
/// 0xBFD0_03F8 - 0xBFD0_03FD  <=映射=> [0] - [1]
wire addr;
assign addr = uart_addr_i[2]; // 8 -- 0 ; C -- 1


////// 以下三个数据的读写逻辑，应该与SRAM一致，都是下降沿进行读/写
// data buffer
(*mark_debug = "true"*)reg [7:0] serial_data;
// status
(*mark_debug = "true"*)reg idle; // 0xBFD0_03FC[0]; 1 --> idle
(*mark_debug = "true"*)reg avai; // 0xBFD0_03FC[1]; 1 --> receive data
//////////


// 不同的信号在不同的逻辑下做不同的事情，因此每个信号分开写！


//////////////////////////////////////////////
// 在阻止0x06发送期间，还应该锁定0x06，暂时没加
//////////////////////////////////////////////


// write avai and serial_data 内部数据
always@(negedge clk)
begin
    if(rst_n == `rst_enable)
    begin
        serial_data <= 0;
        avai <= `uart_data_avai_disable;
    end
    // receiver to buffer
    else if(r_data_w_i == `r_data_write_enable && idle == `uart_data_idle)
    begin
        avai <= `uart_data_avai_enable;
        serial_data <= r_data_i;
    end
    // CPU to buffer  idle的检测通过软件（指令序列），能写就说明idle_enable
    else if(uart_data_w_i == `uart_data_write_enable)
    begin
        avai <= `uart_data_avai_enable;
        serial_data <= uart_data_i[7:0];
    end
    // CPU read data from buffer, and clear avai status bit
    else if(uart_data_r_i == `uart_data_read_enable && addr == `cpu_read_serial_data)
    begin
        avai <= `uart_data_avai_disable;
    end
end


// write idle 内部数据
always@(negedge clk)
begin
    if(rst_n == `rst_enable)
    begin
        idle <= `uart_data_idle;
    end
    else if(uart_data_w_i == `uart_data_write_enable || TxD_busy_i || TxD_start_o)
    begin
        idle <= `uart_data_busy; // buffer的busy是0，发送器的busy是1.
    end
    else
    begin
        idle <= `uart_data_idle;
    end
end

localparam DATA_W_START = 2'b01; // uart_data_w_i导致启动发送器
localparam TRANS_START  = 2'b10; // trans_enable_i导致启动发送器
reg [1:0] state;

// 处理start
always@(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        TxD_start_o <= `t_start_disable;
        state <= DATA_W_START;
    end
    else if(trans_enable_i == `transmitter_enable)
    begin
        // 一般状态下启动发送器
        if(uart_data_w_i == `uart_data_write_enable && state == DATA_W_START)
        begin
            TxD_start_o <= `t_start_enable;
        end
        else if(state == TRANS_START) // 被模式切换机禁止后启动start
        begin
            TxD_start_o <= `t_start_enable;
            state <= DATA_W_START;
        end
        else
        begin
            TxD_start_o <= `t_start_disable;
        end
    end
    else if(trans_enable_i == `transmitter_disable)
    begin
        state <= TRANS_START;
    end
end

// assign TxD_start_o = !idle; // 注意是start --启动--> busy
assign TxD_data_o = serial_data;

// read data from buffer
assign buffer_data_o =
       // avai的检测通过软件，能读就说明avai_enable了
       (uart_data_r_i == `uart_data_read_enable)?
       (
           (addr == `cpu_read_serial_data) ?
           {{24{serial_data[7]}}, serial_data}: //读串口数据
           {30'h0, avai, idle} // 读串口状态
       )
       :0; // 数据读取失败



// // data buffer
// reg [7:0] serial_memory[7:0]; // 多余2个是为了凑2的倍数8


// // write logic
// // 如果CPU和接收器同时准备好数据，又同时写入
// // 按当前逻辑，接收器会优先写入，CPU写的数据会丢失
// reg TxD_start_o_1;
// always@(posedge clk)
// begin
//     if(rst_n == `rst_enable)
//     begin
//         serial_memory[0] <= 0; // serial port data
//         serial_memory[1] <= 0;
//         serial_memory[2] <= 0;
//         serial_memory[3] <= 0;
//         //serial_memory[4] <= 1; // status bit; NOTE！[0] = 1 -- idle
//         serial_memory[5] <= 0;
//         serial_memory[6] <= 0;
//         serial_memory[7] <= 0;
//         TxD_start_o_1 <= `t_start_disable;
//     end
//     // receiver write data
//     // 如果写之前是avai_enable，则之前的数据会被新的帧覆盖
//     else if(r_data_w_i == `r_data_write_enable && !TxD_busy_i)
//     begin
//         serial_memory[0] <= r_data_i;
//         serial_memory[4][1] <= `uart_data_avai_enable; // 收到数据
//         //serial_memory[4][0] <= `uart_data_idle;        // 串口空闲
//         TxD_start_o_1 <= `t_start_disable;
//     end
//     // CPU write data（之前通过状态位确定“空闲”）了
//     else if(uart_data_w_i == `uart_data_write_enable)
//     begin
//         serial_memory[0] <= uart_data_i[7:0];
//         serial_memory[4][1] <= `uart_data_avai_disable; // 不是串口发过来的，不可用
//         //serial_memory[4][0] <= `uart_data_busy;         // 串口忙碌
//         TxD_start_o_1 <= `t_start_enable;     // 发送器开始工作
//     end
//     else if(uart_data_r_i == `uart_data_read_enable) // 不能和下降沿读取写一起，会导致多驱动
//     begin
//         serial_memory[4][1] <= `uart_data_avai_disable; // clear
//     end
//     else if(!TxD_busy_i)
//     begin
//         TxD_start_o_1 <= `t_start_disable;
//         //serial_memory[4][0] <= `uart_data_idle;  // 串口空闲
//     end
// end


// // // 二级流水，使得start晚一个周期出现，保证数据准备好
// // always@(posedge clk)
// // begin
// //     TxD_start_o <= TxD_start_o_1;
// // end

// assign TxD_start_o = TxD_start_o_1;


// // 针对串口忙碌状态的处理
// always@(posedge clk)
// begin
//     if(rst_n == `rst_enable)
//     begin
//         serial_memory[4][0] <= `uart_data_idle;
//     end
//     else if(uart_data_w_i == `uart_data_write_enable || TxD_busy_i || TxD_start_o_1)
//     begin
//         serial_memory[4][0] <= `uart_data_busy;
//     end
//     else
//     begin
//         serial_memory[4][0] <= `uart_data_idle;
//     end
// end



// // read logic
// reg [7:0] temp_data;
// always@(negedge clk)
// begin
//     if(rst_n == `rst_enable)
//     begin
//         temp_data = 1; // idle
//     end
//     // CPU read data
//     else if(uart_data_r_i == `uart_data_read_enable)
//     begin
//         // read status
//         if(serial_addr == 4)
//         begin
//             temp_data <= serial_memory[4];
//         end
//         // read data
//         else if(serial_addr == 0)
//         begin
//             temp_data <= serial_memory[0];
//         end
//     end
// end



// // output  cpu data (8 --> 32) sign extend
// assign buffer_data_o = {{24{temp_data[7]}}, temp_data};

// assign TxD_data_o = serial_memory[0];   // transmitter data

endmodule
