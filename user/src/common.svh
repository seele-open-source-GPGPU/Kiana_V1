`ifndef  _COMMON
`define _COMMON
package common;
    typedef enum logic [3:0] {
        ALU_ADD,
        ALU_SUB, 
        ALU_AND, 
        ALU_OR,  
        ALU_XOR, 
        ALU_SLL, 
        ALU_SRL, 
        ALU_SRA, 
        ALU_SLT, 
        ALU_SLTU,
        ALU_NOP
    } alu_op_t;

    typedef enum logic [2:0] {
        LSU_LOAD_BYTE,
        LSU_LOAD_HALF_WORD,
        LSU_LOAD_WORD,
        LSU_STORE_BYTE,
        LSU_STORE_HALF_WORD,
        LSU_STORE_WORD
    } lsu_op_t;

    typedef enum logic [2:0] {
        BRA_BRANCH,
        BRA_JUMP,
        BRA_FLUSH,
        BRA_POP,
        BRA_PUSH,
        BRA_PC_ADD_4,
        BRA_NOP
    } branch_op_t;

    `define SIMT_STACK_DEPTH 16

    `define KIANA_SP_ERR_FETCHER_INVALID_WARP_MASK                                  32'b0000_0000_0000_0000_0000_0000_0000_0001
    `define KIANA_SP_ERR_INSTRUCTION_BUFFER_SLOT_WRONG_OVERRIDE                     32'b0000_0000_0000_0000_0000_0000_0000_0010
    `define KIANA_SP_ERR_DECODER_WRONG_INSTRUCTION_FORMAT                           32'b0000_0000_0000_0000_0000_0000_0000_0100
    `define KIANA_SP_ERR_DISPATCHER_BOTH_LSU_ALU_USED                               32'b0000_0000_0000_0000_0000_0000_0000_1000
    `define KIANA_SP_ERR_DISPATCHER_INSTRUCTION_SELECTED_WITH_EXE_UNIT_NOT_READY    32'b0000_0000_0000_0000_0000_0000_0001_0000
    `define KIANA_SP_ERR_SIMT_STACK_OVERFLOW                                        32'b0000_0000_0000_0000_0000_0000_0010_0000
    `define KIANA_SP_ERR_SIMT_STACK_UNDERFLOW                                       32'b0000_0000_0000_0000_0000_0000_0100_0000
    `define KIANA_SP_ERR_BRANCH_UNIT_INVALID_OP                                     32'b0000_0000_0000_0000_0000_0000_1000_0000

    `define KIANA_SP_ERR_BRANCH_UNIT_BRANCH_ERR                                     32'b0000_0000_0000_0000_0000_0001_0000_0000
    `define KIANA_SP_ERR_ISSUE_FIFO_OVERFLOW                                        32'b0000_0000_0000_0000_0000_0010_0000_0000
    function is_special(input [102:0] in);
        return in[0];
    endfunction

    function is_lsu(input [102:0] in);
        return in[1];
    endfunction

    function is_alu(input [102:0] in);
        return in[2];
    endfunction

    function [31:0] get_pred(input [102:0] in);
        return in[34:3];
    endfunction

    function [7:0] get_feature_flags(input [102:0] in);
        return in[42:35];
    endfunction

    function [31:0] get_imm(input [102:0] in);
        return in[74:43];
    endfunction

    function [7:0] get_opcode(input [102:0] in);
        return in[82:75];
    endfunction

    function [4:0] get_rs2(input [102:0] in);
        return in[87:83];
    endfunction

    function [4:0] get_rs1(input [102:0] in);
        return in[92:88];
    endfunction

    function [4:0] get_rd(input [102:0] in);
        return in[97:93];
    endfunction

    function [4:0] get_warp_id(input [102:0] in);
        return in[102:98];
    endfunction
endpackage
`endif