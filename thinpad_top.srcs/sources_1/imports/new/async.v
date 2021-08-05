////////////////////////////////////////////////////////
// RS-232 RX and TX module
// (c) fpga4fun.com & KNJN LLC - 2003 to 2016

// The RS-232 settings are fixed
// TX: 8-bit data, 2 stop, no-parity
// RX: 8-bit data, 1 stop, no-parity (the receiver can accept more stop bits of course)

// 仿真的时候需要取消注释；实现的时候需要注释下面的语句
// `define SIMULATION   // in this mode, TX outputs one bit per clock cycle
// and RX receives one bit per clock cycle (for fast simulations)

//////////////////////////////////////////////////////

// 8 --> 1
module async_transmitter(
           input wire clk,

           // start 作为数据发送的开始，数据发送完成前必须置0，否则会一直发数据
           (*mark_debug = "true"*)input wire TxD_start,		// 高有效，开始处理并行数据
           (*mark_debug = "true"*)input wire [7:0] TxD_data,	// 8位并行数据

           output wire TxD,				// 串行数据
           output wire TxD_busy			// 低电平代表一帧发送完成，高电平代表发送中
       );

// Assert TxD_start for (at least) one clock cycle to start transmission of TxD_data
// TxD_data is latched so that it doesn't have to stay valid while it is being sent
// TxD_start信号至少保持一个时钟周期有效（高电平？），以保证TxD_data数据的发送
// TxD_data数据是暂存器中的，能够自行保持稳定，发送过程不必其他额外操作

parameter ClkFrequency = 25000000;	// 25MHz
parameter Baud = 115200;

// generate
// 	if(ClkFrequency<Baud*8 && (ClkFrequency % Baud!=0)) ASSERTION_ERROR PARAMETER_OUT_OF_RANGE("Frequency incompatible with requested Baud rate");
// endgenerate

////////////////////////////////
`ifdef SIMULATION  		// 仿真测试时候，每个时钟周期输出 1 bit
wire BitTick = 1'b1;  	// output one bit per clock cycle
`else					// FPGA模式下的输出，串口发送/接收器对应的采样频率（过采样），通过波特率发生器生成
wire BitTick;
BaudTickGen #(ClkFrequency, Baud) tickgen(.clk(clk), .enable(TxD_busy), .tick(BitTick));
`endif

reg [3:0] TxD_state = 0;
wire TxD_ready = (TxD_state==0);
assign TxD_busy = ~TxD_ready;

reg [7:0] TxD_shift = 0;
always @(posedge clk)
begin
    if(TxD_ready & TxD_start)
        TxD_shift <= TxD_data;
    else
        if(TxD_state[3] & BitTick)
            TxD_shift <= (TxD_shift >> 1);

    case(TxD_state)
        4'b0000:
            if(TxD_start)
                TxD_state <= 4'b0100;
        4'b0100:
            if(BitTick)
                TxD_state <= 4'b1000;  // start bit
        4'b1000:
            if(BitTick)
                TxD_state <= 4'b1001;  // bit 0
        4'b1001:
            if(BitTick)
                TxD_state <= 4'b1010;  // bit 1
        4'b1010:
            if(BitTick)
                TxD_state <= 4'b1011;  // bit 2
        4'b1011:
            if(BitTick)
                TxD_state <= 4'b1100;  // bit 3
        4'b1100:
            if(BitTick)
                TxD_state <= 4'b1101;  // bit 4
        4'b1101:
            if(BitTick)
                TxD_state <= 4'b1110;  // bit 5
        4'b1110:
            if(BitTick)
                TxD_state <= 4'b1111;  // bit 6
        4'b1111:
            if(BitTick)
                TxD_state <= 4'b0010;  // bit 7
        4'b0010:
            if(BitTick)
                TxD_state <= 4'b0000;  // stop1
        //4'b0011: if(BitTick) TxD_state <= 4'b0000;  // stop2
        default:
            if(BitTick)
                TxD_state <= 4'b0000;
    endcase
end

assign TxD = (TxD_state<4) | (TxD_state[3] & TxD_shift[0]);  // put together the start, data and stop bits
endmodule



    //*******************************************************************************
    //*******************************************************************************
    //*******************************************************************************

    ////////////////////////////////////////////////////////
    module async_receiver(
        input wire clk,
        // 数据举例：[1...1][0, 0xab, 1, 1...1][...]，信息位的复用，一串数据的不同位代表不同含义，这也是接收器接收数据的判定依据
        // 以往都是多个端口发送数据判定，有数据端还有控制端，现在只有1个端口、位宽1位，也需要实现同样的逻辑
        input wire RxD,				// PC通过串口发送来的串行数据：[空闲位][开始位 1，数据位 8，结束位 1，空闲位 n][同前面][...]

        output reg RxD_data_ready,  // 成功接收了PC发过来的1帧数据，置1；数据被取走之后，置0
        input wire RxD_clear,		// 清除 RxD_data_ready 信号（置0），clear高有效
        output reg [7:0] RxD_data   // data received, valid only (for one clock cycle) when RxD_data_ready is asserted(set 1'b1)
    );

parameter ClkFrequency = 25000000; // 25MHz
parameter Baud = 115200;

parameter Oversampling = 8;  // needs to be a power of 2
// we oversample the RxD line at a fixed rate to capture each RxD data bit at the "right" time
// 8 times oversampling by default, use 16 for higher quality reception
// 位的接收使用过采样，默认对每一位进行8次采样，如果要保证质量更高，可以采样16次
// 过采样为8，意味着采样的速率 = 串行数据位的传输速率 * 8
// 串行数据位传输速率 = 1/波特率 s，波特率 9600bps代表每秒传输9600位，取倒数能够得到 传输1 bit需要的时间，也就是位传输速率

// generate
// 	if(ClkFrequency<Baud*Oversampling) ASSERTION_ERROR PARAMETER_OUT_OF_RANGE("Frequency too low for current Baud rate and oversampling");
// 	if(Oversampling<8 || ((Oversampling & (Oversampling-1))!=0)) ASSERTION_ERROR PARAMETER_OUT_OF_RANGE("Invalid oversampling value");
// endgenerate

////////////////////////////////

// We also detect if a gap occurs in the received stream of characters
// That can be useful if multiple characters are sent in burst
//  so that multiple characters can be treated as a "packet"

// 空闲位，当一段时间内没有接收数据的时候，置1
wire RxD_idle;  		// asserted when no data has been received for a while

// 当检测到一个“包”，置1并保持1个时钟周期
reg RxD_endofpacket; 	// asserted for one clock cycle when a packet has been detected (i.e. RxD_idle is going high)


reg [3:0] RxD_state = 0;

`ifdef SIMULATION		// 仿真测试时候，1个时钟周期接收 1 bit
wire RxD_bit = RxD;
wire sampleNow = 1'b1;  // receive one bit per clock cycle

`else
wire OversamplingTick;
BaudTickGen #(ClkFrequency, Baud, Oversampling) tickgen(.clk(clk), .enable(1'b1), .tick(OversamplingTick));

// synchronize RxD to our clk domain
reg [1:0] RxD_sync = 2'b11;
always @(posedge clk) if(OversamplingTick)
        RxD_sync <= {RxD_sync[0], RxD};

// and filter it
reg [1:0] Filter_cnt = 2'b11;
reg RxD_bit = 1'b1;

always @(posedge clk)
    if(OversamplingTick)
    begin
        if(RxD_sync[1]==1'b1 && Filter_cnt!=2'b11)
            Filter_cnt <= Filter_cnt + 1'd1;
        else
            if(RxD_sync[1]==1'b0 && Filter_cnt!=2'b00)
                Filter_cnt <= Filter_cnt - 1'd1;

        if(Filter_cnt==2'b11)
            RxD_bit <= 1'b1;
        else
            if(Filter_cnt==2'b00)
                RxD_bit <= 1'b0;
    end

// and decide when is the good time to sample the RxD line
function integer log2(input integer v);
    begin
        log2=0;
        while(v>>log2)
            log2=log2+1;
    end
endfunction
localparam l2o = log2(Oversampling);
reg [l2o-2:0] OversamplingCnt = 0;
always @(posedge clk) if(OversamplingTick)
        OversamplingCnt <= (RxD_state==0) ? 1'd0 : OversamplingCnt + 1'd1;
wire sampleNow = OversamplingTick && (OversamplingCnt==Oversampling/2-1);

`endif

// now we can accumulate the RxD bits in a shift-register
always @(posedge clk)
case(RxD_state)
    4'b0000:
        if(~RxD_bit)
            RxD_state <= `ifdef SIMULATION 4'b1000 `else 4'b0001 `endif;  // start bit found?
    4'b0001:
        if(sampleNow)
            RxD_state <= 4'b1000;  // sync start bit to sampleNow
    4'b1000:
        if(sampleNow)
            RxD_state <= 4'b1001;  // bit 0
    4'b1001:
        if(sampleNow)
            RxD_state <= 4'b1010;  // bit 1
    4'b1010:
        if(sampleNow)
            RxD_state <= 4'b1011;  // bit 2
    4'b1011:
        if(sampleNow)
            RxD_state <= 4'b1100;  // bit 3
    4'b1100:
        if(sampleNow)
            RxD_state <= 4'b1101;  // bit 4
    4'b1101:
        if(sampleNow)
            RxD_state <= 4'b1110;  // bit 5
    4'b1110:
        if(sampleNow)
            RxD_state <= 4'b1111;  // bit 6
    4'b1111:
        if(sampleNow)
            RxD_state <= 4'b0010;  // bit 7
    4'b0010:
        if(sampleNow)
            RxD_state <= 4'b0000;  // stop bit
    default:
        RxD_state <= 4'b0000;
endcase

always @(posedge clk)
    if(sampleNow && RxD_state[3])
        RxD_data <= {RxD_bit, RxD_data[7:1]};

//reg RxD_data_error = 0;
always @(posedge clk)
begin
    if(RxD_clear)
        RxD_data_ready <= 0;
    else
        RxD_data_ready <= RxD_data_ready | (sampleNow && RxD_state==4'b0010 && RxD_bit);  // make sure a stop bit is received
    //RxD_data_error <= (sampleNow && RxD_state==4'b0010 && ~RxD_bit);  // error if a stop bit is not received
end

`ifdef SIMULATION
assign RxD_idle = 0;


`else
reg [l2o+1:0] GapCnt = 0;
always @(posedge clk)
    if (RxD_state!=0)
        GapCnt<=0;
    else if(OversamplingTick & ~GapCnt[log2(Oversampling)+1])
        GapCnt <= GapCnt + 1'h1;
assign RxD_idle = GapCnt[l2o+1];
always @(posedge clk)
    RxD_endofpacket <= OversamplingTick & ~GapCnt[l2o+1] & &GapCnt[l2o:0];

`endif

endmodule



    // ****************************************************************

    ////////////////////////////////////////////////////////
    // dummy module used to be able to raise an assertion in Verilog
    module ASSERTION_ERROR();
endmodule


    ////////////////////////////////////////////////////////
    module BaudTickGen(
        input  wire clk, enable,
        output wire tick  // generate a tick at the specified baud rate * oversampling
    );
parameter ClkFrequency = 25000000;
parameter Baud = 115200;
parameter Oversampling = 1;

function integer log2(input integer v);
    begin
        log2=0;
        while(v>>log2)
            log2=log2+1;
    end
endfunction
localparam AccWidth = log2(ClkFrequency/Baud)+8;  // +/- 2% max timing error over a byte
reg [AccWidth:0] Acc = 0;
localparam ShiftLimiter = log2(Baud*Oversampling >> (31-AccWidth));  // this makes sure Inc calculation doesn't overflow
localparam Inc = ((Baud*Oversampling << (AccWidth-ShiftLimiter))+(ClkFrequency>>(ShiftLimiter+1)))/(ClkFrequency>>ShiftLimiter);
always @(posedge clk) if(enable)
        Acc <= Acc[AccWidth-1:0] + Inc[AccWidth:0];
    else
        Acc <= Inc[AccWidth:0];
assign tick = Acc[AccWidth];
endmodule


    ////////////////////////////////////////////////////////
