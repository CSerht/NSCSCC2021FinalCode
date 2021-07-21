`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/06/22 15:14:30
// Design Name:
// Module Name: base_ram_ctl
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

// 测试base RAM的使用，指令存储器
// 特别注意inout双向数据总线与控制信号的配合！
// 暂时不管两类虚拟地址，涉及到80000000和A0000000的识别，需要仲裁
// 【inout的时候，行为建模不大好用！】
// 对于组合逻辑，能用数据流建模，就别用行为建模！
module base_ram_ctl(
           // from CPU IF stage
           input wire inst_w_i, // 写使能，高有效，暂时恒有效
           input wire inst_r_i, // 读使能，高有效，暂时恒有效
           input wire inst_ce_i, // 芯片使能，高有效，暂时恒有效

           input  wire [31:0] pc_i,   // pc,指令虚拟地址
           input  wire [31:0] inst_i, // 要写入的指令，暂时恒无效
           output wire [31:0] inst_o, // 读取到的指令，暂时恒有效

           // from Base RAM, inst RAM (*mark_debug = "true"*)
           inout wire[31:0] base_ram_data_io,  //BaseRAM数据，低8位与CPLD串口控制器共享，暂时恒输出

           output wire [19:0] base_ram_addr_o, //BaseRAM地址
           output wire [3:0] base_ram_be_o,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
           output wire  base_ram_ce_o,       //BaseRAM片选，低有效
           output wire  base_ram_oe_o,       //BaseRAM读使能，低有效
           output wire  base_ram_we_o        //BaseRAM写使能，低有效
       );

// write data to RAM when inst_w_i equals 1, inout -- output
assign base_ram_data_io =
       (inst_w_i == 1)? inst_i:32'hzzzz_zzzz;
// read data from RAM, inout -- input
assign inst_o = base_ram_data_io; // 仅读取模式下才起作用

// 假设pc的范围是0x8000_0000 ~ 9FFF_FFFF，求物理地址
wire [31:0] pc_i_physical = {3'b000, pc_i[28:0]};

assign base_ram_addr_o = pc_i_physical[21:2];
assign base_ram_be_o = 4'b0000;
assign base_ram_oe_o = !inst_r_i;
assign base_ram_we_o = !inst_w_i;

// RAM使能 == 0 时无效,若为1，则：11 || 00 || ce使能 == 0 时无效，否则有效
assign base_ram_ce_o = (!inst_ce_i) ||
       (inst_ce_i && inst_r_i && inst_w_i) || (inst_ce_i && !inst_r_i && !inst_w_i);


///////////////////////
///// 下面的为啥不对？嗯？？？？以后再说吧……迷惑
// always@(*)
// begin
//     case({inst_w_i,inst_r_i})
//         2'b00:
//         begin
//             base_ram_we_o <= 1;
//             base_ram_ce_o <= 1;
//             base_ram_oe_o <= 1;
//             base_ram_be_o <= 4'b0000;
//             base_ram_addr_o <= 0;
//         end
//         2'b01: // read only
//         begin
//             base_ram_we_o <= 1;
//             base_ram_ce_o <= 0;
//             base_ram_oe_o <= 0;
//             // 此处，be == 0时，SRAM地址 = PC[:2]
//             // PC物理地址是字节编址，SRAM不是！得看实际设计。
//             base_ram_be_o <= 4'b0000;
//             base_ram_addr_o <= pc_i_physical[21:2];
//             inst_o <= temp_inst;
//         end
//         2'b10: // write only，暂时默认只有读指令，先不管读写冲突
//         begin
//             base_ram_we_o <= 0;
//             base_ram_ce_o <= 0;
//             base_ram_oe_o <= 0;
//             base_ram_be_o <= 4'b0000;
//             base_ram_addr_o <= pc_i_physical[21:2];
//         end
//         2'b11:
//         begin
//             base_ram_we_o <= 0;
//             base_ram_ce_o <= 1;
//             base_ram_oe_o <= 1;
//             base_ram_be_o <= 4'b0000;
//             base_ram_addr_o <= 0;
//         end

//         default:
//         begin
//             base_ram_we_o <= 1;
//             base_ram_ce_o <= 1;
//             base_ram_oe_o <= 1;
//             base_ram_be_o <= 4'b0000;
//             base_ram_addr_o <= 0;
//         end
//     endcase
// end


endmodule
