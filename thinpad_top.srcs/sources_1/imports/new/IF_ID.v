`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/06 09:05:01
// Design Name:
// Module Name: IF_ID
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

`include "define.v"

module IF_ID(
           input wire clk,
           input wire rst_n,

           input wire if_id_w_i,
           input wire if_id_clear_i,

           input wire [31:0] inst_i,
           input wire [31:0] pc_i,

           (*mark_debug = "true"*)output reg [31:0] inst_o,
           output reg [31:0] pc_o
       );

always@(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        inst_o <= 32'b0;
        pc_o   <= 32'b0;
    end
    else if(if_id_w_i == `if_id_write_enable &&
            if_id_clear_i == `clear_disable)
    begin
        inst_o <= inst_i;
        pc_o   <= pc_i;
    end // clear 优先级 比 write 低
    else if(if_id_w_i == `if_id_write_enable &&
            if_id_clear_i == `clear_enable)
    begin
        inst_o <= 32'h0000_0000; // insert nop
    end
    else
    begin
        ;
    end
end

endmodule
