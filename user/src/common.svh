`ifndef  _COMMON
`define _COMMON
package common;
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,
        ALU_SUB  = 4'b0001,
        ALU_AND  = 4'b0010,
        ALU_OR   = 4'b0011,
        ALU_XOR  = 4'b0100,
        ALU_SLL  = 4'b0101,
        ALU_SRL  = 4'b0110,
        ALU_SRA  = 4'b0111,
        ALU_SLT  = 4'b1000,
        ALU_SLTU = 4'b1001,
        ALU_NOP  = 4'b1010
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
        BRANCH,
        JUMP,
        FLUSH,
        POP,
        PUSH
    } branch_op_t;
    `define SIMT_STACK_DEPTH 16

    `define KIANA_SP_ERR_FETCHER_INVALID_WARP_MASK                                  32'b0000_0000_0000_0000_0000_0000_0000_0001
    `define KIANA_SP_ERR_INSTRUCTION_BUFFER_SLOT_WRONG_OVERRIDE                     32'b0000_0000_0000_0000_0000_0000_0000_0010
    `define KIANA_SP_ERR_DECODER_WRONG_INSTRUCTION_FORMAT                           32'b0000_0000_0000_0000_0000_0000_0000_0100
    `define KIANA_SP_ERR_DISPATCHER_BOTH_LSU_ALU_USED                               32'b0000_0000_0000_0000_0000_0000_0000_1000
    `define KIANA_SP_ERR_DISPATCHER_INSTRUCTION_SELECTED_WITH_EXE_UNIT_NOT_READY    32'b0000_0000_0000_0000_0000_0000_0001_0000
endpackage
`endif