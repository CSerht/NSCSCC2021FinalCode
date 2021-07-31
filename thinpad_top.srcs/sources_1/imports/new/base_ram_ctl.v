// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company:
// // Engineer:
// //
// // Create Date: 2021/06/22 15:14:30
// // Design Name:
// // Module Name: base_ram_ctl
// // Project Name:
// // Target Devices:
// // Tool Versions:
// // Description:
// //
// // Dependencies:
// //
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// //
// //////////////////////////////////////////////////////////////////////////////////

// // 测试base RAM的使用，指令存储器
// // 特别注意inout双向数据总线与控制信号的配合！
// // 暂时不管两类虚拟地址，涉及到80000000和A0000000的识别，需要仲裁
// // 【inout的时候，行为建模不大好用！】
// // 对于组合逻辑，能用数据流建模，就别用行为建模！
`include "define.v"
module base_ram_ctl(
           input wire clk,
           input wire rst_n,

           // from CPU IF stage
           //    input wire [1:0] base_mode_i,
           input wire [3:0] data_sel_i,

           input wire data_w_i, // 写使能，高有效
           input wire data_r_i, // 读使能，高有效
           input wire data_ce_i, // 芯片使能，高有效，留有端口但是内部不使用

           // 当从base取数据而不是指令的时候，该信号值为1
           input wire is_read_data_i,

           input  wire [31:0] data_addr_i,
           (*mark_debug = "true"*)input  wire [31:0] data_i,
           (*mark_debug = "true"*)output wire [31:0] data_o,


           // signal to cpu  active-high
           output reg sram_ctl_busy_o,
           output reg data_r_finish_o,
           output reg data_w_finish_o,


           // from Base RAM, inst RAM
           inout wire[31:0] sram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享，暂时恒输出

           output reg [19:0] sram_addr, //BaseRAM地址
           output reg [3:0] sram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
           output reg  sram_ce_n,       //BaseRAM片选，低有效
           output reg  sram_oe_n,       //BaseRAM读使能，低有效
           output reg  sram_we_n        //BaseRAM写使能，低有效
       );


// FSM state
localparam [2:0] IDLE                  = 3'b000;
localparam [2:0] READ                  = 3'b001;
localparam [2:0] WRITE                 = 3'b010;
localparam [2:0] READ_DATA_FROM_BASE   = 3'b011; // 从base读数据
localparam [2:0] READ_INST_FROM_BASE   = 3'b100; // 还原现场1
localparam [2:0] READ_INST_FROM_BASE_2 = 3'b101; // 还原现场2
localparam [2:0] WRITE_2               = 3'b110; // 写入操作阶段2


// tristate. if(W_ENBALE) inout --> output,write data to SRAM
localparam [0:0] W_ENABLE  = 1'b1;
localparam [0:0] W_DISABLE = 1'b0; // rear data from SRAM

reg [2:0] current_state;
reg [31:0] data_from_SRAM;
reg [31:0] data_to_SRAM;
reg tristate;

reg [31:0] temp_instruction; // 从base读数据的时候，暂时保持指令




initial
begin
    // cpu
    sram_ctl_busy_o  <= `sram_idle;
    data_r_finish_o <= `data_read_unfinish;
    // 写入完成，意味着当前没有数据被写入，平时就是这个状态！
    // 还有成功写入数据之后，也会从unfinish进入finish状态
    data_w_finish_o <= `data_write_finish; // NOTE

    // base ram
    sram_addr <= 0;
    sram_be_n   <= 0;
    sram_ce_n   <= 1;
    sram_oe_n   <= 1;
    sram_we_n   <= 1;

    // internal data
    current_state  <= IDLE;
    data_from_SRAM <= 32'h0000_0000;
    data_to_SRAM   <= 32'h0000_0000;
    tristate       <= W_DISABLE;

    temp_instruction <= 32'h0000_0000;
end

// 时钟上升沿之后，进入某个状态，并在该状态下保持一个周期！
// 注意所有的状态信息（读完成，写完成，忙碌）都代表的是controler的状态！
// 例如busy，在读状态上升沿写入后保持的一个周期：
// buffer的数据是从SRAM读出并存好的数据，r_finish表示当前buffer数据有效
// busy表示当前buffer正在工作中
// 注意此时，状态机虽然是IDLE状态，但是当前周期是数据保持有效的周期
always @(posedge clk)
begin
    case (current_state)
        /////// 1. 中止 读/写 状态，保持idle
        /////// 2. 根据CPU传来的信息，为下面的读写状态
        ///////    提前准备好数据(要写入的数据)和地址（读/写地址），并切换状态
        IDLE:
        begin
            // internal data
            tristate       <= W_DISABLE;

            // cpu
            sram_ctl_busy_o  <= `sram_idle;
            data_r_finish_o <= `data_read_unfinish;
            // NOTE! 把之前的WE拉高，结束写入周期
            data_w_finish_o <= `data_write_finish;

            // base ram
            sram_ce_n   <= 0;
            sram_oe_n   <= 0;
            sram_we_n   <= 1;

            if(data_r_i == `data_read_enable && is_read_data_i == `read_data_not_from_baseram)
            begin
                sram_be_n   <= data_sel_i;
                sram_addr <= data_addr_i[21:2];
                current_state   <= READ;  // read instruction
            end
            else if(data_r_i == `data_read_enable && is_read_data_i == `read_data_from_baseram)
            begin
                sram_be_n   <= data_sel_i;
                sram_addr <= data_addr_i[21:2];
                current_state <= READ_DATA_FROM_BASE; // read data from base ram
            end
            // 应该不会出现这种状态
            // else if(data_w_i == `data_write_enable)
            // begin
            //     data_to_SRAM     <= data_i;
            //     sram_be_n    <= data_sel_i;
            //     sram_addr  <= data_addr_i[21:2];
            //     current_state    <= WRITE;
            // end
            else // not read and write
            begin
                sram_be_n    <= 0;
                current_state    <= IDLE;
            end
        end
        /////// 读阶段，把已经从SRAM读出的数据（在门口等着），写入到read data buffer中
        /////// 该周期等待数据从SRAM的家里走到控制器门口
        READ:
        begin
            if(data_r_i == `data_read_enable)
            begin
                // read instruction from base ram
                if(is_read_data_i == `read_data_not_from_baseram)
                begin
                    data_from_SRAM    <= sram_data;
                    data_r_finish_o   <= `data_read_finish;
                    sram_ctl_busy_o    <= `sram_busy;

                    current_state     <= IDLE;
                end
                // read data from base ram
                // 1. 保护现场，将已经读出的指令存到其他硬件
                // 2. 转移到空闲状态，并且设置好相关状态
                // 3. 读取完数据后，要恢复现场，正常取指
                else
                begin
                    temp_instruction <= sram_data;

                    data_r_finish_o   <= `data_read_unfinish;
                    sram_ctl_busy_o    <= `sram_idle;

                    current_state     <= IDLE;
                end
            end
            // 在READ状态发现，准备写入指令到baseRAM，目前来说这种可能性只可能出现在READ状态
            else if(data_w_i == `data_write_enable)
            begin
                // temp_instruction <= sram_data; // 暂存读取的的指令
                // 把已经读到的指令送出去
                data_from_SRAM   <= sram_data;
                data_r_finish_o   <= `data_read_finish;
                sram_ctl_busy_o    <= `sram_busy;

                // 切换到WRITE状态
                data_to_SRAM     <= data_i;
                sram_be_n        <= data_sel_i;
                sram_addr        <= data_addr_i[21:2];
                current_state    <= WRITE;
            end
            else  // 如果准备写入数据到data_from_SRAM的时候,读不允许,写不允许
            begin // 就等待读允许，再切换状态
                current_state <= READ;
            end
        end
        // 从base读数据
        READ_DATA_FROM_BASE:
        begin
            data_from_SRAM    <= sram_data;
            data_r_finish_o   <= `data_read_finish;
            sram_ctl_busy_o    <= `sram_busy;

            current_state     <= READ_INST_FROM_BASE;
        end
        // 恢复指令现场
        READ_INST_FROM_BASE:
        begin
            data_from_SRAM    <= temp_instruction;
            data_r_finish_o   <= `data_read_unfinish;
            sram_ctl_busy_o    <= `sram_idle;

            current_state     <= READ_INST_FROM_BASE_2;
        end
        READ_INST_FROM_BASE_2:
        begin
            data_r_finish_o   <= `data_read_finish;
            sram_ctl_busy_o    <= `sram_busy;
            current_state <= IDLE;
        end

        /////// 写阶段，把已经准备在 write data buffer中的数据
        /////// 准备写入到SRAM中（下拉WE，启动写入）
        /////// 该周期等待数据进入它在SRAM的家里
        WRITE:
        begin
            // 指令读取成功,修改读取状态
            data_r_finish_o   <= `data_read_unfinish;
            // sram_ctl_busy_o    <= `sram_idle;

            data_w_finish_o  <= `data_write_unfinish;
            sram_we_n        <= 0;
            sram_ctl_busy_o  <= `sram_busy;

            // current_state <= WRITE_2;
            current_state <= IDLE;
            tristate      <= W_ENABLE;
        end
        // 写阶段2
        WRITE_2:
        begin

        end
    endcase

end

assign sram_data =
       (tristate == W_ENABLE)?
       data_to_SRAM : 32'hzzzz_zzzz;

assign data_o = data_from_SRAM;


///////////////////////////////////////////////////////////
/////////////// 以下组合逻辑的写法是错误的！ ////////////////
///////////////////////////////////////////////////////////
// // write data to RAM when inst_w_i equals 1, inout -- output
// assign base_ram_data_io =
//        (inst_w_i == 1)? inst_i:32'hzzzz_zzzz;
// // read data from RAM, inout -- input
// // assign inst_o = base_ram_data_io; // 仅读取模式下才起作用


// always @(posedge clk or posedge rst_n)
// begin
//     if (rst_n == `rst_enable)
//         inst_o <= 0;
//     else if(inst_r_i == 1)
//         inst_o <= base_ram_data_io;
// end

// assign base_ram_addr_o = pc_i[21:2];

// assign base_ram_be_o = inst_data_sel_i;
// assign base_ram_oe_o = !inst_r_i;
// assign base_ram_we_o = !inst_w_i;

// // RAM使能 == 0 时无效,若为1，则：11 || 00 || ce使能 == 0 时无效，否则有效
// assign base_ram_ce_o = (!inst_ce_i) ||
//        (inst_ce_i && inst_r_i && inst_w_i) ||
//        (inst_ce_i && !inst_r_i && !inst_w_i);


endmodule
