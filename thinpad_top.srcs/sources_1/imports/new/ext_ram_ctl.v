// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company:
// // Engineer:
// //
// // Create Date: 2021/06/23 21:03:18
// // Design Name:
// // Module Name: ext_ram_ctl
// // Project Name:
// // Target Devices:
// // Tool Versions:
// // Description: SRAM控制器只需要一个模块，实例化两个
// //
// // Dependencies:
// //
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// //
// //////////////////////////////////////////////////////////////////////////////////
// `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/28 16:52:25
// Design Name:
// Module Name: sram_ctl
// Project Name:
// Target Devices:
// Tool Versions:
// Description: SRAM控制器，能够控制baseRAM和extRAM
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

// `include "define.v"
// module sram_ctl(
//            input wire clk,
//            input wire rst_n,

//            // from CPU IF stage
//            //    input wire [1:0] base_mode_i,
//            input wire [3:0] data_sel_i,

//            input wire data_w_i, // 写使能，高有效
//            input wire data_r_i, // 读使能，高有效
//            input wire data_ce_i, // 芯片使能，高有效，留有端口但是内部不使用

//            input  wire [31:0] data_addr_i,
//            (*mark_debug = "true"*)input  wire [31:0] data_i,
//            (*mark_debug = "true"*)output wire [31:0] data_o,


//            // signal to cpu  active-high
//            output reg sram_ctl_busy_o,
//            output reg data_r_finish_o,
//            output reg data_w_finish_o,


//            // from Base RAM, inst RAM
//            inout wire[31:0] sram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享，暂时恒输出

//            output reg [19:0] sram_addr, //BaseRAM地址
//            output reg [3:0] sram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
//            output reg  sram_ce_n,       //BaseRAM片选，低有效
//            output reg  sram_oe_n,       //BaseRAM读使能，低有效
//            output reg  sram_we_n        //BaseRAM写使能，低有效
//        );

// // FSM state 独热码
// localparam IDLE  = 3'b001;
// localparam READ  = 3'b010;
// localparam WRITE = 3'b100;

// // tristate. if(W_ENBALE) inout --> output,write data to SRAM
// localparam W_ENABLE  = 2'b01;
// localparam W_DISABLE = 2'b10; // rear data from SRAM

// reg [2:0] current_state;
// reg [31:0] data_from_SRAM;
// reg [31:0] data_to_SRAM;
// reg [1:0] tristate;


// initial
// begin
//     // cpu
//     sram_ctl_busy_o  <= `sram_idle;
//     data_r_finish_o <= `data_read_unfinish;
//     // 写入完成，意味着当前没有数据被写入，平时就是这个状态！
//     // 还有成功写入数据之后，也会从unfinish进入finish状态
//     data_w_finish_o <= `data_write_finish; // NOTE

//     // base ram
//     sram_addr <= 0;
//     sram_be_n   <= 0;
//     sram_ce_n   <= 1;
//     sram_oe_n   <= 1;
//     sram_we_n   <= 1;

//     // internal data
//     current_state  <= IDLE;
//     data_from_SRAM <= 32'h0000_0000;
//     data_to_SRAM   <= 32'h0000_0000;
//     tristate       <= W_DISABLE;
// end

// // 时钟上升沿之后，进入某个状态，并在该状态下保持一个周期！
// // 注意所有的状态信息（读完成，写完成，忙碌）都代表的是controler的状态！
// // 例如busy，在读状态上升沿写入后保持的一个周期：
// // buffer的数据是从SRAM读出并存好的数据，r_finish表示当前buffer数据有效
// // busy表示当前buffer正在工作中
// // 注意此时，状态机虽然是IDLE状态，但是当前周期是数据保持有效的周期
// always @(posedge clk)
// begin
//     case (current_state)
//         /////// 1. 中止 读/写 状态，保持idle
//         /////// 2. 根据CPU传来的信息，为下面的读写状态
//         ///////    提前准备好数据(要写入的数据)和地址（读/写地址），并切换状态
//         IDLE:
//         begin
//             // internal data
//             tristate       <= W_DISABLE;

//             // cpu
//             sram_ctl_busy_o  <= `sram_idle;
//             data_r_finish_o <= `data_read_unfinish;
//             // NOTE! 把之前的WE拉高，结束写入周期
//             data_w_finish_o <= `data_write_finish;

//             // base ram
//             sram_ce_n   <= 0;
//             sram_oe_n   <= 0;
//             sram_we_n   <= 1;
//             // ###########################################
//             // NOTE！与取指不同，取指一直连续读，关注不读的部分
//             // 取数据只是偶尔取，数据准备好之后，data_read
//             // 依然是高电平，需要上升沿之后才下降（进入MEM）
//             // 这会导致ext控制器再一次读取，但实际上已经读完
//             // 这会导致连续load出错！
//             // ###########################################
//             if(data_r_i == `data_read_enable && data_r_finish_o == `data_read_unfinish)
//             begin
//                 sram_be_n   <= data_sel_i;
//                 sram_addr <= data_addr_i[21:2];
//                 current_state   <= READ;
//             end
//             else if(data_w_i == `data_write_enable)
//             begin
//                 data_to_SRAM     <= data_i;
//                 sram_be_n        <= data_sel_i;
//                 sram_addr        <= data_addr_i[21:2];
//                 current_state    <= WRITE;
//             end
//             else // not read and write
//             begin
//                 sram_be_n        <= 0;
//                 current_state    <= IDLE;
//             end
//         end
//         /////// 读阶段，把已经从SRAM读出的数据（在门口等着），写入到read data buffer中
//         /////// 该周期等待数据从SRAM的家里走到控制器门口
//         READ:
//         begin
//             // if(data_r_i == `data_read_enable)
//             // begin
//             data_from_SRAM    <= sram_data;
//             data_r_finish_o   <= `data_read_finish;
//             sram_ctl_busy_o    <= `sram_busy;

//             current_state     <= IDLE;
//             // end   // 以下只针对【取指的SRAM控制器】
//             // else  // 如果准备写入数据到buffer的时候，发现CPU读不允许了
//             // begin // 就等待读允许，再切换状态
//             // current_state <= READ;
//             // end
//         end
//         /////// 写阶段，把已经准备在 write data buffer中的数据
//         /////// 准备写入到SRAM中（下拉WE，启动写入）
//         /////// 该周期等待数据进入它在SRAM的家里
//         WRITE:
//         begin
//             data_w_finish_o <= `data_write_unfinish;
//             sram_we_n   <= 0;
//             sram_ctl_busy_o  <= `sram_busy;

//             current_state <= IDLE;
//             tristate      <= W_ENABLE;
//         end
//     endcase

// end

// assign sram_data =
//        (tristate == W_ENABLE)?
//        data_to_SRAM : 32'hzzzz_zzzz;

// assign data_o = data_from_SRAM;

// endmodule

// `include "define.v"
// module ext_ram_ctl(
//            input wire clk,
//            input wire rst_n,
//            // from CPU

//            //    input wire [1:0] mode_i,
//            input wire [3:0] data_sel_i,
//            // 以下三个均高电平有效
//            input wire data_w_i,
//            input wire data_r_i,
//            input wire data_ce_i,

//            input wire [31:0] data_addr_i, // 来自CPU的数据虚拟地址
//            (*mark_debug = "true"*)input wire [31:0] data_i,    // 待写入的数据
//            (*mark_debug = "true"*)output reg [31:0] data_o,   // 读取到的数据

//            // signal to cpu  active-high
//            output reg extram_busy_o,
//            output reg extdata_r_finish_o,
//            output reg extdata_w_finish_o,


//            //ExtRAM信号
//            inout wire[31:0] ext_ram_data,  //ExtRAM数据
//            output wire[19:0] ext_ram_addr, //ExtRAM地址
//            output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
//            output wire ext_ram_ce_n,       //ExtRAM片选，低有效
//            output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
//            output wire ext_ram_we_n       //ExtRAM写使能，低有效
//        );






// //////////////////////////////////////////
// // 以前错误的组合逻辑
// // ///////////////////////////////////////
// // assign ext_ram_data = (data_w_i == 1)? data_i: 32'hzzzz_zzzz;
// // // assign data_o = ext_ram_data;

// // always @(posedge clk or posedge rst_n)
// // begin
// //     if(rst_n == `rst_enable)
// //         data_o <= 0;
// //     else if(data_r_i == 1)
// //         data_o <= ext_ram_data;
// // end

// // // wire [31:0] addr_i_physical = {3'b000, data_addr_i[28:0]};
// // assign ext_ram_addr = data_addr_i[21:2];

// // // assign ext_ram_be_n = data_sel_i;
// // assign ext_ram_be_n = data_sel_i;
// // assign ext_ram_oe_n = !data_r_i;
// // // 若连续两次出现store，就会出问题！第二个就不能正常写入了，因为we没有上拉
// // assign ext_ram_we_n = !data_w_i;

// // assign ext_ram_ce_n = (!data_ce_i) ||
// //        (data_ce_i && data_r_i && data_w_i) ||
// //        (data_ce_i && !data_r_i && !data_w_i);



// endmodule
