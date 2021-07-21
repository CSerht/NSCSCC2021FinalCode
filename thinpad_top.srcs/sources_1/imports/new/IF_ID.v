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

           input wire [31:0] inst_i,
           input wire [31:0] pc_i,

           output reg [31:0] inst_o,
           output reg [31:0] pc_o
       );

always@(posedge clk)
begin
    if(rst_n == `rst_enable)
    begin
        inst_o <= 32'b0;
        pc_o   <= 32'b0;
    end
    else if(if_id_w_i == `if_id_write_enable)
    begin
        inst_o <= inst_i;
        pc_o   <= pc_i;
    end
    else
    begin
        ; // no operation
    end
end

endmodule
