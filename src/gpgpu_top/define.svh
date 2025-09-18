`ifndef _DEFINE
`define _DEFINE 

`define KIANA_NUM_SM 2 //the number of sm
`define KIANA_NUM_CLUSTER 1 //the number of cluster
`define KIANA_NUM_THREAD 4 //the number of thread
`define KIANA_NUM_WARP 8 //the number of warp
`define KIANA_XLEN 32   // 数据位宽（例如 RISC-V XLEN = 32 位）
`define KIANA_NUM_FETCH 2    // 每次取指的指令数
`define KIANA_DEPTH_WARP $clog2(`KIANA_NUM_WARP)    // Warp ID 位宽（支持的 Warp 数量 = 2^DEPTH_WARP）
`define KIANA_WIDBITS `KIANA_DEPTH_WARP    // Warp ID 位宽（同 DEPTH_WARP，部分模块用这个名字）
`define KIANA_BYTESOFWORD 4 //a word has 4 bytes
`define KIANA_WORDLENGTH `KIANA_XLEN
`define KIANA_LENGTH_REPLACE_TIME 10
`define KIANA_NUM_SM_IN_CLUSTER `KIANA_NUM_SM/`KIANA_NUM_CLUSTER //the number of sm in a cluster
`define KIANA_NUM_L2CACHE 1 //the number of l2cache in gpgpu

package i_cache;
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

package d_cache;
  `define KIANA_DCACHE_NSETS 32
  `define KIANA_DCACHE_NWAYS 2
  `define KIANA_DCACHE_BLOCKWORDS 2// Both L1$D and L1$I use this parameter
  `define KIANA_DCACHE_WSHR_ENTRY 4//no bigger than KIANA_DCACHE_MSHRENTRY
  `define KIANA_DCACHE_SETIDXBITS $clog2(`KIANA_DCACHE_NSETS)
  `define KIANA_DCACHE_WAYIDXBITS $clog2(`KIANA_DCACHE_NWAYS)
  `define KIANA_DCACHE_WORDOFFSETBITS $clog2(`KIANA_BYTESOFWORD)
  `define KIANA_DCACHE_BLOCKOFFSETBITS $clog2(`KIANA_DCACHE_BLOCKWORDS) //select word in block
  `define KIANA_DCACHE_TAGBITS (`KIANA_XLEN-(`KIANA_DCACHE_SETIDXBITS+`KIANA_DCACHE_BLOCKOFFSETBITS+`KIANA_DCACHE_WORDOFFSETBITS))
  `define KIANA_DCACHE_MSHRENTRY 4//4
  `define KIANA_DCACHE_MSHRSUBENTRY 2
  `define KIANA_DCACHE_NLANES `KIANA_NUM_THREAD
  `define KIANA_DCACHE_ENTRY_DEPTH $clog2(`KIANA_DCACHE_MSHRENTRY)
  `define KIANA_DCACHE_SUBENTRY_DEPTH $clog2(`KIANA_DCACHE_MSHRSUBENTRY)
  `define KIANA_TIWIDTH (`KIANA_WIDBITS+`KIANA_DCACHE_NLANES*(1+`KIANA_DCACHE_BLOCKOFFSETBITS+`KIANA_BYTESOFWORD))
  `define KIANA_BABITS (`KIANA_DCACHE_TAGBITS+`KIANA_DCACHE_SETIDXBITS)
  //tilelink interconnect
  `define TLAOP_GET 3'd4
  `define TLAOP_PUTFULL 3'd0
  `define TLAOP_PUTPART 3'd1
  `define TLAOP_FLUSH 3'd5
  `define TLAPARAM_FLUSH 3'd0
  `define TLAPARAM_INV 3'd1
  `define TLAOP_ARITH 3'd2
  `define TLAOP_LOGIC 3'd3
  `define TLAPARAM_ARITHMIN 3'd0
  `define TLAPARAM_ARITHMAX 3'd1
  `define TLAPARAM_ARITHMINU 3'd2
  `define TLAPARAM_ARITHMAXU 3'd3
  `define TLAPARAM_ARITHADD 3'd4
  `define TLAPARAM_LOGICXOR 3'd0
  `define TLAPARAM_LOGICOR 3'd1
  `define TLAPARAM_LOGICAND 3'd2
  `define TLAPARAM_LOGICSWAP 3'd3
  `define TLAPARAM_LRSC 3'd1
endpackage

package shared_mem;
  `define KIANA_SHAREDMEM_DEPTH 128
  `define KIANA_SHAREDMEM_NWAYS 1
  `define KIANA_SHAREDMEM_BLOCKWORDS `KIANA_DCACHE_BLOCKWORDS
  `define KIANA_SHAREMEM_SIZE (`KIANA_SHAREDMEM_DEPTH * `KIANA_SHAREDMEM_BLOCKWORDS * 4)
  `define KIANA_SHAREMEM_NLANES `KIANA_NUM_THREAD
  `define KIANA_SHAREMEM_NBANKS `KIANA_DCACHE_BLOCKWORDS
  `define KIANA_SHAREDMEM_BLOCKOFFSETBITS $clog2(`KIANA_SHAREDMEM_BLOCKWORDS)
  `define KIANA_SHAREMEM_BANKIDXBITS $clog2(`KIANA_SHAREMEM_NBANKS)
  `define KIANA_SHAREMEM_BANKOFFSET ((`KIANA_SHAREDMEM_BLOCKOFFSETBITS > `KIANA_SHAREMEM_BANKIDXBITS) ? (`KIANA_SHAREDMEM_BLOCKOFFSETBITS - `KIANA_SHAREMEM_BANKIDXBITS) : 1 )
endpackage

package l2_cache;
`define KIANA_L2CACHE_NSETS 2
`define KIANA_L2CACHE_NWAYS 4
`define KIANA_L2CACHE_BLOCKWORDS `KIANA_DCACHE_BLOCKWORDS
`define KIANA_L2CACHE_WRITEBYTES 1
`define KIANA_L2CACHE_MEMCYCLES 4
`define KIANA_L2CACHE_PORTFACTOR 2 

//l2cache_define
`define KIANA_L2CACHE_LEVEL 2
`define KIANA_L2CACHE_BLOCKBYTES        (`KIANA_L2CACHE_BLOCKWORDS * 4)
`define KIANA_L2CACHE_BEATBYTES         (`KIANA_L2CACHE_BLOCKWORDS * 4)
`define KIANA_L2CACHE_BLOCKS            (`KIANA_L2CACHE_NWAYS * `KIANA_L2CACHE_NSETS )//4/2 =2
`define KIANA_L2CACHE_SIZEBYTES         (`KIANA_L2CACHE_BLOCKS * `KIANA_L2CACHE_BLOCKBYTES)
`define KIANA_L2CACHE_BLOCKBEATS        (`KIANA_L2CACHE_BLOCKBYTES / `KIANA_L2CACHE_BEATBYTES) // 8/8 = 1
`define KIANA_L2CACHE_NUM_WARP          `KIANA_NUM_WARP
`define KIANA_L2CACHE_NUM_SM            `KIANA_NUM_SM
`define KIANA_L2CACHE_NUM_SM_IN_CLUSTER `KIANA_NUM_SM_IN_CLUSTER  //2
`define KIANA_L2CACHE_NUM_CLUSTER       `KIANA_NUM_CLUSTER //1
`define KIANA_OP_BITS                   3
`define KIANA_PARAM_BITS                3   //3+lg2(4)+lg2(32）+lg2(2) + 0+1 = 3+2+5+1 +1 =12
`define KIANA_SOURCE_BITS               (3 + $clog2(`KIANA_DCACHE_MSHRENTRY) + $clog2(`KIANA_DCACHE_NSETS) + $clog2(`KIANA_L2CACHE_NUM_SM_IN_CLUSTER) + $clog2(`KIANA_L2CACHE_NUM_CLUSTER) + 1)
`define KIANA_URCE_S_BITS				(3 + $clog2(`KIANA_DCACHE_MSHRENTRY) + $clog2(`KIANA_DCACHE_NSETS) + $clog2(`KIANA_L2CACHE_NUM_SM_IN_CLUSTER) + $clog2(`KIANA_NUM_CACHE_IN_SM) + 1)
`define KIANA_URCE_L_BITS				(3 + $clog2(`KIANA_DCACHE_MSHRENTRY) + $clog2(`KIANA_DCACHE_NSETS) + $clog2(`KIANA_L2CACHE_NUM_SM_IN_CLUSTER) + $clog2(`KIANA_NUM_CACHE_IN_SM) + $clog2(`KIANA_NUM_CLUSTER) + 1)
`define KIANA_DATA_BITS                 (`KIANA_L2CACHE_BEATBYTES * 8)
`define KIANA_MASK_BITS                 (`KIANA_L2CACHE_BEATBYTES / `KIANA_L2CACHE_WRITEBYTES)
`define KIANA_SIZE_BITS                 ($clog2(`KIANA_L2CACHE_BEATBYTES))
`define KIANA_MSHRS                     ((`KIANA_L2CACHE_MEMCYCLES + `KIANA_L2CACHE_BLOCKBEATS - 1) / `KIANA_L2CACHE_BLOCKBEATS )
`define KIANA_SECONDARY                 (((`KIANA_MSHRS > (`KIANA_L2CACHE_MEMCYCLES - `KIANA_MSHRS)) ? `KIANA_MSHRS : (`KIANA_L2CACHE_MEMCYCLES - `KIANA_MSHRS)))
`define KIANA_PUTLISTS                  `KIANA_L2CACHE_MEMCYCLES
`define KIANA_PUTBEATS                  ( (((2 * `KIANA_L2CACHE_BLOCKBEATS) > `KIANA_L2CACHE_MEMCYCLES) ? (2 * `KIANA_L2CACHE_BLOCKBEATS) : `KIANA_L2CACHE_MEMCYCLES))
`define KIANA_RELLISTS                  2   //2*1 = 16 > 4 ? 2* 1 ：4
`define KIANA_RELBEATS                  (`KIANA_RELLISTS * `KIANA_L2CACHE_BLOCKBEATS)
`define KIANA_ADDRESS_BITS              32
`define KIANA_WAY_BITS                  ($clog2(`KIANA_L2CACHE_NWAYS)     )
`define KIANA_SET_BITS                  ($clog2(`KIANA_L2CACHE_NSETS)     )
`define KIANA_OFFSET_BITS               ($clog2(`KIANA_L2CACHE_BLOCKBYTES))
`define KIANA_L2C_BITS                  $clog2(`KIANA_NUM_L2CACHE) //`define  KIANA_L2C_BITS = $clog2(`KIANA_NUM_L2CACHE)
`define KIANA_TAG_BITS                  (`KIANA_ADDRESS_BITS - `KIANA_SET_BITS - `KIANA_OFFSET_BITS - `KIANA_L2C_BITS)
`define KIANA_PUT_BITS                  ($clog2(`KIANA_PUTLISTS))
`define KIANA_INNER_MASK_BITS           (`KIANA_L2CACHE_BEATBYTES / `KIANA_L2CACHE_WRITEBYTES)
`define KIANA_OUTER_MASK_BITS           (`KIANA_L2CACHE_BEATBYTES / `KIANA_L2CACHE_WRITEBYTES)
`define KIANA_PUTLISTS                  `KIANA_L2CACHE_MEMCYCLES
//tilelink interface opcode
`define       PUTFULLDATA           3'd0         //                            => AccessAck
`define       PUTPARTIALDATA        3'd1         //                            => AccessAck
`define       ARITHMETICDATA        3'd2         //                            => AccessAckData
`define       LOGICALDATA           3'd3         //                            => AccessAckData
`define       GET                   3'd4         //                            => AccessAckData
`define       HINT                  3'd5         //                            => HintAck
`define       ACQUIREBLOCK          3'd6         //                            => Grant[Data]
`define       ACQUIREPERM           3'd7         //                            => Grant[Data]
`define       PROBE                 3'd6         //                            => ProbeAck[Data]
`define       ACCESSACK             3'd0         //                   
`define       ACCESSACKDATA         3'd1         //                   
`define       HINTACK               3'd2         //                   
`define       PROBEACK              3'd4         //               
`define       PROBEACKDATA          3'd5         //               
`define       RELEASE               3'd6         //                            => ReleaseAck
`define       RELEASEDATA           3'd7         //                            => ReleaseAck
`define       GRANT                 3'd4         //                            => GrantAck
`define       GRANTDATA             3'd5         //                            => GrantAck
`define       RELEASEACK            3'd6         //                    
`define       GRANTACK              3'd0         //  
endpackage

`endif
