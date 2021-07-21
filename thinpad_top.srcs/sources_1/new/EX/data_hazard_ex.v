`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/06 14:05:44
// Design Name:
// Module Name: data_hazard_ex
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 位于EX阶段的数据冒险旁路处理单元
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "../define.v"

module data_hazard_ex(
           input wire ex_mem_w_i, // write enable signal
           input wire mem_wb_w_i,
           input wire [4:0] ex_mem_rd_i,
           input wire [4:0] mem_wb_rd_i,

           input wire [4:0] id_ex_rs_i,
           input wire [4:0] id_ex_rt_i,

           output reg [1:0] bypass_a_o,
           output reg [1:0] bypass_b_o
       );


// bypass A
always@(*)
begin
    if(
        (ex_mem_w_i == `reg_write_enable) &&
        (ex_mem_rd_i != `zero_register) &&
        (ex_mem_rd_i == id_ex_rs_i)
    )
    begin
        bypass_a_o <= `data_from_EX_MEM;
    end
    else if(
        (mem_wb_w_i == `reg_write_enable) &&
        (mem_wb_rd_i != `zero_register) &&
        (mem_wb_rd_i == id_ex_rs_i)
    )
    begin
        bypass_a_o <= `data_from_MEM_WB;
    end
    else
    begin
        bypass_a_o <= `data_from_regfile;
    end
end


// bypass B
always@(*)
begin
    if(
        (ex_mem_w_i == `reg_write_enable) &&
        (ex_mem_rd_i != `zero_register) &&
        (ex_mem_rd_i == id_ex_rt_i)
    )
    begin
        bypass_b_o <= `data_from_EX_MEM;
    end
    else if(
        (mem_wb_w_i == `reg_write_enable) &&
        (mem_wb_rd_i != `zero_register) &&
        (mem_wb_rd_i == id_ex_rt_i)
    )
    begin
        bypass_b_o <= `data_from_MEM_WB;
    end
    else
    begin
        bypass_b_o <= `data_from_regfile;
    end
end

endmodule
