`ifndef _COMMON
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
        LSU_STORE_WORD,
        LSU_NON
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

    typedef enum logic [3:0] {
        Lui,
        Auipc,
        Fence,
        SoftIr,
        SyncWorkGroup,
        SyncWarp,
        SyncGlobal,
        Ret,
        CsrRw,
        CsrRs,
        CsrRc,
        CsrRwi,
        CsrRsi,
        CsrRci,
        Ctrl_Non
    } control_op_t;
    typedef struct {
        logic [6:0] Opcode;
        logic [4:0] SrcReg1;
        logic [4:0] SrcReg2;
        logic [4:0] DstReg;
        logic [31:0] Imm;
        logic [11:0] Csr;
        logic [2:0] Funct3;
        alu_op_t AluOp;
        lsu_op_t LsuOp;
        branch_op_t BranchOp;
        control_op_t ControlOp;
    } Instruction_t;


    `define SIMT_STACK_DEPTH 16

    `define KIANA_SP_ERR_FETCHER_INVALID_WARP_MASK 32'b0000_0000_0000_0000_0000_0000_0000_0001
    `define KIANA_SP_ERR_INSTRUCTION_BUFFER_SLOT_WRONG_OVERRIDE 32'b0000_0000_0000_0000_0000_0000_0000_0010
    `define KIANA_SP_ERR_DECODER_WRONG_INSTRUCTION_FORMAT 32'b0000_0000_0000_0000_0000_0000_0000_0100
    `define KIANA_SP_ERR_DISPATCHER_BOTH_LSU_ALU_USED 32'b0000_0000_0000_0000_0000_0000_0000_1000
    `define KIANA_SP_ERR_DISPATCHER_INSTRUCTION_SELECTED_WITH_EXE_UNIT_NOT_READY 32'b0000_0000_0000_0000_0000_0000_0001_0000
    `define KIANA_SP_ERR_SIMT_STACK_OVERFLOW 32'b0000_0000_0000_0000_0000_0000_0010_0000
    `define KIANA_SP_ERR_SIMT_STACK_UNDERFLOW 32'b0000_0000_0000_0000_0000_0000_0100_0000
    `define KIANA_SP_ERR_BRANCH_UNIT_INVALID_OP 32'b0000_0000_0000_0000_0000_0000_1000_0000

    `define KIANA_SP_ERR_BRANCH_UNIT_BRANCH_ERR 32'b0000_0000_0000_0000_0000_0001_0000_0000
endpackage

`endif
