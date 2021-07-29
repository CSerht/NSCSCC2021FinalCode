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
