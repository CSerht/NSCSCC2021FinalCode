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
           input wire clk,
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

           output wire base_data_ce_o,

           // BRAM and Fast Mode
           /// CPU port
           input wire [31:0] prgm_start_addr_i,
           input wire lock_addr_i,

           input wire fast_mode_start_i,
           input wire bram_w_start_i,
           output wire bram_w_finish_o,

           /// BRAM and baseram_ctl port
           input wire [31:0] bram_data_i,
           output reg [9:0] bram_addr_o,

           input wire bram_w_finish_i,
           output wire fast_mode_start_o,
           output wire bram_w_start_o,
           output reg [31:0] prgm_start_addr_o
       );


// 根据地址的值(且必须是 读/写 指令)进行仲裁
// 10'b1000_0000_01 代表范围 [0x804_*,0x808_*)
// 10'b1000_0000_00 代表范围 [0x800_*,0x804_*)
(*mark_debug = "true"*)wire [1:0] destination;
assign destination =
       (data_addr_i[31:24] == 8'hBF && (data_w_i || data_r_i)) ?
       `d_serial_memory : // 串口
       (data_addr_i[31:22] == 10'b1000_0000_01 && (data_w_i || data_r_i)) ?
       `d_ext_data_memory : // ext_dataRAM  [0x804_*,0x808_*)
       (data_addr_i[31:22] == 10'b1000_0000_00 && (data_w_i || data_r_i)) ?
       `d_base_data_memory : // base_instRAM [0x800_*,0x804_*)
       `d_other_memory; // 正常取指

// assign destination =
//        (data_addr_i[31:24] == 8'hBF && (data_w_i || data_r_i)) ?
//        `d_serial_memory : // 串口
//        ((data_addr_i[31:24] == 8'h80) && (data_addr_i[23:22] >= 2'b01) && (data_addr_i[23:22] < 2'b10) && (data_w_i || data_r_i)) ?
//        `d_ext_data_memory : // ext_dataRAM  [0x804_*,0x808_*) && data_addr_i[31:22] < 10'b1000_0000_10
//        ((data_addr_i[31:24] == 8'h80) && (data_addr_i[23:22] >= 2'b00) && (data_addr_i[23:22] < 2'b01) && (data_w_i || data_r_i)) ?
//        `d_base_data_memory : // base_instRAM [0x800_*,0x804_*) && data_addr_i[31:22] < 10'b1000_0000_01
//        `d_other_memory; // 正常取指

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

// 对于给baseram的端口，d_base_data_memory优先级比fast_mode_start_i高
// 对于给cpu的inst_o端口，则优先级相反
assign base_addr_o =

       (destination == `d_base_data_memory) ? data_addr_i :
       (
           (fast_mode_start_i == `normal_mode)? pc_i : 0
       );

// assign base_mode_o = (destination == `d_base_data_memory) ? mode_i      : `word_mode;
assign base_data_be_o = (destination == `d_base_data_memory) ? sel : 4'b0000;
///////


assign base_data_w_o = (destination == `d_base_data_memory)?data_w_i    :
       (
           (fast_mode_start_i == `normal_mode)? inst_w_i : 0
       );
assign base_data_r_o = (destination == `d_base_data_memory)?data_r_i    :
       (
           (fast_mode_start_i == `normal_mode)? inst_r_i : 0
       );
assign base_data_ce_o= (destination == `d_base_data_memory)?data_ce_i   : inst_ce_i; // ce 恒0
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


// 注意优先级！
assign inst_o =
       (fast_mode_start_i == `fast_mode)? bram_data_i :
       ( // normal mode
           (destination == `d_base_data_memory) ? 32'h0000_0000 : base_data_i
       );
//    (destination == `d_base_data_memory) ? 32'h0000_0000 :
//    (
//        (fast_mode_start_i == `normal_mode)? base_data_i : bram_data_i // fast mode下使用bram指令
//    );
assign inst_r_finish_o =
       (destination == `d_base_data_memory) ?
       `inst_read_unfinish : inst_r_finish_i;
// 直连获取baseram_ctl信号
assign baseram_w_finish_o = inst_w_finish_i;


//////////////////////////////////////////////////////////
//////////////     BRAM和Fast Mode的处理     //////////////
//////////////////////////////////////////////////////////

///////////////////////////////
// 锁存程序起始addr和地址映射
///////////////////////////////
localparam ADDR_SAVE = 2'b01; // 保存地址
localparam ADDR_LOCK = 2'b10; // 锁住地址
reg [1:0] addr_state;
reg [31:0] addr_buffer; // 暂存v0程序初始地址

reg [31:0] addr_map; // 通过BRAM执行程序时候的地址映射值

always @(posedge clk or posedge rst_n)
begin
    if(rst_n == `rst_enable)
    begin
        addr_buffer <= 0;
        addr_map    <= 0;
        addr_state  <= ADDR_SAVE;

        prgm_start_addr_o <= 0; // 没有复位导致出现 set and reset with the same priority
    end
    else
    begin
        case(addr_state)
            ADDR_SAVE:
            begin
                addr_buffer <= prgm_start_addr_i;
                if(lock_addr_i == `lock_addr_enable) // 锁住程序地址起始值
                begin
                    addr_state <= ADDR_LOCK;
                end
            end

            ADDR_LOCK:
            begin
                prgm_start_addr_o <= addr_buffer;
                addr_map          <= addr_buffer - 32'h164; // 应该是0x164吧...
                if(lock_addr_i == `lock_addr_disable) // 解锁
                begin
                    addr_state <= ADDR_SAVE;
                end
            end
        endcase
    end
end


////////////////////////
// FastMode转换过程变量
////////////////////////
// to base ram ctl
assign bram_w_start_o = bram_w_start_i;
assign fast_mode_start_o = fast_mode_start_i;

// to cpu
assign bram_w_finish_o = bram_w_finish_i;

// to bram 地址需要映射
wire [31:0] other_addr = pc_i - 32'h8000_2280; // 固化指令地址映射
wire [31:0] dynamic_addr = pc_i - addr_map;    // 即将执行的程序地址映射

always @(*)
begin
    if(pc_i >= 32'h8000_2280 && pc_i <= 32'h8000_23e0) // 测试程序执行之外的其他指令
    begin
        bram_addr_o <= other_addr[11:2];
    end
    else
    begin
        bram_addr_o <= dynamic_addr[11:2];
    end
end

endmodule
