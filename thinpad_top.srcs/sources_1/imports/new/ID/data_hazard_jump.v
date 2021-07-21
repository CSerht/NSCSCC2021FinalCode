`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/15 18:49:29
// Design Name:
// Module Name: data_hazard_jump
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
module data_hazard_jump(
           // source
           input wire [4:0] if_id_rs_i,
           input wire [4:0] if_id_rt_i,

           // EX ALU
           input wire id_ex_w_i,
           input wire [4:0] id_ex_rd_i,

           // EX/MEM
           input wire ex_mem_w_i,
           input wire [4:0] ex_mem_rd_i,

           // MEM/WB
           input wire mem_wb_w_i,
           input wire [4:0] mem_wb_rd_i,

           // output
           output reg [1:0] bypass_dataA_o,
           output reg [1:0] bypass_dataB_o
       );

// dataA
always @(*)
begin
    if(
        (id_ex_w_i == `reg_write_enable) &&
        (id_ex_rd_i != `zero_register)   &&
        (id_ex_rd_i == if_id_rs_i)
    )
    begin
        bypass_dataA_o <= `j_data_from_alu_result;
    end
    else if(
        (ex_mem_w_i == `reg_write_enable) &&
        (ex_mem_rd_i != `zero_register)   &&
        (ex_mem_rd_i == if_id_rs_i)
    )
    begin
        bypass_dataA_o <= `j_data_from_ex_mem;
    end
    else if(
        (mem_wb_w_i == `reg_write_enable) &&
        (mem_wb_rd_i != `zero_register)   &&
        (mem_wb_rd_i == if_id_rs_i)
    )
    begin
        bypass_dataA_o <= `j_data_from_mem_wb;
    end
    else
    begin
        bypass_dataA_o <= `j_data_from_regfiles;
    end
end


// dataB
always @(*)
begin
    if(
        (id_ex_w_i == `reg_write_enable) &&
        (id_ex_rd_i != `zero_register)   &&
        (id_ex_rd_i == if_id_rt_i)
    )
    begin
        bypass_dataB_o <= `j_data_from_alu_result;
    end
    else if(
        (ex_mem_w_i == `reg_write_enable) &&
        (ex_mem_rd_i != `zero_register)   &&
        (ex_mem_rd_i == if_id_rt_i)
    )
    begin
        bypass_dataB_o <= `j_data_from_ex_mem;
    end
    else if(
        (mem_wb_w_i == `reg_write_enable) &&
        (mem_wb_rd_i != `zero_register)   &&
        (mem_wb_rd_i == if_id_rt_i)
    )
    begin
        bypass_dataB_o <= `j_data_from_mem_wb;
    end
    else
    begin
        bypass_dataB_o <= `j_data_from_regfiles;
    end
end

endmodule
