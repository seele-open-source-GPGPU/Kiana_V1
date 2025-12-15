`ifndef SP_DEFINES
`define SP_DEFINES

`define NUM_WARP 4 // 只能更小不能更大,要是2的幂次
`define NUM_THREAD 4
`define NUM_SP_INTERRUPT 32
`define NUM_COMMON_CSR 8

`define INTERRUPT_CSR_METADATA_INVALID_ADDR (NUM_SP_INTERRUPT'b1)
`define INTERRUPT_CSR_INVALID_COMMON_CSR_OP (NUM_SP_INTERRUPT'b1<<1)
`define INTERRUPT_SIMT_STACK_OP_CONFLICT    (NUM_SP_INTERRUPT'b1<<2)
`define INTERRUPT_SIMT_STACK_OVERFLOW       (NUM_SP_INTERRUPT'b1<<3)
`define INTERRUPT_SIMT_STACK_UNDERFLOW      (NUM_SP_INTERRUPT'b1<<4)

typedef enum logic [2:0] {
   BRANCH,
   JUMP,
   FLUSH,
   POP,
   PUSH,
   PC_ADD_4,
   NOP,
   SETRPC
} SmitStackOperation_t;

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
   SmitStackOperation_t BranchOp;
   control_op_t ControlOp;
   logic UnpredictablePC;
   logic UseALU;
   logic UseLSU;
   logic UseCtrl;
   logic UseBranch;
} Instruction_t;

function automatic logic [$clog2(`NUM_WARP)-1:0] onehot_to_bin_num_warp (
    input logic [`NUM_WARP-1:0] onehot
);
    logic [$clog2(`NUM_WARP)-1:0] idx;
    idx = '0;

    for (int i = 0; i < `NUM_WARP; i++) begin
        if (onehot[i])
            idx = i[$clog2(`NUM_WARP)-1:0];
    end

    return idx;
endfunction

`endif
