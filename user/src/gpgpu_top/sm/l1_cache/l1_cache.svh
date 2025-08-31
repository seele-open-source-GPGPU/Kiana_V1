`ifndef _l1cache
`define _l1cache
package i_cache;
  `define KIANA_NUM_WARP 8 //the number of warp
  `define KIANA_XLEN 32   // 数据位宽（例如 RISC-V XLEN = 32 位）
  `define KIANA_NUM_FETCH 2    // 每次取指的指令数
  `define KIANA_DEPTH_WARP $clog2(`KIANA_NUM_WARP)    // Warp ID 位宽（支持的 Warp 数量 = 2^DEPTH_WARP）
  `define KIANA_WIDBITS `KIANA_DEPTH_WARP    // Warp ID 位宽（同 DEPTH_WARP，部分模块用这个名字）

  `define KIANA_ICACHE_BLOCKWORDS 2    // 每个 Cache Block 含多少个 word
  `define KIANA_ICACHE_TAGBITS (`KIANA_XLEN-(`KIANA_ICACHE_SETIDXBITS+`KIANA_ICACHE_BLOCKOFFSETBITS+`KIANA_ICACHE_WORDOFFSETBITS))   // Cache Tag 位数
  `define KIANA_ICACHE_SETIDXBITS $clog2(`KIANA_ICACHE_NSETS)    // Cache Set 索引位宽
  `define KIANA_ICACHE_WAYIDXBITS $clog2(`KIANA_ICACHE_NWAYS)    // Cache Way 索引位宽（log2(ICACHE_NWAYS)）
  `define KIANA_ICACHE_NSETS 32  // Cache 中 Set 的数量
  `define KIANA_ICACHE_NWAYS 2    // Cache 的组相连数（几路组相连）
  `define KIANA_ICACHE_BLOCKOFFSETBITS $clog2(`KIANA_ICACHE_BLOCKWORDS)   // block 内的 word 偏移位宽（log2(ICACHE_BLOCKWORDS)）
  `define KIANA_ICACHE_WORDOFFSETBITS 2    // word 内的 byte 偏移位宽（log2(XLEN/8)）

  `define KIANA_ICACHE_MSHRENTRY 4    // MSHR 表项数量
  `define KIANA_ICACHE_MSHRSUBENTRY 2    // MSHR 子表项数量
  `define KIANA_ICACHE_ENTRY_DEPTH $clog2(`KIANA_ICACHE_MSHRENTRY)    // MSHR 表项深度位宽
  `define KIANA_ICACHE_SUBENTRY_DEPTH $clog2(`KIANA_ICACHE_MSHRSUBENTRY)    // MSHR 子表项深度位宽
endpackage
`endif