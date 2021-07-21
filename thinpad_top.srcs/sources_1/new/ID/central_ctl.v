`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/21 20:50:22
// Design Name:
// Module Name: central_ctl
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

module central_ctl(
           input wire [5:0] op,

           /*** ID ***/
           output reg reg_dst_o,
           output reg zero_sign_ext_o,

           /*** EX ***/
           output reg alu_src_o,
           output reg [3:0] alu_op_o,

           /*** MEM ***/
           output reg [1:0] mode_o,
           output reg data_w_o,
           output reg data_r_o,
           output reg mem_reg_o,

           /*** WB ***/
           output reg reg_we_o
       );

always@(*)
begin
    case (op)
        `Rtype_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rd;
            zero_sign_ext_o <= `imm_zero_extension;

            /* EX */
            alu_op_o        <= `Rtype_alu_op;
            alu_src_o       <= `B_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `mul_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rd;
            zero_sign_ext_o <= `imm_zero_extension;

            /* EX */
            alu_op_o        <= `mul_alu_op;
            alu_src_o       <= `B_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `lui_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_zero_extension;

            /* EX */
            alu_op_o        <= `lui_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `andi_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_zero_extension;

            /* EX */
            alu_op_o        <= `andi_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `ori_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_zero_extension;

            /* EX */
            alu_op_o        <= `ori_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `xori_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_zero_extension;

            /* EX */
            alu_op_o        <= `xori_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `addi_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_sign_extension;

            /* EX */
            alu_op_o        <= `add_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `addiu_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_sign_extension;

            /* EX */
            alu_op_o        <= `add_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `lb_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_sign_extension;

            /* EX */
            alu_op_o        <= `add_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_enable;
            mem_reg_o       <= `data_from_mem;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `lw_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_sign_extension;

            /* EX */
            alu_op_o        <= `add_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `word_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_enable;
            mem_reg_o       <= `data_from_mem;
            /* WB */
            reg_we_o        <= `reg_write_enable;
        end
        `sb_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_sign_extension;

            /* EX */
            alu_op_o        <= `add_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_enable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_disable;
        end
        `sw_inst_op:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rt;
            zero_sign_ext_o <= `imm_sign_extension;

            /* EX */
            alu_op_o        <= `add_alu_op;
            alu_src_o       <= `imm_calculate;
            /* MEM */
            mode_o          <= `word_mode;
            data_w_o        <=  `data_w_enable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_disable;
        end
        default:
        begin
            /* ID */
            reg_dst_o       <= `reg_dst_rd;
            zero_sign_ext_o <= `imm_zero_extension;

            /* EX */
            alu_op_o        <= `other_alu_op;
            alu_src_o       <= `B_calculate;
            /* MEM */
            mode_o          <= `byte_mode;
            data_w_o        <=  `data_w_disable;
            data_r_o        <= `data_r_disable;
            mem_reg_o       <= `data_from_reg;
            /* WB */
            reg_we_o        <= `reg_write_disable;
        end
    endcase
end
endmodule
