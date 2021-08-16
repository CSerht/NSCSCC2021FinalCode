`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2021/07/06 10:37:33
// Design Name:
// Module Name: my_cpu
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

`include "define.v"

module my_cpu(
           input wire clk,
           input wire rst_n,

           // for inst base ram
           input wire [31:0] inst_i,
           input wire baseram_busy_i,
           input wire inst_r_finish_i,

           input wire baseram_w_finish_i,

           output wire [31:0] pc_o,

           output reg [31:0] inst_o = 0,
           output reg inst_w_o = 0, // only read
           output wire inst_r_o,
           output reg inst_ce_o = 1,

           // for data ext ram
           input wire [31:0] data_i,
           input wire ram_busy_i,
           input wire data_r_finish_i,
           input wire data_w_finish_i,

           output wire [31:0] data_o,
           output wire [31:0] data_addr_o,
           output wire data_w_o,
           output wire data_r_o,
           output wire [1:0] mode_o,
           output reg data_ce_o = 1,

           // DRAM and Fst Mode
           output wire [31:0] prgm_start_addr_o,
           output wire lock_addr_o,

           output wire fast_mode_start_o,

           input wire bram_w_finish_i,
           output wire bram_w_start_o,

           output wire trans_enable_o
       );



//////////////////////////////////////////
///////////      IF stage      ///////////
//////////////////////////////////////////

// input
wire isjump_i_if;
wire [31:0] pc1_i_if;
wire [31:0] pc_i_if = (isjump_i_if == 1)? pc1_i_if : (pc_o + 4);

wire pc_w_i;

pc  u_pc (
        .clk                     ( clk       ),
        .rst_n                   ( rst_n     ),
        .pc_i                    ( pc_i_if   ),
        .pc_w_i                  ( pc_w_i    ),

        .pc_o                    ( pc_o      )
    );


//////////////////////////////////////////
//*********        IF/ID       *********//
//////////////////////////////////////////

// input
wire [31:0] pc_i_ifid;
assign pc_i_ifid = pc_o;

wire if_id_w_i;
// // 根据ID/EX的isjump的值选择指令的输入
// // isjump enable，输入nop；否则输入inst_i
// // 写在ID/EX模块那里了
// wire [31:0] inst_i_sel;
wire [31:0] inst_i_ctl_result;

wire if_id_clear_i; // connect with pc_stall.v

// output
wire [31:0] pc_o_ifid;
wire [31:0] inst_o_ifid;

IF_ID  u_IF_ID (
           .clk                     ( clk         ),
           .rst_n                   ( rst_n       ),
           .if_id_w_i               ( if_id_w_i   ),
           .if_id_clear_i           ( if_id_clear_i   ),

           .inst_i                  ( inst_i_ctl_result ),
           .pc_i                    ( pc_i_ifid     ),

           .inst_o                  ( inst_o_ifid   ),
           .pc_o                    ( pc_o_ifid     )
       );



/*********************/
//     pc_stall.v    //
/*********************/

// input


// output
wire pc_w_o_pcstall;
wire if_id_clear_o_pcstall;



pc_stall  u_pc_stall (
              .fast_mode_start_i       ( fast_mode_start_o  ),

              .inst_r_finish_i         ( inst_r_finish_i    ),  // CPU外部直连
              .baseram_w_finish_i      ( baseram_w_finish_i ),  // CPU外部直连

              .pc_w_o                  ( pc_w_o_pcstall            ),
              .if_id_clear_o           ( if_id_clear_o_pcstall     )
          );


//////////////////////////////////////////
///////////      ID stage      ///////////
//////////////////////////////////////////

/*********************/
// central controler //
/*********************/

// input
wire [5:0] op;
assign op = inst_o_ifid[31:26];

// output
wire reg_dst_o;
wire zero_sign_ext_o;

wire  alu_src_o_ex;
wire  [3:0]  alu_op_o_ex;

wire  [1:0]  mode_o_mem;
wire  data_w_o_mem;
wire  data_r_o_mem;
wire  mem_reg_o_mem;

wire  reg_we_o_wb;

central_ctl  u_central_ctl (
                 .op                      ( op                ),

                 .reg_dst_o               ( reg_dst_o         ),
                 .zero_sign_ext_o         ( zero_sign_ext_o   ),
                 .alu_src_o               ( alu_src_o_ex         ),
                 .alu_op_o                ( alu_op_o_ex          ),
                 .mode_o                  ( mode_o_mem            ),
                 .data_w_o                ( data_w_o_mem          ),
                 .data_r_o                ( data_r_o_mem          ),
                 .mem_reg_o               ( mem_reg_o_mem         ),
                 .reg_we_o                ( reg_we_o_wb          )
             );

/********************/
//    reg files     //
/********************/

// input
/// from WB stage
wire reg_we_i_id;
wire [4:0] rW_id;
wire [31:0] wr_data_i_id;

/// from jump_ident module (WB stage)
// wire [31:0] jal_i_id;
// wire jal_en_i_id;

/// from IF/ID
wire [4:0] rA;
wire [4:0] rB;
assign rA = inst_o_ifid[25:21]; // rs
assign rB = inst_o_ifid[20:16]; // rt

// output
wire [31:0] A;
wire [31:0] B;

reg_files  u_reg_files (
               .clk                     ( clk            ),
               .rst_n                   ( rst_n          ),
               .reg_we_i                ( reg_we_i_id    ),
               .rW                      ( rW_id          ),
               .wr_data_i               ( wr_data_i_id   ),
               //    .jal_i                   ( jal_i_id       ),
               //    .jal_en_i                ( jal_en_i_id    ),
               .rA                      ( rA          ),
               .rB                      ( rB          ),

               .A                       ( A           ),
               .B                       ( B           )
           );


/********************/
//    rw select     //
/********************/

// input
wire reg_dst_i; // from central controler
wire [4:0] rd;
wire [4:0] rt;

assign reg_dst_i = reg_dst_o;
assign rt = inst_o_ifid[20:16];
assign rd = inst_o_ifid[15:11];

// output
wire [4:0] rW_o_id;

rW_select  u_rW_select (
               .reg_dst_i               ( reg_dst_i   ),
               .rd                      ( rd          ),
               .rt                      ( rt          ),

               .rW_o                    ( rW_o_id     )
           );

/********************/
//  imm extension   //
/********************/

// input
wire zero_sign_ext_i;
wire [15:0] imm;

assign zero_sign_ext_i = zero_sign_ext_o;
assign imm = inst_o_ifid[15:0];

// output
wire [31:0] imm_ext_o_id;

imm_extension  u_imm_extension (
                   .zero_sign_ext_i         ( zero_sign_ext_i   ),
                   .imm                     ( imm               ),

                   .imm_ext_o               ( imm_ext_o_id      )
               );


/********************/
// jump identifier  //
/********************/

// input
wire [5:0] op_jump;
wire [31:0] pc_jump;
wire [25:0] offset;
wire [31:0] dataA;
wire [31:0] dataB;

assign op_jump = inst_o_ifid[31:26];
assign pc_jump = pc_o_ifid;
assign offset = inst_o_ifid[25:0];


// output
wire isjump_o;
wire jal_en_o;
wire [31:0] pc_jump_o;
wire [31:0] jal_jump_o;
wire is_jump_inst_o;

assign isjump_i_if = isjump_o;  // IF stage
assign pc1_i_if = pc_jump_o;    // IF stage

jump_ident  u_jump_ident (
                .op                      ( op_jump         ),
                .pc                      ( pc_jump         ),
                .offset                  ( offset     ),
                .dataA                   ( dataA      ),
                .dataB                   ( dataB      ),

                .isjump_o                ( isjump_o   ),
                .jal_en_o                ( jal_en_o   ),
                .pc_o                    ( pc_jump_o       ),
                .jal_o                   ( jal_jump_o      ),
                .is_jump_inst_o          ( is_jump_inst_o  )
            );


/********************/
//  dataA/B bypass  //
/********************/
wire [31:0] alu_result_ex_stage;
wire [31:0] ex_mem_j_data;
wire [31:0] mem_wb_j_data;

wire [1:0] bypass_dataA_i;
assign dataA =
       (bypass_dataA_i == `j_data_from_regfiles)  ? A:
       (bypass_dataA_i == `j_data_from_alu_result)? alu_result_ex_stage:
       (bypass_dataA_i == `j_data_from_ex_mem)? ex_mem_j_data:
       (bypass_dataA_i == `j_data_from_mem_wb)? mem_wb_j_data:
       0;


wire [1:0] bypass_dataB_i;
assign dataB =
       (bypass_dataB_i == `j_data_from_regfiles)  ? B:
       (bypass_dataB_i == `j_data_from_alu_result)? alu_result_ex_stage:
       (bypass_dataB_i == `j_data_from_ex_mem)? ex_mem_j_data:
       (bypass_dataB_i == `j_data_from_mem_wb)? mem_wb_j_data:
       0;

//////////////////////////////////////////
//*********        ID/EX       *********//
//////////////////////////////////////////

// input
wire clear_i;

wire [31:0] A_i;
wire [31:0] B_i;
assign A_i = A;
assign B_i = B;

wire [4:0] rW_i_id;
wire [31:0] imm_ext_i_id;
assign rW_i_id = rW_o_id;
assign imm_ext_i_id = imm_ext_o_id;

wire [31:0] jal_jump_i_id;
assign jal_jump_i_id = jal_jump_o;

wire [4:0] rs_i;
wire [4:0] rt_i;
assign rs_i = inst_o_ifid[25:21];
assign rt_i = inst_o_ifid[20:16];

wire alu_src_i_ex;
wire [3:0] alu_op_i_ex;
wire isjump_i_ex;
assign alu_src_i_ex = alu_src_o_ex;
assign alu_op_i_ex = alu_op_o_ex;
assign isjump_i_ex = isjump_o;


wire [1:0] mode_i_mem;
wire data_w_i_mem;
wire data_r_i_mem;
wire mem_reg_i_mem;
wire is_jump_inst_i_mem;
assign mode_i_mem = mode_o_mem;
assign data_w_i_mem = data_w_o_mem;
assign data_r_i_mem = data_r_o_mem;
assign mem_reg_i_mem = mem_reg_o_mem;
assign is_jump_inst_i_mem = is_jump_inst_o;

wire reg_we_i_wb;
assign reg_we_i_wb = reg_we_o_wb;

wire jal_en_i_wb;
assign jal_en_i_wb = jal_en_o;

wire id_ex_reg_w_i;


// output
wire [31:0] A_o_idex;
wire [31:0] B_o_idex;
wire [4:0] rW_o_idex;
wire [31:0] imm_ext_o_idex;
wire [31:0] jal_o_idex;
wire [4:0] rs_o_idex;
wire [4:0] rt_o_idex;
wire alu_src_o_idex;
wire [3:0] alu_op_o_idex;

wire isjump_o_idex;

wire [1:0] mode_o_idex;
wire data_w_o_idex;
wire data_r_o_idex;
wire mem_reg_o_idex;
wire is_jump_inst_o_idex;
wire reg_we_o_idex;
wire jal_en_o_idex;

ID_EX  u_ID_EX (
           .clk                     ( clk         ),
           .rst_n                   ( rst_n       ),
           .clear_i                 ( clear_i     ),
           .id_ex_w_i               ( id_ex_reg_w_i        ),
           /* reg files */
           .A_i                     ( A_i         ),
           .B_i                     ( B_i         ),
           /* rW imm */
           .rW_i                    ( rW_i_id        ),
           .imm_ext_i               ( imm_ext_i_id   ),
           /* jump identifier */
           .jal_i                   ( jal_jump_i_id       ),
           /* rs rt */
           .rs_i                    ( rs_i        ),
           .rt_i                    ( rt_i        ),
           /* control */
           // EX //
           .alu_src_i               ( alu_src_i_ex   ),
           .alu_op_i                ( alu_op_i_ex    ),

           .isjump_i                ( isjump_i_ex       ),
           // MEM //
           .mode_i                  ( mode_i_mem      ),
           .data_w_i                ( data_w_i_mem    ),
           .data_r_i                ( data_r_i_mem    ),
           .mem_reg_i               ( mem_reg_i_mem   ),
           .is_jump_inst_i          ( is_jump_inst_i_mem  ),
           // WB //
           .reg_we_i                ( reg_we_i_wb    ),
           .jal_en_i                ( jal_en_i_wb    ),

           .A_o                     ( A_o_idex         ),
           .B_o                     ( B_o_idex         ),
           .rW_o                    ( rW_o_idex        ),
           .imm_ext_o               ( imm_ext_o_idex   ),
           .jal_o                   ( jal_o_idex       ),
           .rs_o                    ( rs_o_idex        ),
           .rt_o                    ( rt_o_idex        ),
           .alu_src_o               ( alu_src_o_idex   ),
           .alu_op_o                ( alu_op_o_idex    ),

           .isjump_o               ( isjump_o_idex    ),

           .mode_o                  ( mode_o_idex      ),
           .data_w_o                ( data_w_o_idex    ),
           .data_r_o                ( data_r_o_idex    ),
           .mem_reg_o               ( mem_reg_o_idex   ),
           .is_jump_inst_o          ( is_jump_inst_o_idex ),
           .reg_we_o                ( reg_we_o_idex    ),
           .jal_en_o                ( jal_en_o_idex    )
       );

// 输入指令选择nop or inst_i;
// 在Fast模式下，跳转指令若成立，会导致多执行延迟槽之后的一条指令，将其置nop
// assign inst_i_sel =
//        (isjump_o_idex == `jump_enable && fast_mode_start_o == `fast_mode) ?
//        32'h0000_0000 : inst_i;


//////////////////////////////////////////
///////////      EX stage      ///////////
//////////////////////////////////////////

/********************/
//   ALU controler  //
/********************/

// input
wire [3:0] alu_op_i;
wire [5:0] func;
assign alu_op_i = alu_op_o_idex;
assign func = imm_ext_o_idex[5:0];

// output
wire [3:0] data_op_o;

ALU_ctl  u_ALU_ctl (
             .alu_op_i                ( alu_op_i   ),
             .func                    ( func       ),

             .op_o                    ( data_op_o       )
         );


/********************/
//        ALU       //
/********************/

// input
wire [3:0] data_op_i;
wire alu_src_i;
assign data_op_i = data_op_o;
assign alu_src_i = alu_src_o_idex;

wire [31:0] bypass_A_i; // final data A
wire [31:0] bypass_B_i; // final data B
wire [31:0] imm_ext_i;
assign imm_ext_i = imm_ext_o_idex;


// output
wire [31:0] alu_result_o_ex;

ALU  u_ALU (
         .op_i                    ( data_op_i           ),
         .alu_src_i               ( alu_src_i      ),
         .A_i                     ( bypass_A_i            ),
         .B_i                     ( bypass_B_i            ),
         .imm_ext_i               ( imm_ext_i      ),


         .alu_result_o            ( alu_result_o_ex   )
     );


/********************/
//  data hazard ex  //
/********************/


// input
wire ex_mem_w_i;
wire mem_wb_w_i;
wire [4:0]  ex_mem_rd_i;
wire [4:0]  mem_wb_rd_i;
wire [4:0]  id_ex_rs_i;
wire [4:0]  id_ex_rt_i;

// output
wire [1:0]  bypass_a_o;
wire [1:0]  bypass_b_o;

data_hazard_ex  u_data_hazard_ex (
                    .ex_mem_w_i              ( ex_mem_w_i    ),
                    .mem_wb_w_i              ( mem_wb_w_i    ),
                    .ex_mem_rd_i             ( ex_mem_rd_i   ),
                    .mem_wb_rd_i             ( mem_wb_rd_i   ),
                    .id_ex_rs_i              ( id_ex_rs_i    ),
                    .id_ex_rt_i              ( id_ex_rt_i    ),

                    .bypass_a_o              ( bypass_a_o    ),
                    .bypass_b_o              ( bypass_b_o    )
                );

/*********************/
// bypass A/B select //
/*********************/

wire [31:0] ex_mem_data; // data for data hazard in mem stage
wire [31:0] mem_wb_data; // data for data hazard in wb stage

// A
wire [31:0] bypass_data_A;
assign bypass_data_A =
       (bypass_a_o == 2'b00) ?  A_o_idex    :
       (bypass_a_o == 2'b01) ?  mem_wb_data :
       (bypass_a_o == 2'b10) ?  ex_mem_data :
       0;
assign bypass_A_i = bypass_data_A;  // ALU

// B
wire [31:0] bypass_data_B;
assign bypass_data_B =
       (bypass_b_o == 2'b00) ?  B_o_idex    :
       (bypass_b_o == 2'b01) ?  mem_wb_data :
       (bypass_b_o == 2'b10) ?  ex_mem_data :
       0;
assign bypass_B_i = bypass_data_B;

//////////////////////////////////////////
//*********       EX/MEM       *********//
//////////////////////////////////////////

// input
wire [31:0] data_to_mem_i;
wire [31:0] alu_result_i;
wire [4:0] rW_i_ex;
wire [31:0] jal_i_ex;

assign data_to_mem_i = bypass_data_B;
assign alu_result_i = alu_result_o_ex;
assign rW_i_ex = rW_o_idex;
assign jal_i_ex = jal_o_idex;
//---------------------------
wire [1:0] mode_i_ex;
wire data_w_i_ex;
wire data_r_i_ex;
wire mem_reg_i_ex;
wire is_jump_inst_i_ex;

assign mode_i_ex = mode_o_idex;
assign data_w_i_ex = data_w_o_idex;
assign data_r_i_ex = data_r_o_idex;
assign mem_reg_i_ex = mem_reg_o_idex;
assign is_jump_inst_i_ex = is_jump_inst_o_idex;
//---------------------------
wire reg_we_i_ex;
wire jal_en_i_ex;

assign reg_we_i_ex = reg_we_o_idex;
assign jal_en_i_ex = jal_en_o_idex;


wire ex_mem_reg_w_i;

// output
wire [31:0] data_to_mem_o_exmem;
wire [31:0] alu_result_o_exmem;
wire [4:0] rW_o_exmem;
wire [31:0] jal_o_exmem;
wire [1:0] mode_o_exmem;
wire dat_w_o_exmem;
wire data_r_o_exmem;
wire mem_reg_o_exmem;
wire is_jump_inst_o_exmem;
wire reg_we_o_exmem;
wire jal_en_o_exmem;

EX_MEM  u_EX_MEM (
            .clk                     ( clk             ),
            .rst_n                   ( rst_n           ),
            .ex_mem_w_i              ( ex_mem_reg_w_i       ),

            .data_to_mem_i           ( data_to_mem_i   ),
            .alu_result_i            ( alu_result_i    ),
            .rW_i                    ( rW_i_ex         ),
            .jal_i                   ( jal_i_ex        ),
            // MEM //
            .mode_i                  ( mode_i_ex       ),
            .data_w_i                ( data_w_i_ex     ),
            .data_r_i                ( data_r_i_ex     ),
            .mem_reg_i               ( mem_reg_i_ex    ),
            .is_jump_inst_i          ( is_jump_inst_i_ex   ),
            // WB //
            .reg_we_i                ( reg_we_i_ex     ),
            .jal_en_i                ( jal_en_i_ex     ),

            .data_to_mem_o           ( data_to_mem_o_exmem ),
            .alu_result_o            ( alu_result_o_exmem  ),
            .rW_o                    ( rW_o_exmem          ),
            .jal_o                   ( jal_o_exmem         ),
            .mode_o                  ( mode_o_exmem        ),
            .data_w_o                ( data_w_o_exmem      ),
            .data_r_o                ( data_r_o_exmem      ),
            .mem_reg_o               ( mem_reg_o_exmem     ),
            .is_jump_inst_o          ( is_jump_inst_o_exmem   ),
            .reg_we_o                ( reg_we_o_exmem      ),
            .jal_en_o                ( jal_en_o_exmem      )
        );


//////////////////////////////////////////
///////////     MEM stage      ///////////
//////////////////////////////////////////

/********************/
// data hazard lwsw //
/********************/

// input
/// XXX_rd_i is the same as data hazard ex
wire ex_mem_data_w_i;
wire mem_wb_data_r_i;

// output
wire bypass_mem_data_o;

data_hazard_lwsw  u_data_hazard_lwsw (
                      .ex_mem_rd_i             ( ex_mem_rd_i         ),
                      .ex_mem_data_w_i         ( ex_mem_data_w_i     ),
                      .mem_wb_rd_i             ( mem_wb_rd_i         ),
                      .mem_wb_data_r_i         ( mem_wb_data_r_i     ),

                      .bypass_mem_data_o       ( bypass_mem_data_o   )
                  );

/***************************/
// output for data mem ctl //
/***************************/
wire [31:0] data_result_mem;
// assign data_result_mem =
//        (mem_reg_o_exmem == 0)? alu_result_o_exmem : data_i;

// data for memory using bypass
wire [31:0] bypass_mem_data_mem_wb;
assign data_o = (bypass_mem_data_o == `mem_data_from_ex_mem)?
       data_to_mem_o_exmem: bypass_mem_data_mem_wb;

assign data_addr_o = alu_result_o_exmem;
assign data_w_o = data_w_o_exmem;
assign data_r_o = data_r_o_exmem;
assign mode_o = mode_o_exmem;

/////////////////////////////////////////////////////
// 访存缩短到2周期测试，EX结果直接输出到CPU外面
// 果然不行啊……WNS直接-4.755...直接炸掉
/////////////////////////////////////////////////////
// assign data_o = (bypass_mem_data_o == `mem_data_from_ex_mem)?
//        bypass_data_B : bypass_mem_data_mem_wb;

// assign data_addr_o = alu_result_o_ex;
// assign data_w_o = data_w_o_idex;
// assign data_r_o = data_r_o_idex;
// assign mode_o = mode_o_idex;
/////////////////////////////////////////////////////


//////////////////////////////////////////
//*********       MEM/WB       *********//
//////////////////////////////////////////

// input
wire [31:0] data_result_i_mem;
wire data_r_i_from_mem;
wire [4:0] rW_i_mem;
wire [31:0] jal_i_mem;

assign data_result_i_mem = data_result_mem;
assign data_r_i_from_mem = data_r_o_exmem;
assign rW_i_mem = rW_o_exmem;
assign jal_i_mem = jal_o_exmem;
//-------------------------
wire reg_we_i_mem;
wire jal_en_i_mem;

assign reg_we_i_mem = reg_we_o_exmem;
assign jal_en_i_mem = jal_en_o_exmem;


wire mem_wb_reg_w_i;

// output
wire [31:0] data_result_o_memwb;
wire [4:0] rW_o_memwb;
wire [31:0] jal_o_memwb;
wire data_r_o_memwb;
wire reg_we_o_memwb;
wire jal_en_o_memwb;

MEM_WB  u_MEM_WB (
            .clk                     ( clk             ),
            .rst_n                   ( rst_n           ),
            .mem_wb_w_i              ( mem_wb_reg_w_i      ),

            .data_result_i           ( data_result_i_mem   ),
            .rW_i                    ( rW_i_mem            ),
            .jal_i                   ( jal_i_mem           ),

            .data_r_i                ( data_r_i_from_mem   ),
            .reg_we_i                ( reg_we_i_mem        ),
            .jal_en_i                ( jal_en_i_mem        ),

            .data_result_o           ( data_result_o_memwb ),
            .rW_o                    ( rW_o_memwb          ),
            .jal_o                   ( jal_o_memwb         ),
            .data_r_o                ( data_r_o_memwb      ),
            .reg_we_o                ( reg_we_o_memwb      ),
            .jal_en_o                ( jal_en_o_memwb      )
        );


//////////////////////////////////////////
///////////      WB stage      ///////////
//////////////////////////////////////////

// ID reg files
assign reg_we_i_id = reg_we_o_memwb;
assign rW_id = rW_o_memwb;
assign wr_data_i_id = data_result_o_memwb;
// assign jal_i_id = jal_o_memwb;
// assign jal_en_i_id = jal_en_o_memwb;

//**************************************//
///////////// hazard handler /////////////
//**************************************//


/*
 * type:     data hazard 1 for ALU
 * location: EX stage
 */

// data hazard in ex stage
assign ex_mem_w_i = reg_we_o_exmem;
assign mem_wb_w_i = reg_we_o_memwb;
assign ex_mem_rd_i = rW_o_exmem;
assign mem_wb_rd_i = rW_o_memwb;
assign id_ex_rs_i = rs_o_idex;
assign id_ex_rt_i = rt_o_idex;

// bypass A/B data
assign ex_mem_data = alu_result_o_exmem;
assign mem_wb_data = data_result_o_memwb;
assign bypass_mem_data_mem_wb = data_result_o_memwb;

/*
 * type:     data hazard 2 for jump identifier 
 * name:     data_hazard_jump.v
 * location: ID stage
 */

// input
/// ID stage
wire [4:0] if_id_rs_i;
wire [4:0] if_id_rt_i;
assign if_id_rs_i = inst_o_ifid[25:21];
assign if_id_rt_i = inst_o_ifid[20:16];

/// EX stage
wire id_ex_w_i;
wire [4:0] id_ex_rd_i;
assign id_ex_w_i = reg_we_o_idex;
assign id_ex_rd_i = rW_o_idex;
/// others have been defined

// output
wire [1:0] bypass_dataA_o;
wire [1:0] bypass_dataB_o;

assign bypass_dataA_i = bypass_dataA_o;
assign bypass_dataB_i = bypass_dataB_o;

data_hazard_jump  u_data_hazard_jump (
                      .if_id_rs_i              ( if_id_rs_i       ),
                      .if_id_rt_i              ( if_id_rt_i       ),
                      .id_ex_w_i               ( id_ex_w_i        ),
                      .id_ex_rd_i              ( id_ex_rd_i       ),
                      .ex_mem_w_i              ( ex_mem_w_i       ),
                      .ex_mem_rd_i             ( ex_mem_rd_i      ),
                      .mem_wb_w_i              ( mem_wb_w_i       ),
                      .mem_wb_rd_i             ( mem_wb_rd_i      ),

                      .bypass_dataA_o          ( bypass_dataA_o   ),
                      .bypass_dataB_o          ( bypass_dataB_o   )
                  );


assign alu_result_ex_stage = alu_result_o_ex;
assign ex_mem_j_data = alu_result_o_exmem;
assign mem_wb_j_data = data_result_o_memwb;

/*
 * type:     data hazard 3 for lw sw instruction
 * location: MEM stage
 */

assign ex_mem_data_w_i = data_w_o_exmem;
assign mem_wb_data_r_i = data_r_o_memwb;

/*
 * type:     stall pipeline
 * location: ID stage
 */

// input
wire id_ex_data_r_i;
wire ex_mem_data_r_i;
wire is_jump_inst_i;

assign id_ex_data_r_i = data_r_o_idex;
assign ex_mem_data_r_i = data_r_o_exmem;
// 对于'||'前面，是lw,bne的情况
// '||'后面，是lw,XXX,bne的情况
assign is_jump_inst_i = is_jump_inst_o_idex || is_jump_inst_o;


wire if_id_data_r_i;
wire if_id_data_w_i;

assign if_id_data_r_i = data_w_o_mem;
assign if_id_data_w_i = data_r_o_mem;

// output
wire  pc_w_o;
wire  if_id_w_o;
wire  clear_o;



stall_pipeline  u_stall_pipeline (
                    .id_ex_data_r_i          ( id_ex_data_r_i    ),
                    .id_ex_rd_i              ( id_ex_rd_i        ),
                    .ex_mem_data_r_i         ( ex_mem_data_r_i   ),
                    .ex_mem_rd_i             ( ex_mem_rd_i       ),
                    .is_jump_inst_i          ( is_jump_inst_i    ),
                    .if_id_rs_i              ( if_id_rs_i        ),
                    .if_id_rt_i              ( if_id_rt_i        ),

                    .pc_w_o                  ( pc_w_o            ),
                    .if_id_w_o               ( if_id_w_o         ),
                    .clear_o                 ( clear_o           ),

                    .if_id_data_r_i          ( if_id_data_r_i    ),
                    .if_id_data_w_i          ( if_id_data_w_i    )
                );


/*
 * type:     stall pipeline
 * description: CPU向base_instRAM读/写数据
 * location: MEM stage
 */

// input
wire [31:0] data_addr_i_stall;
assign data_addr_i_stall = alu_result_o_exmem;

// output
wire pc_w_o_mem;
wire if_id_w_o_mem;
wire clear_o_mem;

r_w_instram_stall  u_r_w_instram_stall (
                       .fast_mode_start_i       ( fast_mode_start_o ),

                       .ex_mem_data_w_i         ( ex_mem_data_w_i   ),
                       .ex_mem_data_r_i         ( ex_mem_data_r_i   ),
                       .data_addr_i             ( data_addr_i_stall ),

                       .pc_w_o                  ( pc_w_o_mem        ),
                       .if_id_w_o               ( if_id_w_o_mem     ),
                       .clear_o                 ( clear_o_mem       )
                   );

/*
 * type:     stall pipeline
 * description: load指令，全流水暂停一个周期
 * location: MEM stage
 */

// input
wire [31:0] data_addr_i_loadstall;
assign data_addr_i_loadstall = alu_result_o_exmem;

// output
wire pc_w_o_load;
wire if_id_w_o_load;
wire id_ex_w_o_load;
wire ex_mem_w_o_load;
wire mem_wb_w_o_load;


loaddata_stall  u_loaddata_stall (
                    // .clk                     ( clk               ),
                    // .rst_n                   ( rst_n             ),
                    .ex_mem_data_r_i         ( ex_mem_data_r_i   ),
                    .data_r_finish_i         ( data_r_finish_i   ), // 外部
                    .data_addr_i             ( data_addr_i_loadstall   ),

                    .pc_w_o                  ( pc_w_o_load            ),
                    .if_id_w_o               ( if_id_w_o_load         ),
                    .id_ex_w_o               ( id_ex_w_o_load         ),
                    .ex_mem_w_o              ( ex_mem_w_o_load        ),
                    .mem_wb_w_o              ( mem_wb_w_o_load        )
                );



/*
 * type:     sw_stall.v
 * description: FastMode下连续store非串口，需要暂停
 * location: MEM stage
 */

// input
wire        id_ex_w_i_swstall;
wire [31:0] id_ex_data_addr_i_swstall;
wire        if_id_w_i_swstall;

assign id_ex_w_i_swstall         = data_w_o_idex;
assign id_ex_data_addr_i_swstall = alu_result_o_ex;
assign if_id_w_i_swstall         = data_w_o_mem;


// output
wire pc_w_o_swstall;
wire if_id_w_o_swstall;
wire clear_o_swstall;

sw_stall  u_sw_stall (
              .id_ex_w_i               ( id_ex_w_i_swstall          ),
              .id_ex_data_addr_i       ( id_ex_data_addr_i_swstall   ),
              .if_id_w_i               ( if_id_w_i_swstall           ),

              .fast_mode_start_i       ( fast_mode_start_o   ),

              .pc_w_o                  ( pc_w_o_swstall      ),
              .if_id_w_o               ( if_id_w_o_swstall   ),
              .clear_o                 ( clear_o_swstall     )
          );


/*
 * type:     pc stall
 * description: CPU取指需要两个周期！
 * location: IF stage
 */


/*
 * type:     jal hazard
 * location: ID stage
 */

// 待完善

/////////////////////////////
//////  mode_convert.v //////
/////////////////////////////

// input
wire [4:0] mem_wb_rW_i          = rW_o_memwb;
wire [31:0] mem_wb_wdata_i      = data_result_o_memwb;
wire [0:0] mem_wb_reg_w_i_fast  = reg_we_o_memwb;

wire [31:0] id_G_start_i        = inst_o_ifid;

wire [0:0] id_ex_data_w_i       = data_w_o_idex;
wire [31:0] id_ex_data_addr_i   = alu_result_i; // NOTE!不是来自于reg
wire [0:0] ex_mem_data_w_i_fast = data_w_o_exmem;
wire [31:0] ex_mem_data_addr_i  = alu_result_o_exmem;

// output
wire stall_entire_cpu_o;

mode_convert  u_mode_convert (
                  .clk                     ( clk                  ),
                  .rst_n                   ( rst_n                ),

                  .mem_wb_rW_i             ( mem_wb_rW_i          ),
                  .mem_wb_wdata_i          ( mem_wb_wdata_i       ),
                  .mem_wb_reg_w_i          ( mem_wb_reg_w_i_fast  ),
                  .id_G_start_i            ( id_G_start_i         ),
                  .id_ex_data_w_i          ( id_ex_data_w_i       ),
                  .id_ex_data_addr_i       ( id_ex_data_addr_i    ),
                  .ex_mem_data_w_i         ( ex_mem_data_w_i_fast ),
                  .ex_mem_data_addr_i      ( ex_mem_data_addr_i   ),
                  .bram_w_finish_i         ( bram_w_finish_i      ), //外部

                  .prgm_start_addr_o       ( prgm_start_addr_o    ),//外部
                  .lock_addr_o             ( lock_addr_o          ),//外部
                  .bram_w_start_o          ( bram_w_start_o       ),//外部
                  .trans_enable_o          ( trans_enable_o       ),//外部
                  .stall_entire_cpu_o      ( stall_entire_cpu_o   ),//内部
                  .fast_mode_start_o       ( fast_mode_start_o    ) //内外部
              );


/////////////////////////////
// fast_start_transition.v //
/////////////////////////////

// input


// output
wire if_id_clear_o_transition;

fast_start_transition u_fast_start_transition (
                          .clk                     ( clk                      ),
                          .rst_n                   ( rst_n                    ),
                          .fast_mode_start_i       ( fast_mode_start_o        ),

                          .if_id_clear_o           ( if_id_clear_o_transition )
                      );


/////////////////////////////
///////  mem_speed.v  ///////
/////////////////////////////

// input
wire [31:0] spe_addr_i;
wire [31:0] spe_data_i;
wire [1:0] spe_mode_i;
wire spe_data_w_i;
wire spe_data_r_i;

assign spe_addr_i   = alu_result_o_exmem;
assign spe_data_i   = data_o;
assign spe_mode_i   = mode_o_exmem;
assign spe_data_w_i = data_w_o_exmem;
assign spe_data_r_i = data_r_o_exmem;


// output
wire spe_stall_pipe_o;
wire spe_or_mem_o;
wire [31:0] spe_data_o;

wire [31:0] data_from_mem = (spe_or_mem_o == 1)? spe_data_o : data_i;

assign data_result_mem =
       (mem_reg_o_exmem == 0)? alu_result_o_exmem : data_from_mem;

mem_speed  u_mem_speed (
               .clk                     ( clk                ),
               .rst_n                   ( rst_n              ),

               .spe_addr_i              ( spe_addr_i         ),
               .spe_data_i              ( spe_data_i         ),
               .spe_mode_i              ( spe_mode_i         ),
               .spe_data_w_i            ( spe_data_w_i       ),
               .spe_data_r_i            ( spe_data_r_i       ),

               .spe_stall_pipe_o        ( spe_stall_pipe_o   ),
               .spe_or_mem_o            ( spe_or_mem_o       ),
               .spe_data_o              ( spe_data_o         )
           );


// 流水暂停，列真值表
assign pc_w_i    = pc_w_o && pc_w_o_mem &&
       pc_w_o_load && pc_w_o_pcstall &&
       pc_w_o_swstall && stall_entire_cpu_o &&
       spe_stall_pipe_o;
assign if_id_w_i = if_id_w_o && if_id_w_o_mem && if_id_w_o_load
       && if_id_w_o_swstall && stall_entire_cpu_o &&
       spe_stall_pipe_o;


assign id_ex_reg_w_i = id_ex_w_o_load &&
       stall_entire_cpu_o && spe_stall_pipe_o;
assign ex_mem_reg_w_i = ex_mem_w_o_load &&
       stall_entire_cpu_o && spe_stall_pipe_o;
assign mem_wb_reg_w_i = mem_wb_w_o_load &&
       stall_entire_cpu_o && spe_stall_pipe_o;


// 除了pc_stall导致PC不允许写的情况
wire pc_w_i_exclude_pcstall = pc_w_o && pc_w_o_mem && pc_w_o_load;
assign inst_r_o = pc_w_i_exclude_pcstall;
// assign inst_r_o = 1;

// id_ex clear
assign clear_i   = clear_o || clear_o_mem || clear_o_swstall;

assign if_id_clear_i = if_id_clear_o_pcstall || if_id_clear_o_transition;


/////////////////////////////
///////  inst_i_ctl.v  //////
/////////////////////////////

// input
wire id_ex_isjump_i;
assign id_ex_isjump_i = isjump_o_idex;

// output
wire [31:0] inst_to_ifid_o;
assign inst_i_ctl_result = inst_to_ifid_o;

inst_i_ctl  u_inst_i_ctl (
                .clk                     ( clk                 ),
                .rst_n                   ( rst_n               ),

                .id_ex_isjump_i          ( id_ex_isjump_i      ),
                .inst_i                  ( inst_i              ), // 外部
                .pc_w_i                  ( pc_w_i              ), // 与直连pc的信号一样
                .fast_mode_start_i       ( fast_mode_start_o   ), // 与cpu输出一样

                .inst_to_ifid_o          ( inst_to_ifid_o      )
            );

endmodule
