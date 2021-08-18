/////////////////////////////////////////////////////////////
////////////////////// macro definition /////////////////////
/////////////////////////////////////////////////////////////


/***********************************************************/
/*****************       instruction      ******************/
/***********************************************************/
`define and_func    6'b100100
`define or_func     6'b100101
`define xor_func    6'b100110
`define sll_func    6'b000000
`define srl_func    6'b000010
`define sllv_func   6'b000100
`define addu_func   6'b100001
`define jr_func     6'b001000

`define sltu_func 6'b101011

/***********************************************************/
/*****************         Global         ******************/
/***********************************************************/
`define rst_enable      1'b1    // reset enable
`define rst_disable     1'b0



/***********************************************************/
/*******************         IF         ********************/
/***********************************************************/

//////////////////////////
////////    pc    ////////
//////////////////////////
`define pc_enable   1'b1    // pc chip enable
`define pc_disable  1'b0    // pc chip disable

`define initial_pc  32'h8000_0000  // pc initialization 0x8000_0000


/***********************************************************/
/*******************         ID         ********************/
/***********************************************************/

//////////////////////////
//  central controler   //
//////////////////////////
`define Rtype_inst_op    6'b000000   // exclude mul
`define mul_inst_op      6'b011100

`define lui_inst_op      6'b001111
`define andi_inst_op     6'b001100
`define ori_inst_op      6'b001101   // instruction ori
`define xori_inst_op     6'b001110
`define addi_inst_op     6'b001000
`define addiu_inst_op    6'b001001
`define lb_inst_op       6'b100000
`define lw_inst_op       6'b100011
`define sb_inst_op       6'b101000
`define sw_inst_op       6'b101011


// is_j_inst_o
`define jump_inst_disable     1'b0
`define jump_inst_enable      1'b1
// mem_reg_o
`define data_from_reg           1'b0
`define data_from_mem           1'b1

/////////////////////////////////
//  jump instruction decision  //
/////////////////////////////////
`define jr_inst_op      6'b000000 // == Rtype_inst_op
`define beq_inst_op     6'b000100
`define bne_inst_op     6'b000101
`define bgtz_inst_op    6'b000111
`define bgez_inst_op    6'b000001
`define j_inst_op       6'b000010
`define jal_inst_op     6'b000011

`define b_inst_op       6'b


`define j_inst_enable   1'b1 // It is jump instruction.
`define j_inst_disable  1'b0

`define jump_enable     1'b1 // Jump to target: enable
`define jump_disable    1'b0

`define jal_enable      1'b1
`define jal_disable     1'b0

`define is_jump_inst        1'b1
`define is_not_jump_inst    1'b0

//////////////////////////
///  jump data bypass  ///
//////////////////////////
`define j_data_from_regfiles    2'b00
`define j_data_from_alu_result  2'b01
`define j_data_from_ex_mem      2'b10
`define j_data_from_mem_wb      2'b11


//////////////////////////
///   stall pipeline   ///
//////////////////////////
`define pc_write_enable     1'b1
`define pc_write_disable    1'b0
`define if_id_write_enable  1'b1
`define if_id_write_disable 1'b0
`define clear_enable        1'b1 // 允许“插入nop”
`define clear_disable       1'b0

`define id_ex_write_enable   1'b1
`define id_ex_write_disable  1'b0


`define ex_mem_write_enable   1'b1
`define ex_mem_write_disable  1'b0


`define mem_wb_write_enable   1'b1
`define mem_wb_write_disable  1'b0

//////////////////////////
////    reg files    /////
//////////////////////////
`define zero_register   5'b0    // $0

/* signal: reg_we_i */
`define reg_write_enable    1'b1
`define reg_write_disable   1'b0


//////////////////////////
/////  rW selection  /////
//////////////////////////

/* signal: reg_dst_i */
`define reg_dst_rd  1'b0    // R-type rW = rd
`define reg_dst_rt  1'b1    // I-type rW = rt


//////////////////////////
/////  imm extension /////
//////////////////////////

/* signal: zero_sign_ext_i */
`define imm_zero_extension  1'b0
`define imm_sign_extension  1'b1


/***********************************************************/
/*******************         EX         ********************/
/***********************************************************/

//////////////////////////
///////    ALU    ////////
//////////////////////////

/* signal: alu_src_i */
`define B_calculate     1'b0    // source operand = B
`define imm_calculate   1'b1    // source operand = imm_ext

// ALU operation
/* signal:op_i  from ALU_stl.v */
`define and_op      4'b0000
`define or_op       4'b0001
`define xor_op      4'b0010
`define sll_op      4'b0011
`define srl_op      4'b0100
`define add_op      4'b0101
`define mul_op      4'b0110
`define lui_op      4'b0111
`define other_op    4'b1000

`define sllv_op     4'b1001

`define sltu_op     4'b1010
//////////////////////////
///   ALU controler    ///
//////////////////////////

/* signal: alu_op_i */
// from central controler, 与之共用
`define Rtype_alu_op    4'b0000
`define mul_alu_op      4'b0001
`define lui_alu_op      4'b0010
`define andi_alu_op     4'b0011
`define ori_alu_op      4'b0100
`define xori_alu_op     4'b0101
`define add_alu_op      4'b0110 // addi addiu lb lw sb sw
`define other_alu_op    4'b0111


//////////////////////////
///    data hazard     ///
//////////////////////////
`define data_from_regfile   2'b00
`define data_from_EX_MEM    2'b10
`define data_from_MEM_WB    2'b01

/***********************************************************/
/*******************         MEM         *******************/
/***********************************************************/

`define byte_mode     2'b00 // or default mode
`define word_mode     2'b10

`define initial_data_addr  32'h8040_0000

//////////////////////////
///   ext_ram_ctl.v    ///
//////////////////////////
`define data_w_enable       1'b1
`define data_w_disable      1'b0
`define data_r_enable       1'b1
`define data_r_disable      1'b0


//////////////////////////
/// data_hazard_lwsw.v ///
//////////////////////////
`define mem_data_from_ex_mem    1'b0
`define mem_data_from_mem_wb    1'b1


/***********************************************************/
/*******************         WB         ********************/
/***********************************************************/



////////////////////////////////////////////////////////////
//////////////////                        //////////////////
//////////////////     external device    //////////////////
//////////////////                        //////////////////
////////////////////////////////////////////////////////////


/***********************************************************/
/*******************        UART        ********************/
/***********************************************************/

//////////////////////////
///    uart_buffer.v   ///
//////////////////////////
`define uart_data_avai_enable    1'b1
`define uart_data_avai_disable   1'b0

`define r_data_write_enable      1'b1
`define r_data_write_disable     1'b0

`define uart_data_read_enable    1'b1
`define uart_data_read_disable   1'b0
`define uart_data_write_enable   1'b1
`define uart_data_write_disable  1'b0


`define uart_data_idle          1'b1
`define uart_data_busy          1'b0

`define t_start_enable      1'b1
`define t_start_disable     1'b0


`define r_clear_enable      1'b1
`define r_clear_disable     1'b0

// signal addr
`define cpu_read_serial_data      1'b0
`define cpu_read_serial_status    1'b1

//////////////////////////
///    arbitration.v   ///
//////////////////////////
`define d_serial_memory     2'b00    // 数据目标是串口
`define d_ext_data_memory   2'b01    // 数据目标是Ext_dataRAM
`define d_base_data_memory  2'b10    // 数据目标是Base_instRAM
`define d_other_memory      2'b11    // 正常取指

`define read_data_from_baseram     1'b1
`define read_data_not_from_baseram 1'b0

//////////////////////////
///   base_ram_ctl.v   ///
//////////////////////////
// 当前模块已经弃用！但宏定义保留，其他模块有用
`define baseram_busy            1'b1
`define baseram_idle            1'b0

`define inst_read_finish        1'b1
`define inst_read_unfinish      1'b0

`define inst_write_finish       1'b1
`define inst_write_unfinish     1'b0

`define inst_read_enable        1'b1
`define inst_read_disable       1'b0

`define inst_write_enable        1'b1
`define inst_write_disable       1'b0


`define invalid 1'b0  // in arbitration.v

//////////////////////////
///     sram_ctl.v     ///
//////////////////////////
`define sram_busy            1'b1
`define sram_idle            1'b0

`define data_read_finish        1'b1
`define data_read_unfinish      1'b0

`define data_write_finish       1'b1
`define data_write_unfinish     1'b0

`define data_read_enable        1'b1
`define data_read_disable       1'b0

`define data_write_enable        1'b1
`define data_write_disable       1'b0

////////////////////////////////////////////////////////////
//////////////////                        //////////////////
//////////////////     lab3pro性能优化     //////////////////
//////////////////                        //////////////////
////////////////////////////////////////////////////////////


//////////////////////////
///   mode_convert.v   ///
//////////////////////////
`define bram_write_enable       1'b1
`define bram_write_disable      1'b0

`define bram_write_finish       1'b1
`define bram_write_unfinish     1'b0


`define transmitter_enable      1'b1
`define transmitter_disable     1'b0

`define fast_mode               1'b1
`define normal_mode             1'b0

`define reg_v0                  5'd2

`define lock_addr_enable        1'b1
`define lock_addr_disable       1'b0

`define all_reg_w_enable        1'b1
`define all_reg_w_disable       1'b0

//////////////////////////
///   base_ram_ctl.v   ///
//////////////////////////
`define bram_w_data_disable     1'b0
`define bram_w_data_enable      1'b1

