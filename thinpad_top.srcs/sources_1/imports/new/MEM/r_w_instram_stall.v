`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/24 22:48:28
// Design Name:
// Module Name: r_w_instram_stall
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 当 CPU 向 base_inst RAM 读/写 数据的时候
//              的流水线暂停逻辑
//               启动Fast Mode之后，就不需要暂停了
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////
// 不能弃用的啊.......
//////////////////////////////////////
`include "../define.v"
module r_w_instram_stall(
           input wire fast_mode_start_i,

           input wire ex_mem_data_w_i,
           input wire ex_mem_data_r_i,
           input wire [31:0] data_addr_i,

           output wire pc_w_o,
           output wire if_id_w_o,
           output wire clear_o
       );

// Normal Mode下，为1则说明数据会读/写到instRAM
// Fast Mode下不暂停
wire is_data_to_inst_ram = (fast_mode_start_i == `normal_mode)?
     (data_addr_i[31:22] == 10'b1000_0000_00 && ex_mem_data_r_i) :
     0;
// (ex_mem_data_w_i || ex_mem_data_r_i);

assign pc_w_o    = !is_data_to_inst_ram;
assign if_id_w_o = !is_data_to_inst_ram;
assign clear_o   = is_data_to_inst_ram;

endmodule
