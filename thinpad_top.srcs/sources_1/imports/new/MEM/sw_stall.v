`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/08/03 13:22:54
// Design Name:
// Module Name: sw_stall
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 当启动Fast Mode之后，遇到连续store（非串口）需要暂停逻辑
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "../define.v"
module sw_stall(
           input wire id_ex_w_i,
           input wire [31:0] id_ex_data_addr_i,

           input wire if_id_w_i,

           input wire fast_mode_start_i,

           output reg pc_w_o,
           output reg if_id_w_o,
           output reg clear_o
       );

// 为1，说明EX stage的sw的不是写串口，不写加速器，且ID，EX均为store指令
// 需要向中间插入nop
wire stall_sw = if_id_w_i && id_ex_w_i &&
     (id_ex_data_addr_i[31:24] != 8'hBF) &&
     (id_ex_data_addr_i[31:24] != 8'hFF);

always@(*)
begin
    if(fast_mode_start_i == `fast_mode)
    begin
        if(stall_sw)
        begin
            pc_w_o <= `pc_write_disable;
            if_id_w_o <= `if_id_write_disable;
            clear_o <= `clear_enable;
        end
        else
        begin
            pc_w_o <= `pc_write_enable;
            if_id_w_o <= `if_id_write_enable;
            clear_o <= `clear_disable;
        end
    end
    else // normal mode下不会暂停
    begin
        pc_w_o <= `pc_write_enable;
        if_id_w_o <= `if_id_write_enable;
        clear_o <= `clear_disable;
    end
end

endmodule
