`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/06 09:05:58
// Design Name:
// Module Name: MEM_WB
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

module MEM_WB(
           input wire clk,
           input wire rst_n,
           input wire mem_wb_w_i,

           input wire [31:0] data_result_i,
           (*mark_debug = "true"*)output reg [31:0] data_result_o,

           input wire [4:0] rW_i,
           (*mark_debug = "true"*)output reg [4:0] rW_o,

           /* jump identifier */
           input wire [31:0] jal_i,
           output reg [31:0] jal_o,

           /* control */
           // MEM // for data hazard
           input wire data_r_i,
           output reg data_r_o,

           // WB //
           input reg_we_i,
           input wire jal_en_i,
           (*mark_debug = "true"*)output reg reg_we_o,
           output reg jal_en_o
       );

always@(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        data_result_o <= 0;
        rW_o <= 0;

        /* jump identifier */
        jal_o <= 0;

        /* control */
        // MEM // for data hazard
        data_r_o <= `data_r_disable;

        // WB //
        reg_we_o <= `reg_write_disable;
        jal_en_o <= `jal_disable;
    end
    else if(mem_wb_w_i == `mem_wb_write_enable)
    begin
        data_result_o <= data_result_i;
        rW_o <= rW_i;

        /* jump identifier */
        jal_o <= jal_i;

        /* control */
        // MEM // for data hazard
        data_r_o <= data_r_i;

        // WB //
        reg_we_o <= reg_we_i;
        jal_en_o <= jal_en_i;
    end
    else
    begin
        ;
    end
end

endmodule
