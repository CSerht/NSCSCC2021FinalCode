`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/23 09:58:12
// Design Name: 
// Module Name: base_ram_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 单独测试一个Base RAM
//              这里其实唯一麻烦的就是inout端口的使用
//              至于时序暂时不需要管
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module base_ram_tb(

    );


wire[15:0] base_ram_data; //BaseRAM数据，低8位与CPLD串口控制器共享
reg [19:0] base_ram_addr; //BaseRAM地址
reg [1:0]  base_ram_be_n;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
reg        base_ram_ce_n;       //BaseRAM片选，低有效
reg        base_ram_oe_n;       //BaseRAM读使能，低有效
reg        base_ram_we_n;       //BaseRAM写使能，低有效



// BaseRAM 仿真模型
// 不能进行连续的字节写入操作（连续字写入可以），是仿真模型的bug吗？
// 回头试试开发板能不能用
sram_model base1(/*autoinst*/
            .DataIO(base_ram_data[15:0]),
            .Address(base_ram_addr[19:0]),
            .OE_n(base_ram_oe_n),
            .CE_n(base_ram_ce_n),
            .WE_n(base_ram_we_n),
            .LB_n(base_ram_be_n[0]),
            .UB_n(base_ram_be_n[1]));

// 接入到BaseRAM外部的测试模块信号的模拟
reg  [15:0] data_to_ram;    // 写入到RAM的数据
wire [15:0] data_from_ram;  // 从RAM读取的数据


// 写入，三态
assign base_ram_data = (base_ram_we_n == 0)? data_to_ram: 16'hzzzz; 
// 读取
assign data_from_ram = base_ram_data;   

initial begin
    // 此处addr就是SRAM的addr
    #100 // write to addr 0
    base_ram_addr = 0; // 20根地址线的值
    base_ram_be_n = 0;
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 0;
    data_to_ram = 16'habce;
    #100 // write to addr 1
    base_ram_addr = 1;
    base_ram_be_n = 0;
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 0;
    data_to_ram = 16'h1234;


    #100 // read from addr 0
    base_ram_addr = 0;
    base_ram_be_n = 2'b00; // Dout,Dout 【abce】
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 1;
    #100 // read from addr 1
    base_ram_addr = 1;
    base_ram_be_n = 2'b00; // Dout,Dout 【1234】
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 1;

    ////////////////// 写字节测试 //////////////////
    #100 // write to addr 0
    base_ram_addr = 0; // 20根地址线的值
    base_ram_be_n = 2'b10; // 仅仅写入低8位
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 0;
    data_to_ram = 16'h3312;
    // #100 // read from addr 0
    // base_ram_addr = 0;
    // base_ram_be_n = 2'b00; // Dout,Dout 【ab12】
    // base_ram_ce_n = 0;
    // base_ram_oe_n = 0;
    // base_ram_we_n = 1;   
    #100
    base_ram_we_n = 1;

    #10 // write to addr 1
    base_ram_addr = 1; // 20根地址线的值
    base_ram_be_n = 2'b11; // 仅仅写入高8位 ff
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 0;
    data_to_ram = 16'hffee;
    #50
    base_ram_be_n = 2'b01;

    #100 // read from addr 0
    base_ram_addr = 0;
    base_ram_be_n = 2'b00; // Dout,Dout 
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 1;
    #100 // read from addr 1
    base_ram_addr = 1;
    base_ram_be_n = 2'b00; // Dout,Dout
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 1;

    // 对于写入数据的选择，请注意，sel决定了
    // 1. 取输入数据的哪一部分，例如16'h3312,sel = 2'b01，则取8'h33
    // 2. 把取到的数据写入哪里，例如addr = 0,sel = 2'b01,
    //    则写入0号地址的高8位的位置，也就是高地址


    ////////////////// 读字节测试 //////////////////
    #100 // read from addr 0
    base_ram_addr = 0;
    base_ram_be_n = 2'b10; // zz,Dout
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 1;
    #100 // read from addr 0
    base_ram_addr = 0;
    base_ram_be_n = 2'b01; // Dout,zz
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 1;

    #100 // read from addr 0
    base_ram_addr = 0;
    base_ram_be_n = 2'b00; // Dout,Dout
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 1;
    #100 // read from addr 1
    base_ram_addr = 1;
    base_ram_be_n = 0;
    base_ram_ce_n = 0;
    base_ram_oe_n = 0;
    base_ram_we_n = 1;

end

endmodule
