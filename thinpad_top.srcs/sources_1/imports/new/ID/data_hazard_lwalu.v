`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/20 15:51:05
// Design Name:
// Module Name: data_hazard_lwalu
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 解决加载指令导致流水线暂停的数据冒险
//              lw/lb $1,0($4)
//              add $2,$1,$3
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

// 弃用！
// `include "../define.v"
// module data_hazard_lwalu(
//            input wire id_ex_data_r_i, // load instruction
//            input wire [4:0] id_ex_rd_i,
//            input wire [4:0] if_id_rs_i,
//            input wire [4:0] if_id_rt_i,

//            output reg pc_w_o,
//            output reg if_id_w_o,
//            output reg data_clear_o
//        );

// always @(*)
// begin
//     if (
//         (id_ex_data_r_i == `data_r_enable) &&
//         (id_ex_rd_i != `zero_register)     &&
//         (
//             (id_ex_rd_i == if_id_rs_i) ||
//             (id_ex_rd_i == if_id_rt_i)
//         )
//     )
//     begin
//         // stall pipeline
//         pc_w_o          <= `pc_write_disable;
//         if_id_w_o       <= `if_id_write_disable;
//         data_clear_o    <= `data_clear_enable;
//     end
//     else
//     begin
//         pc_w_o          <= `pc_write_enable;
//         if_id_w_o       <= `if_id_write_enable;
//         data_clear_o    <= `data_clear_disable;
//     end
// end

// endmodule
