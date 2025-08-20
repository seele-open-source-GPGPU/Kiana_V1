`include "global.svh"

`ifndef _DCACHE
`define _DCACHE 
package dcache;
  // 规模参数（字节/集合/路数）
  `define KIANA_DCACHE_SET_SIZE 32              // 32 sets
  `define KIANA_DCACHE_BLOCK_SIZE 128             // 128B (一行字节数)
  `define KIANA_DCACHE_DATA_SIZE 8               // 8B 数据口
  `define KIANA_DCACHE_WAY_NUM 4

  // 派生位宽
  `define KIANA_DCACHE_WAY_WTH $clog2(`KIANA_DCACHE_WAY_NUM)

  // 地址切片：| TAG | INDEX | BLOCK_OFFSET |
  `define KIANA_DCACHE_TAG_LSB 12
  `define KIANA_DCACHE_TAG_WTH 32
  `define KIANA_DCACHE_TAG_MSB (`KIANA_DCACHE_TAG_LSB + `KIANA_DCACHE_TAG_WTH)

  `define KIANA_DCACHE_SET_LSB 7
  `define KIANA_DCACHE_SET_WTH $clog2(`KIANA_DCACHE_SET_SIZE)
  `define KIANA_DCACHE_SET_MSB (`KIANA_DCACHE_SET_LSB + `KIANA_DCACHE_SET_WTH)

  `define KIANA_DCACHE_BLOCK_LSB 0
  `define KIANA_DCACHE_BLOCK_WTH $clog2(`KIANA_DCACHE_BLOCK_SIZE)
  `define KIANA_DCACHE_BLOCK_MSB (`KIANA_DCACHE_BLOCK_LSB + `KIANA_DCACHE_BLOCK_WTH)

  `define KIANA_DCACHE_DATA_LSB 0
  `define KIANA_DCACHE_DATA_WTH $clog2(`KIANA_DCACHE_DATA_SIZE)
  `define KIANA_DCACHE_DATA_MSB (`KIANA_DCACHE_DATA_LSB + `KIANA_DCACHE_DATA_WTH)

  `define KIANA_DCACHE_INDEX_WIDTH 12      // bits
  `define KIANA_DCACHE_TAG_WIDTH 44      // bits
  `define KIANA_DCACHE_LINE_WIDTH 128     // bits (⚠ 与 BLOCK_SIZE=128B 不一致)
  `define KIANA_DCACHE_SET_ASSOC 8

  `define KIANA_DCACHE_OFFSET_WIDTH $clog2(`KIANA_DCACHE_LINE_WIDTH/8)              // =4 (若行宽=128b)
  `define KIANA_DCACHE_NUM_WORDS (2**(`KIANA_DCACHE_INDEX_WIDTH-`KIANA_DCACHE_OFFSET_WIDTH))
  `define KIANA_DCACHE_CL_IDX_WIDTH $clog2(`KIANA_DCACHE_NUM_WORDS)                 // =8
  `define KIANA_DCACHE_NUM_BANKS (`KIANA_DCACHE_LINE_WIDTH/64)                   // =2 (若每 beat=64b)

  `define SBUF_LEN 4
  `define SBUF_WTH $clog2(`SBUF_LEN)

  `define MSHR_LEN 4
  `define MSHR_WTH $clog2(`MSHR_LEN)
  // =====================================================================
  typedef enum logic [1:0] {
    Dirty   = 0,
    Trunk   = 1,
    Branch  = 2,
    Nothing = 3
  } cache_state_e;

  typedef enum logic [0:0] {
    READ  = 0,
    WRITE = 1
  } cache_cmd_e;

  typedef enum logic [0:0] {
    MMU = 0,
    LSU = 1
  } req_src_e;

  typedef struct packed {
    logic [`AWTH-1:0] paddr;
    logic             cacheable;

    size_e                   size;
    logic                    is_store;
    logic                    is_load;
    logic                    is_amo;
    logic [`ROB_WTH-1:0]     rob_idx;
    logic [`PHY_REG_WTH-1:0] rdst_idx;
    logic                    rdst_is_fp;
    amo_opcode_e             amo_op;
    logic                    sign_ext;
    logic [`SBUF_WTH-1:0]    sbuf_idx;

    logic [`DWTH-1:0]                 data;
    logic [`KIANA_DCACHE_WAY_NUM-1:0] way_en;
    logic [7:0]                       be;
    logic [7:0]                       lookup_be;
    logic                             we;
  } dcache_req_t;

  typedef struct packed {
    logic                             valid;
    logic [2:0]                       offset;
    logic                             cacheable;
    logic                             is_store;
    logic                             is_load;
    logic                             is_amo;
    logic [63:0]                      rdata;
    logic [`PHY_REG_WTH-1:0]          rdst_idx;
    logic [`ROB_WTH-1:0]              rob_idx;
    logic [`SBUF_WTH-1:0]             sbuf_idx;
    logic                             rdst_is_fp;
    size_e                            size;
    amo_opcode_e                      amo_op;
    logic [`KIANA_DCACHE_WAY_NUM-1:0] way_en;
    logic [7:0]                       be;
    logic                             sign_ext;
    logic                             mshr_empty;
    logic                             st1_idle;
  } dcache_rsp_t;

  typedef enum logic [0:0] {
    REFILL = 1'b0,
    UPDATE = 1'b1
  } miss_req_cmd_e;

  typedef struct packed {
    miss_req_cmd_e                            cmd;
    logic                                     cacheable;
    logic                                     we;
    logic [7:0]                               be;
    logic [63:0]                              wdata;
    amo_opcode_e                              amo_op;
    logic [`KIANA_DCACHE_TAG_MSB-1:0]         addr;
    logic [$clog2(`KIANA_DCACHE_WAY_NUM)-1:0] update_way;
    // logic [$clog2(DCACHE_WAY_NUM)-1:0]  rpl_way;
  } miss_req_bits_t;

  typedef struct packed {
    logic                                valid;
    logic [31:0]                         paddr;
    logic [`MSHR_LEN-1:0][`MSHR_WTH-1:0] entry_loc;
    logic [`MSHR_WTH:0]                  entry_cnt;
    miss_req_cmd_e                       cmd;
    logic [`KIANA_DCACHE_WAY_WTH-1:0]    update_way;
    logic                                cacheable;
    logic                                we;
    logic                                issue;
    logic                                replay;
  } mshr_head_t;

  typedef struct packed {
    logic                               is_store;
    logic                               is_load;
    logic                               is_amo;
    req_src_e                           src;
    logic [`DWTH-1:0]                   data;
    logic [7:0]                         be;
    logic [7:0]                         lookup_be;
    size_e                              size;
    logic [`ROB_WTH-1:0]                rob_idx;
    logic [`PHY_REG_WTH-1:0]            rdst_idx;
    logic                               rdst_is_fp;
    logic                               sign_ext;
    logic [`SBUF_WTH-1:0]               sbuf_idx;    // Store Buffer idx
    amo_opcode_e                        amo_op;
    logic [`KIANA_DCACHE_BLOCK_WTH-1:0] cl_offset;
  } mshr_entry_t;

  typedef struct packed {
    logic [63:0] cause;  // cause of exception
    logic [63:0] tval;   // additional information of causing exception (e.g.: instruction causing it),
                         // address of LD/ST fault
    logic        valid;
  } exception_t;


  typedef struct packed {
    logic [`KIANA_DCACHE_TAG_WTH-1:0] tag;
    cache_state_e                     state;
    logic                             valid;
  } tag_t;

  typedef struct packed {
    logic                             we;
    logic [`KIANA_DCACHE_WAY_NUM-1:0] way_en;
    logic [`KIANA_DCACHE_TAG_LSB-1:0] idx;
    tag_t                             wr_tag;
  } tag_req_t;

  typedef struct packed {tag_t [`KIANA_DCACHE_WAY_NUM-1:0] tag_data;} tag_rsp_t;

  typedef struct packed {
    logic                                 we;
    logic [`KIANA_DCACHE_WAY_NUM-1:0]     way_en;
    logic [`KIANA_DCACHE_TAG_LSB-1:0]     idx;
    logic [`KIANA_DCACHE_DATA_SIZE*8-1:0] wr_data;
    logic [`KIANA_DCACHE_DATA_SIZE-1:0]   wstrb;
  } data_req_t;

  typedef struct packed {logic [`KIANA_DCACHE_WAY_NUM-1:0][`KIANA_DCACHE_DATA_SIZE*8-1:0] rd_data;} data_rsp_t;

  typedef enum logic[2:0] {  
        MIN  = 0,
        MAX  = 1,
        MINU = 2,
        MAXU = 3,
        ADD  = 4
    } TL_Atomocs_Arith;

    typedef enum logic[2:0] {  
        XOR  = 0,
        OR   = 1,
        AND  = 2,
        SWAP = 3
    } TL_Atomocs_logic;

endpackage
`endif
