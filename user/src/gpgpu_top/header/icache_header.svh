`ifndef _ICACHE
`define _ICACHE

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

`endif