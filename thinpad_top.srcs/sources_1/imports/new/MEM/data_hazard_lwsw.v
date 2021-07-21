`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/15 18:49:55
// Design Name:
// Module Name: data_hazard_lwsw
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 解决 lw/lb $1,($2) sw/sb $1,($3) 数据冒险问题
//              需要唯一地识别出 lw在WB阶段 && sw在MEM阶段
//              特征：lw:data_r enable; sw:data_w enable
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "../define.v"

module data_hazard_lwsw(
           // for sw instruction in EX stage
           input wire [4:0] ex_mem_rd_i,  // store rt field (source)
           input wire ex_mem_data_w_i,    // sw/sb data write enable

           // for lw instruction in MEM stage
           input wire [4:0] mem_wb_rd_i, // load rt field (dentisnan)
           input wire mem_wb_data_r_i,   // lw/lb read data enable

           // output
           output reg bypass_mem_data_o
       );

always@(*)
begin
    if(
        (mem_wb_rd_i != `zero_register) &&
        (ex_mem_data_w_i == `data_w_enable)  &&
        (mem_wb_data_r_i == `data_r_enable)  &&
        (ex_mem_rd_i == mem_wb_rd_i)
    )
    begin
        bypass_mem_data_o <= `mem_data_from_mem_wb;
    end
    else
    begin
        bypass_mem_data_o <= `mem_data_from_ex_mem;
    end
end

endmodule
