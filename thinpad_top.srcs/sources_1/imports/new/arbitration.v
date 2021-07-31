`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/23 15:23:22
// Design Name:
// Module Name: arbitration
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 仲裁模块，确定数据的目标和来源（BaseRAM、ExtRAM、Serial Port）
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "define.v"
module arbitration(
           input wire rst_n,
           // from CPU

           // for ext ram [实际数据去向是3选1]
           input wire [1:0] mode_i,
           // 以下三个均高电平有效
           input wire data_w_i,
           input wire data_r_i,
           input wire data_ce_i,


           output wire ram_busy_o,
           output wire data_r_finish_o,
           output wire data_w_finish_o,


           input wire [31:0] data_addr_i,   // 来自CPU的数据虚拟地址
           input wire [31:0] data_i,        // 待写入的数据
           (*mark_debug = "true"*)output reg [31:0] data_o,        // 读取到的数据

           // for base ram
           input wire [31:0] pc_i,
           input wire inst_w_i,
           input wire inst_r_i,
           input wire inst_ce_i,
           input wire [31:0] inst_i,

           output wire baseram_busy_o,
           output wire inst_r_finish_o,

           output wire baseram_w_finish_o,

           output wire [31:0] inst_o,

           //// ext ram和串口 共用地址线
           output wire [31:0] data_addr_o,
           ///

           // to ExtRAM, data RAM
           input wire [31:0] ext_data_i,

           input wire extram_busy_i,
           input wire extdata_r_finish_i,
           input wire extdata_w_finish_i,

           output wire [31:0] ext_data_o,
           output wire ext_data_w_o,
           output wire ext_data_r_o,
           //     output wire [1:0] ext_mode_o,
           output wire [3:0] ext_data_be_o,

           output wire ext_data_ce_o,


           // to Serial port Memory
           input wire [31:0] uart_data_i,
           output wire uart_data_r_o,
           output wire uart_data_w_o,
           output wire [31:0] uart_data_o,

           // to BaseRAM, inst RAM
           (*mark_debug = "true"*)input wire  [31:0] base_data_i,

           input wire baseram_busy_i,
           input wire inst_r_finish_i,
           input wire inst_w_finish_i,

        //    input wire baseram_w_finish_i,

           output wire is_read_data_o,

           output wire [31:0] base_addr_o,
           output wire [31:0] base_data_o,
           output wire base_data_w_o,
           output wire base_data_r_o,
           //     output wire [1:0] base_mode_o,
           output wire [3:0] base_data_be_o,

           output wire base_data_ce_o
       );


// 根据地址的值(且必须是 读/写 指令)进行仲裁
(*mark_debug = "true"*)wire [1:0] destination;
assign destination =
       (data_addr_i[31:24] == 8'hBF && (data_w_i || data_r_i)) ?
       `d_serial_memory : // 串口
       (data_addr_i[31:22] == 10'b1000_0000_01 && (data_w_i || data_r_i)) ?
       `d_ext_data_memory : // ext_dataRAM
       (data_addr_i[31:22] == 10'b1000_0000_00 && (data_w_i || data_r_i)) ?
       `d_base_data_memory : // base_instRAM
       `d_other_memory; // 正常取指

// 根据CPU给出的mode处理sel，先集中处理再分流
reg [3:0] sel;
always@(*)
begin
    if(rst_n == `rst_enable)
    begin
        sel <= 4'b0000;
    end
    else if(destination == `d_serial_memory)
    begin
        sel <= 4'b0000;
    end
    else if(mode_i == `word_mode)
    begin
        sel <= 4'b0000;
    end
    else if(mode_i == `byte_mode)
    begin
        case(data_addr_i[1:0])
            2'b00:
                sel <= 4'b1110;
            2'b01:
                sel <= 4'b1101;
            2'b10:
                sel <= 4'b1011;
            2'b11:
                sel <= 4'b0111;
            default:
                sel <= 4'b0000;
        endcase
    end
    else
    begin
        sel <= 4'b0000;
    end
end

// 根据sel结果转换要写入的数据
reg [31:0] data_i_convert;
always @(*)
begin
    case(sel)
        4'b0000:
            data_i_convert <= data_i;
        4'b0111:
            data_i_convert <= {data_i[7:0], 24'h00_0000};
        4'b1011:
            data_i_convert <= {8'h00, data_i[7:0], 16'h0000};
        4'b1101:
            data_i_convert <= {16'h0000, data_i[7:0], 8'h00};
        4'b1110:
            data_i_convert <= {24'h00_0000, data_i[7:0]};
        default:
            data_i_convert <= 32'h0000_0000; // 其他情况非法
    endcase
end


//////////////////////////////////////////////////////////
//////////////  extRAM、baseRAM和串口的仲裁  //////////////
//////////////////////////////////////////////////////////
//  1. 数据的交互根据地址决定
//  2. 数据最终只能流向3方中的1方【类似于解复用器】
//  2. 1方根据CPU传递决定，另外2方全部disable
//
//               / | =>
//           => |  | =>
//               \ | =>
//                ▲
//                |
//////////////////////////////////////////////////////////

// 串口和ext_dataRAM的共用地址线
assign data_addr_o = data_addr_i;

// ext/data RAM output
// assign ext_mode_o   =
//        (destination == `d_ext_data_memory) ? mode_i :
//        `byte_mode;

assign ext_data_be_o   =
       (destination == `d_ext_data_memory) ? sel :
       4'b0000;

////////

assign ext_data_w_o =
       (destination == `d_ext_data_memory) ? data_w_i :
       `data_w_disable;

assign ext_data_r_o =
       (destination == `d_ext_data_memory) ? data_r_i :
       `data_r_disable;

assign ext_data_ce_o=
       (destination == `d_ext_data_memory) ? data_ce_i :
       0;

assign ext_data_o   =
       (destination == `d_ext_data_memory) ? data_i_convert :
       0;


// serial memory output
assign uart_data_r_o =
       (destination == `d_serial_memory) ? data_r_i :
       `data_r_disable;

assign uart_data_w_o =
       (destination == `d_serial_memory) ? data_w_i :
       `data_w_disable;

assign uart_data_o   =
       (destination == `d_serial_memory) ? data_i :
       0;


/////////////////////////////////////////////////////////
///////////////  extRAM 和 baseRAM 的仲裁 //////////////// 二选一选择器
/////////////////////////////////////////////////////////
// 如果数据目标是baseRAM，则CPU取指暂停一个时钟周期
// 否则（目标是extRAM），则正常取指令，正常读写extRAM数据
/////////////////////////////////////////////////////////

assign base_addr_o = (destination == `d_base_data_memory) ? data_addr_i : pc_i;

// assign base_mode_o = (destination == `d_base_data_memory) ? mode_i      : `word_mode;
assign base_data_be_o = (destination == `d_base_data_memory) ? sel : 4'b0000;
///////


assign base_data_w_o = (destination == `d_base_data_memory)?data_w_i    : inst_w_i;
assign base_data_r_o = (destination == `d_base_data_memory)?data_r_i    : inst_r_i;
assign base_data_ce_o= (destination == `d_base_data_memory)?data_ce_i   : inst_ce_i;
assign base_data_o = (destination == `d_base_data_memory) ? data_i_convert : inst_i;

assign is_read_data_o = (destination == `d_base_data_memory)?
       //    `read_data_from_baseram : `read_data_not_from_baseram;
       data_r_i : `read_data_not_from_baseram;

///////////////////////////////////////
/////////// data to cpu /////////////// 多路选择器
///////////////////////////////////////

////////////////////
// 处理发给CPU的数据
////////////////////
wire [31:0] data_temp_o; // 含义zz的数据
assign data_temp_o =
       (destination == `d_serial_memory) ? uart_data_i :
       (destination == `d_ext_data_memory) ? ext_data_i :
       base_data_i;

always @(*)
begin
    case(sel)
        4'b0000:
            data_o <= data_temp_o;
        4'b0111:
            data_o <= {{24{data_temp_o[31]}}, data_temp_o[31:24]};
        4'b1011:
            data_o <= {{24{data_temp_o[23]}}, data_temp_o[23:16]};
        4'b1101:
            data_o <= {{24{data_temp_o[15]}}, data_temp_o[15:8]};
        4'b1110:
            data_o <= {{24{data_temp_o[7]}}, data_temp_o[7:0]};
        default:
            data_o <= 32'h0000_0000;
    endcase
end

// 串口读写一个周期完成，CPU不暂停，需要添加额外的逻辑，识别串口访问让3个信号无效
assign ram_busy_o =
       (destination == `d_serial_memory) ?   `invalid :
       (destination == `d_ext_data_memory) ? extram_busy_i :
       baseram_busy_i;

assign data_r_finish_o =
       (destination == `d_serial_memory) ?    `invalid :
       (destination == `d_ext_data_memory) ? extdata_r_finish_i :
       inst_r_finish_i;

assign data_w_finish_o =
       (destination == `d_serial_memory) ?    `invalid :
       (destination == `d_ext_data_memory) ? extdata_w_finish_i :
       inst_w_finish_i;

// // 读取的数据来源于3个位置
// assign data_o =
//        (destination == `d_serial_memory) ? uart_data_i :
//        (destination == `d_ext_data_memory) ? ext_data_i :
//        base_data_i;


// 目前来说，指令一定来自于BaseRAM
assign inst_o = (destination == `d_base_data_memory) ? 32'h0000_0000 : base_data_i;
assign inst_r_finish_o =
       (destination == `d_base_data_memory) ?
       `inst_read_unfinish : inst_r_finish_i;
// 直连获取baseram_ctl信号
assign baseram_w_finish_o = inst_w_finish_i;

endmodule
