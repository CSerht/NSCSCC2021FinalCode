`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/27 11:57:32
// Design Name:
// Module Name: loaddata_stall
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 当load指令处于MEM的时候，整个流水线暂停一拍，等待数据从SRAM读出
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "../define.v"
module loaddata_stall(
           //    input wire clk,
           //    input wire rst_n,

           input wire ex_mem_data_r_i,
           input wire data_r_finish_i,
           input wire [31:0] data_addr_i,

           output reg pc_w_o,
           output reg if_id_w_o,
           output reg id_ex_w_o,
           output reg ex_mem_w_o,
           output reg mem_wb_w_o
       );



// 如果是load指令，且不读串口，不读加速器，则需要暂停，直到read_finish_enable
wire load_stall =
     (ex_mem_data_r_i == `data_r_enable) &&
     (data_addr_i[31:24] != 8'hBF)       &&
     (data_addr_i[31:24] != 8'hFF);

always@(*)
begin
    if(load_stall && data_r_finish_i == `data_read_unfinish)
    begin
        pc_w_o     <= `pc_write_disable;
        if_id_w_o  <= `if_id_write_disable;
        id_ex_w_o  <= `id_ex_write_disable;
        ex_mem_w_o <= `ex_mem_write_disable;
        mem_wb_w_o <= `mem_wb_write_disable;
    end
    else // if((load_stall && data_r_finish_i == `data_read_finish))
    begin
        pc_w_o     <= `pc_write_enable;
        if_id_w_o  <= `if_id_write_enable;
        id_ex_w_o  <= `id_ex_write_enable;
        ex_mem_w_o <= `ex_mem_write_enable;
        mem_wb_w_o <= `mem_wb_write_enable;
    end
end

endmodule
