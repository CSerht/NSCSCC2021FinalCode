`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/22 14:35:32
// Design Name:
// Module Name: pc
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

module pc(
           input wire clk,
           input wire rst_n,

           input wire [31:0] pc_i,
           input wire pc_w_i,

           (*mark_debug = "true"*)output reg [31:0] pc_o
       );

// reg pc_ce;

// // reset pc?
// always@(*)
// begin
//     if(rst_n == `rst_enable)
//         pc_ce = `pc_disable;
//     else
//         pc_ce = `pc_enable;
// end

// // change: the value of pc
// always@(posedge clk)
// begin
//     if(pc_ce == `pc_enable)
//         pc_o <= pc_i;
//     else
//         pc_o <= `initial_pc;
// end

always @(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        pc_o <= `initial_pc;
    end
    else if(pc_w_i == `pc_write_enable)
    begin
        pc_o <= pc_i;
    end
    else
    begin
        ; // keep current pc value constant
    end
end

endmodule
