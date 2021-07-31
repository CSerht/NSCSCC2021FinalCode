`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/06 09:05:39
// Design Name:
// Module Name: EX_MEM
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

module EX_MEM(
           input wire clk,
           input wire rst_n,
           input wire ex_mem_w_i,

           input wire [31:0] data_to_mem_i,
           input wire [31:0] alu_result_i,
           input wire [4:0] rW_i,

           output reg [31:0] data_to_mem_o,
           output reg [31:0] alu_result_o,
           output reg [4:0] rW_o,

           /* jump identifier */
           input wire [31:0] jal_i,
           output reg [31:0] jal_o,

           /* control */
           // MEM //
           input wire [1:0] mode_i,
           input wire data_w_i,
           input wire data_r_i,
           input wire mem_reg_i,
           input wire is_jump_inst_i,

           output reg [1:0] mode_o,
           output reg data_w_o,
           output reg data_r_o,
           output reg mem_reg_o,
           output reg is_jump_inst_o,

           // WB //
           input wire reg_we_i,
           input wire jal_en_i,
           output reg reg_we_o,
           output reg jal_en_o
       );

always@(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        data_to_mem_o   <= 0;
        alu_result_o    <= 0;
        rW_o            <= 0;

        /* jump identifier */
        jal_o <= 0;

        /* control */
        // MEM //
        mode_o      <= `byte_mode;
        data_w_o    <= `data_w_disable;
        data_r_o    <= `data_r_disable;
        mem_reg_o   <= `data_from_reg;
        is_jump_inst_o <= `is_not_jump_inst;

        // WB //
        reg_we_o <= `reg_write_disable;
        jal_en_o <= `jal_disable;
    end
    else if(ex_mem_w_i == `ex_mem_write_enable)
    begin
        data_to_mem_o   <= data_to_mem_i;
        if(jal_en_i == `jal_disable)
        begin
            alu_result_o    <= alu_result_i;
        end
        else
        begin
            alu_result_o  <= jal_i;
        end
        rW_o            <= rW_i;

        /* jump identifier */
        jal_o <= jal_i;

        /* control */
        // MEM //
        mode_o      <= mode_i;
        data_w_o    <= data_w_i;
        data_r_o    <= data_r_i;
        mem_reg_o   <= mem_reg_i;
        is_jump_inst_o <= is_jump_inst_i;

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
