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
           input wire clk,

           input wire [31:0] spe_data_i, // 待处理数据

           output wire [31:0] spe_result_o
       );

// 获取result的逻辑，就是加速器逻辑
// 尽可能【并行处理数据】
// assign spe_result_o = spe_data_i + spe_data_i;

// max 32
wire [5:0] temp [31:0];

genvar i;
generate
    for(i = 0; i < 16; i = i + 1)
    begin
        assign temp[i]  = spe_data_i[i+i]  + spe_data_i[i+i+1];
    end
endgenerate

generate
    for(i = 0; i < 8; i = i + 1)
    begin
        assign temp[i+16] = temp[2*i]  + temp[2*i + 1];
    end
endgenerate

// group 1, number = 16
// assign temp[0]  = spe_data_i[0]  + spe_data_i[1];
// assign temp[1]  = spe_data_i[2]  + spe_data_i[3];
// assign temp[2]  = spe_data_i[4]  + spe_data_i[5];
// assign temp[3]  = spe_data_i[6]  + spe_data_i[7];
// assign temp[4]  = spe_data_i[8]  + spe_data_i[9];
// assign temp[5]  = spe_data_i[10] + spe_data_i[11];
// assign temp[6]  = spe_data_i[12] + spe_data_i[13];
// assign temp[7]  = spe_data_i[14] + spe_data_i[15];
// assign temp[8]  = spe_data_i[16] + spe_data_i[17];
// assign temp[9]  = spe_data_i[18] + spe_data_i[19];
// assign temp[10] = spe_data_i[20] + spe_data_i[21];
// assign temp[11] = spe_data_i[22] + spe_data_i[23];
// assign temp[12] = spe_data_i[24] + spe_data_i[25];
// assign temp[13] = spe_data_i[26] + spe_data_i[27];
// assign temp[14] = spe_data_i[28] + spe_data_i[29];
// assign temp[15] = spe_data_i[30] + spe_data_i[31];


// group 2, number = 8
// assign temp[16] = temp[0]  + temp[1];
// assign temp[17] = temp[2]  + temp[3];
// assign temp[18] = temp[4]  + temp[5];
// assign temp[19] = temp[6]  + temp[7];
// assign temp[20] = temp[8]  + temp[9];
// assign temp[21] = temp[10] + temp[11];
// assign temp[22] = temp[12] + temp[13];
// assign temp[23] = temp[14] + temp[15];


// group 3, number = 4
assign temp[24] = temp[16] + temp[17];
assign temp[25] = temp[18] + temp[19];
assign temp[26] = temp[20] + temp[21];
assign temp[27] = temp[22] + temp[23];

// group 4, number = 2
assign temp[28] = temp[24] + temp[25];
assign temp[29] = temp[26] + temp[27];

// group 5, number = 1
assign temp[30] = temp[28] + temp[29];


// final
assign spe_result_o = {26'b0, temp[30]};

endmodule
