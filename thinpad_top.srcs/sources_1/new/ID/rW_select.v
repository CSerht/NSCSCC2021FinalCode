`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/21 20:45:04
// Design Name:
// Module Name: rW_select
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


`include "../define.v"

module rW_select(
           // control
           input wire reg_dst_i,

           input wire [4:0] rd,
           input wire [4:0] rt,

           output reg [4:0] rW_o
       );

always@(*)
begin
    if(reg_dst_i == `reg_dst_rd)
        rW_o <= rd;
    else if(reg_dst_i == `reg_dst_rt)
        rW_o <= rt;
end

endmodule
