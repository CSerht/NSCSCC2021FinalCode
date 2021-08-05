`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/20 22:14:03
// Design Name:
// Module Name: stall_pipeline
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 针对跳转指令/运算指令，被load指令束缚，需要暂停流水线
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "../define.v"
module stall_pipeline(
           input wire id_ex_data_r_i,
           input wire [4:0] id_ex_rd_i,

           input wire ex_mem_data_r_i,
           input wire [4:0] ex_mem_rd_i,

           input wire is_jump_inst_i,

           input wire [4:0] if_id_rs_i,
           input wire [4:0] if_id_rt_i,

           input wire if_id_data_r_i,
           input wire if_id_data_w_i,

           output wire pc_w_o,
           output wire if_id_w_o,
           output wire clear_o
       );

// [lw; bne/add;] stall 1 cycle
// 注意可能的误识别：（lw/sw的base字段，是bne的rs字段）
// lw    v0,0(a0)
// lw/sw v0,-4(a1)
// 补充逻辑：if_id_data_r/w_i disable
reg pc_w_o_1;
reg if_id_w_o_1;
reg clear_o_1;
always @(*)
begin
    if (
        (id_ex_data_r_i == `data_r_enable) &&
        (id_ex_rd_i != `zero_register)     &&
        (
            (id_ex_rd_i == if_id_rs_i) ||
            (id_ex_rd_i == if_id_rt_i)
        ) &&
        (if_id_data_r_i == `data_r_disable) &&
        (if_id_data_w_i == `data_w_disable)
    )
    begin
        // stall pipeline
        pc_w_o_1     <= `pc_write_disable;
        if_id_w_o_1  <= `if_id_write_disable;
        clear_o_1    <= `clear_enable;
    end
    else
    begin
        pc_w_o_1     <= `pc_write_enable;
        if_id_w_o_1  <= `if_id_write_enable;
        clear_o_1    <= `clear_disable;
    end
end

// [lw; other inst; bne;] stall 1 cycle
reg pc_w_o_2;
reg if_id_w_o_2;
reg clear_o_2;
always @(*)
begin
    if (
        (ex_mem_data_r_i == `data_r_enable) &&
        (ex_mem_rd_i != `zero_register)     &&
        (
            (ex_mem_rd_i == if_id_rs_i) ||
            (ex_mem_rd_i == if_id_rt_i)
        )
    )
    begin
        // stall pipeline
        pc_w_o_2     <= `pc_write_disable;
        if_id_w_o_2  <= `if_id_write_disable;
        clear_o_2    <= `clear_enable;
    end
    else
    begin
        pc_w_o_2     <= `pc_write_enable;
        if_id_w_o_2  <= `if_id_write_enable;
        clear_o_2    <= `clear_disable;
    end
end

// result
/// NOTE: [lw; other inst; not jump inst;] not stall
/// 仅识别跳转指令，不会被误识别
assign pc_w_o = (!is_jump_inst_i && pc_w_o_1) ||
       (is_jump_inst_i && pc_w_o_1 && pc_w_o_2);

assign if_id_w_o = (!is_jump_inst_i && if_id_w_o_1) ||
       (is_jump_inst_i && if_id_w_o_1 && if_id_w_o_2);
// clear logic is different
assign clear_o = clear_o_1 ||
       (is_jump_inst_i && !clear_o_1 && clear_o_2);

endmodule
