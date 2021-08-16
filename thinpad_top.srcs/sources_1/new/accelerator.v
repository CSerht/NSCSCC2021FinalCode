`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/08/16 11:20:08
// Design Name:
// Module Name: accelerator
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "../imports/new/define.v"
module accelerator(
           input wire [31:0] spe_data_i, // 待处理数据

           output wire [31:0] spe_result_o
       );

// 获取result的逻辑，就是加速器逻辑
// 尽可能【并行处理数据】
assign spe_result_o = spe_data_i + spe_data_i;

endmodule
