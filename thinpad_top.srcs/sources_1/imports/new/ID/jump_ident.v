`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/21 21:42:09
// Design Name:
// Module Name: jump_ident
// Project Name:
// Target Devices:
// Tool Versions:
// Description: jump instruction decision in ID stage
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "../define.v"

module jump_ident(
        //    input wire fast_mode_start_i,

           input wire [5:0] op,
           input wire [31:0] pc,
           input wire [25:0] offset,
           input wire [31:0] dataA,
           input wire [31:0] dataB,

           output reg isjump_o,
           output reg jal_en_o,

           output reg [31:0] pc_o,
           output reg [31:0] jal_o, // jal 执行之后保持的地址 pc+8

           output reg is_jump_inst_o
       );

// beq bne
wire [31:0] data_sub = dataA - dataB;
// b inst target
wire [31:0] b_target_offset = { {15{offset[15]}}, offset[14:0], 2'b00 };
// pc + 4
// wire [31:0] pc_add_4 = pc + 4;
// wire [31:0] pc_add_4 = pc; // 【访存需要2周期就不用+4了】

// normal Mode下，pc+4与指令对应
// Fast Mode下，pc+4和指令一一对应
wire [31:0] pc_add = pc;

// 注意部分指令的无条件跳转！
always@(*)
begin
    case(op) // 注意是 pc + 4，因为延迟槽指令必执行
        `jr_inst_op: // NOTE: jr_inst_op == Rtype_inst_op
        begin
            if(offset[5:0] == `jr_func)
            begin
                isjump_o <= 1;
                jal_en_o <= 0;
                pc_o <= dataA;
                jal_o <= 0;
                is_jump_inst_o <= `is_jump_inst;
            end
            else
            begin
                isjump_o <= `jump_disable;
                jal_en_o <= `jal_disable;
                pc_o <= 0;
                jal_o <= 0;
                is_jump_inst_o <= `is_not_jump_inst;
            end
        end
        `beq_inst_op:
        begin
            isjump_o <= (data_sub == 0);
            jal_en_o <= 0;
            pc_o <= pc_add + b_target_offset;
            jal_o <= 0;
            is_jump_inst_o <= `is_jump_inst;
        end
        `bne_inst_op:
        begin
            isjump_o <= (data_sub != 0);
            jal_en_o <= 0;
            pc_o <= pc_add + b_target_offset;
            jal_o <= 0;
            is_jump_inst_o <= `is_jump_inst;
        end
        // ################ NOTE: condition is sign bit is 0 but value not zero.
        `bgtz_inst_op:
        begin
            isjump_o <= (dataA[31] == 0 && dataA != 0);
            jal_en_o <= 0;
            pc_o <= pc_add + b_target_offset;
            jal_o <= 0;
            is_jump_inst_o <= `is_jump_inst;
        end
        // ################ NOTE: condition is sign bit is 0.
        // dataA此时是带符号数！
        `bgez_inst_op:
        begin
            isjump_o <= (dataA[31] == 0);
            jal_en_o <= 0;
            pc_o <= pc_add + b_target_offset;
            jal_o <= 0;
            is_jump_inst_o <= `is_jump_inst;
        end
        `j_inst_op:
        begin
            isjump_o <= 1;
            jal_en_o <= 0;
            pc_o <= { pc_add[31:28], offset, 2'b00 };
            jal_o <= 0;
            is_jump_inst_o <= `is_jump_inst;
        end
        `jal_inst_op:
        begin
            isjump_o <= 1;
            jal_en_o <= 1;
            pc_o <= { pc_add[31:28], offset, 2'b00 };
            jal_o <= pc_add + 4; // 当前pc值就是延迟槽指令的pc
            is_jump_inst_o <= `is_jump_inst;
        end
        default:
        begin
            isjump_o <= `jump_disable;
            jal_en_o <= `jal_disable;
            pc_o <= 0;
            jal_o <= 0;
            is_jump_inst_o <= `is_not_jump_inst;
        end
    endcase
end

endmodule
