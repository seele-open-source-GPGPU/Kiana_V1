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

package icache;
  // 指令位宽（例如 RV32）
  `define FETCH_WIDTH 32
  // 组数 / 行大小 / 数据口宽度
  `define KIANA_ICACHE_SET_SIZE 32          // 组数（sets）
  `define KIANA_ICACHE_BLOCK_SIZE 128         // 一行 128B
  `define KIANA_ICACHE_DATA_SIZE 8           // 单拍 8B（64-bit 口）
  // 路数（ways）
  `define KIANA_ICACHE_WAY_NUM 4
  // 一次取指返回字节数（你写 4B，这里保留）
  `define KIANA_ICACHE_FETCH_SIZE 4
  // 派生位宽
  `define KIANA_ICACHE_FETCH_WTH $clog2(`KIANA_ICACHE_FETCH_SIZE)   // = 2 (4B)
  `define KIANA_ICACHE_BLOCK_WTH $clog2(`KIANA_ICACHE_BLOCK_SIZE)   // = 7 (128B)
  `define KIANA_ICACHE_DATA_WTH $clog2(`KIANA_ICACHE_DATA_SIZE)    // = 3 (8B)
  `define KIANA_ICACHE_SET_WTH $clog2(`KIANA_ICACHE_SET_SIZE)     // = 5 (32 组)
  // 地址切片：| Tag | Index | BlockOffset |
  `define KIANA_ICACHE_BLOCK_LSB 0
  `define KIANA_ICACHE_BLOCK_MSB (`KIANA_ICACHE_BLOCK_LSB + `KIANA_ICACHE_BLOCK_WTH)   // = 7
  `define KIANA_ICACHE_SET_LSB `KIANA_ICACHE_BLOCK_MSB           // = 7
  `define KIANA_ICACHE_SET_MSB (`KIANA_ICACHE_SET_LSB + `KIANA_ICACHE_SET_WTH)       // = 12
  `define KIANA_ICACHE_TAG_LSB `KIANA_ICACHE_SET_MSB             // = 12
  `define KIANA_ICACHE_TAG_WTH 32
  `define KIANA_ICACHE_TAG_MSB (`KIANA_ICACHE_TAG_LSB + `KIANA_ICACHE_TAG_WTH)       // = 44
  `define KIANA_ICACHE_DATA_MSB (`KIANA_ICACHE_BLOCK_WTH + `KIANA_ICACHE_FETCH_WTH)   // = 5
  typedef struct packed {
    logic        fetch_valid;      // address translation valid
    logic [63:0] fetch_paddr;      // physical address in
    excp_t       fetch_exception;  // exception occurred during fetch
  } icache_areq_i_t;

  typedef struct packed {
    logic        fetch_valid;      // address translation valid
    logic [63:0] fetch_paddr;      // physical address in
    excp_t       fetch_exception;  // exception occurred during fetch
  } mmu_icache_rsp_t;

  typedef struct packed {
    logic        fetch_req;    // address translation request
    logic [63:0] fetch_vaddr;  // virtual address out
    logic        cacheable;
  } icache_mmu_req_t;

  typedef struct packed {
    logic        fetch_req;    // address translation request
    logic [63:0] fetch_vaddr;  // virtual address out
  } icache_areq_o_t;

  // I$ data requests
  typedef struct packed {
    logic        req;      // we request a new word
    logic        kill_s1;  // kill the current request
    logic        kill_s2;  // kill the last request
    logic [63:0] vaddr;    // 1st cycle: 12 bit index is taken for lookup
  } icache_dreq_i_t;

  typedef struct packed {
    logic                    ready;  // icache is ready
    logic                    valid;  // signals a valid read
    logic [`FETCH_WIDTH-1:0] data;   // 2+ cycle out: tag
    logic [63:0]             vaddr;  // virtual address out
    excp_t                   ex;     // we've encountered an exception
  } icache_dreq_o_t;

  // I$ data requests
  typedef struct packed {
    logic        req;    // we request a new word
    logic        kill;   // kill the current request
    logic [63:0] vaddr;  // 1st cycle: 12 bit index is taken for lookup
  } fetch_req_t;

  typedef struct packed {
    logic                    ready;  // icache is ready
    logic                    valid;  // signals a valid read
    logic [`FETCH_WIDTH-1:0] data;   // 2+ cycle out: tag
    logic [63:0]             vaddr;  // virtual address out
    excp_t                   ex;     // we've encountered an exception
  } fetch_rsp_t;
endpackage

package AX14_channel;
  typedef struct packed {
    logic [3:0]  awid;      // Write address ID
    logic [31:0] awaddr;    // Write address
    logic [7:0]  awlen;     // Burst length
    logic [2:0]  awsize;    // Burst size
    logic [1:0]  awburst;   // Burst type
    logic        awlock;    // Lock type
    logic [3:0]  awcache;   // Cache type
    logic [2:0]  awprot;    // Protection type
    logic        awvalid;   // Write address valid
    logic        awready;   // Write address ready
    logic [3:0]  awqos;     // Quality of Service
    logic [3:0]  awregion;  // Region identifier
  } axi_aw_t;

  typedef struct packed {
    logic [`FETCH_WIDTH-1:0] wdata;   // Write data
    logic [3:0]              wstrb;   // Write strobes
    logic                    wlast;   // Write last
    logic                    wvalid;  // Write valid
    logic                    wready;  // Write ready
  } axi_w_t;

  typedef struct packed {
    logic [3:0] bid;     // Write response ID
    logic [1:0] bresp;   // Write response
    logic       bvalid;  // Write response valid
    logic       bready;  // Write response ready
  } axi_b_t;

  typedef struct packed {
    logic [3:0]  arid;      // Read address ID
    logic [31:0] araddr;    // Read address
    logic [7:0]  arlen;     // Burst length
    logic [2:0]  arsize;    // Burst size
    logic [1:0]  arburst;   // Burst type
    logic        arlock;    // Lock type
    logic [3:0]  arcache;   // Cache type
    logic [2:0]  arprot;    // Protection type
    logic        arvalid;   // Read address valid
    logic        arready;   // Read address ready
    logic [3:0]  arqos;     // Quality of Service
    logic [3:0]  arregion;  // Region identifier
  } axi_ar_t;

  typedef struct packed {
    logic [3:0]              rid;     // Read ID
    logic [`FETCH_WIDTH-1:0] rdata;   // Read data
    logic [1:0]              rresp;   // Read response
    logic                    rlast;   // Read last
    logic                    rvalid;  // Read valid
    logic                    rready;  // Read ready
  } axi_r_t;

endpackage
`endif
