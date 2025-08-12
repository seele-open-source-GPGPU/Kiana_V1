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

package i_cache;
  `define XLEN 32   // 数据位宽（例如 RISC-V XLEN = 32 位）
  `define NUM_FETCH 2    // 每次取指的指令数
  `define DEPTH_WARP 5    // Warp ID 位宽（支持的 Warp 数量 = 2^DEPTH_WARP）
  `define WIDBITS 5    // Warp ID 位宽（同 DEPTH_WARP，部分模块用这个名字）

  `define DCACHE_BLOCKWORDS 8    // 每个 Cache Block 含多少个 word
  `define DCACHE_TAGBITS 20   // Cache Tag 位数
  `define DCACHE_SETIDXBITS 7    // Cache Set 索引位宽
  `define DCACHE_WAYIDXBITS 2    // Cache Way 索引位宽（log2(DCACHE_NWAYS)）
  `define DCACHE_NSETS 128  // Cache 中 Set 的数量
  `define DCACHE_NWAYS 4    // Cache 的组相连数（几路组相连）
  `define DCACHE_BLOCKOFFSETBITS 5   // block 内的 word 偏移位宽（log2(DCACHE_BLOCKWORDS)）
  `define DCACHE_WORDOFFSETBITS 2    // word 内的 byte 偏移位宽（log2(XLEN/8)）

  `define DCACHE_MSHRENTRY 8    // MSHR 表项数量
  `define DCACHE_MSHRSUBENTRY 4    // MSHR 子表项数量
  `define DCACHE_ENTRY_DEPTH 3    // MSHR 表项深度位宽
  `define DCACHE_SUBENTRY_DEPTH 2    // MSHR 子表项深度位宽
endpackage
`endif
