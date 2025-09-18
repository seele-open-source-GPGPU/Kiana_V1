# L1 Cache TileLink到CHI协议修改方案

## 修改概述

本方案将L1数据缓存从TileLink协议直接修改为CHI（Coherent Hub Interface）协议，提供更现代化的一致性接口支持。

## 第一步：协议定义更新

### 1.1 在 `src/gpgpu_top/sm/l1_cache/l1_cache.svh` 中添加CHI协议定义

在`d_cache`包中添加以下CHI协议定义：

```systemverilog
package d_cache;
  // 现有定义保持不变...
  `define KIANA_TIWIDTH (`KIANA_WIDBITS+`KIANA_DCACHE_NLANES*(1+`KIANA_DCACHE_BLOCKOFFSETBITS+`KIANA_BYTESOFWORD))
  `define KIANA_BABITS (`KIANA_DCACHE_TAGBITS+`KIANA_DCACHE_SETIDXBITS)
  
  // CHI协议定义
  // CHI Request Types
  `define CHI_REQ_READSHARED    4'd0
  `define CHI_REQ_READUNIQUE    4'd1
  `define CHI_REQ_READNOTSHARED 4'd2
  `define CHI_REQ_READONCE      4'd3
  `define CHI_REQ_CLEANSHARED   4'd4
  `define CHI_REQ_CLEANINVALID  4'd5
  `define CHI_REQ_MAKEUNIQUE    4'd6
  `define CHI_REQ_WRITEBACK     4'd7
  `define CHI_REQ_WRITECLEAN    4'd8
  `define CHI_REQ_WRITEEVICT    4'd9
  `define CHI_REQ_WRITENOSNOOP 4'd10
  `define CHI_REQ_WRITEUNIQUE  4'd11
  `define CHI_REQ_WRITELINEUNIQUE 4'd12
  `define CHI_REQ_EVICT         4'd13
  `define CHI_REQ_DVMOP         4'd14
  `define CHI_REQ_DVMSYNC       4'd15

  // CHI Response Types
  `define CHI_RSP_COMPACK       4'd0
  `define CHI_RSP_COMP          4'd1
  `define CHI_RSP_COMPDBID      4'd2
  `define CHI_RSP_COMPACKDBID   4'd3
  `define CHI_RSP_SNPACK        4'd4
  `define CHI_RSP_SNPACKDBID    4'd5
  `define CHI_RSP_RETRYACK      4'd6
  `define CHI_RSP_PEERRETRYACK  4'd7
  `define CHI_RSP_DBIDRESP      4'd8
  `define CHI_RSP_SNPRESP       4'd9
  `define CHI_RSP_SNPRESPDBID   4'd10
  `define CHI_RSP_SNPRESPDATA   4'd11
  `define CHI_RSP_SNPRESPDATADBID 4'd12
  `define CHI_RSP_COPYBACK      4'd13
  `define CHI_RSP_COPYBACKDBID  4'd14
  `define CHI_RSP_PERSIST       4'd15

  // CHI Data Response Types
  `define CHI_DRSP_COMPDATA     4'd0
  `define CHI_DRSP_COMPDBID     4'd1
  `define CHI_DRSP_SNPRESPDATA  4'd2
  `define CHI_DRSP_SNPRESPDATADBID 4'd3
  `define CHI_DRSP_COPYBACK     4'd4
  `define CHI_DRSP_COPYBACKDBID 4'd5
  `define CHI_DRSP_NONSHARABLE  4'd6
  `define CHI_DRSP_CANCEL       4'd7

  // CHI Transaction ID位宽
  `define CHI_TXNID_WIDTH 7
  `define CHI_SRCID_WIDTH 12
  `define CHI_TGTID_WIDTH 12
  `define CHI_DBID_WIDTH 7
  `define CHI_PC_RID_WIDTH 4
  `define CHI_CRD_WIDTH 4

  // 保留原有TileLink定义（向后兼容）
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
```

## 第二步：模块接口修改

### 2.1 修改 `src/gpgpu_top/sm/l1_cache/dcache/l1_dcache.sv` 的模块接口

将原有的TileLink接口：

```systemverilog
module l1_dcache (
    input  logic clk,
    input  logic rst_n,
    //coreReq
    input  logic core_req_valid_i,
    output logic core_req_ready_o,
    // ... 其他core接口保持不变 ...
    
    //memRsp - 原有TileLink接口
    input  logic mem_rsp_valid_i,
    output logic mem_rsp_ready_o,
    input  logic [2:0] mem_rsp_d_opcode_i,
    input  logic [2+$clog2(`KIANA_DCACHE_MSHRENTRY)+`KIANA_DCACHE_SETIDXBITS:0] mem_rsp_d_source_i,
    input  logic [`KIANA_XLEN-1:0] mem_rsp_d_addr_i,
    input  logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_XLEN-1:0] mem_rsp_d_data_i,
    
    //memReq - 原有TileLink接口
    output logic mem_req_valid_o,
    input  logic mem_req_ready_i,
    output logic [2:0] mem_req_a_opcode_o,
    output logic [2:0] mem_req_a_param_o,
    output logic [2+$clog2(`KIANA_DCACHE_MSHRENTRY)+`KIANA_DCACHE_SETIDXBITS:0] mem_req_a_source_o,
    output logic [`KIANA_XLEN-1:0] mem_req_a_addr_o,
    output logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_XLEN-1:0] mem_req_a_data_o,
    output logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_BYTESOFWORD-1:0] mem_req_a_mask_o
);
```

替换为CHI接口：

```systemverilog
module l1_dcache (
    input  logic clk,
    input  logic rst_n,
    //coreReq
    input  logic core_req_valid_i,
    output logic core_req_ready_o,
    // ... 其他core接口保持不变 ...
    
    //CHI Request Interface
    output logic chi_req_valid_o,
    input  logic chi_req_ready_i,
    output logic [3:0] chi_req_type_o,
    output logic [`CHI_TXNID_WIDTH-1:0] chi_req_txnid_o,
    output logic [`CHI_SRCID_WIDTH-1:0] chi_req_srcid_o,
    output logic [`CHI_TGTID_WIDTH-1:0] chi_req_tgtid_o,
    output logic [`KIANA_XLEN-1:0] chi_req_addr_o,
    output logic [1:0] chi_req_size_o,
    output logic [2:0] chi_req_attr_o,
    output logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_XLEN-1:0] chi_req_data_o,
    output logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_BYTESOFWORD-1:0] chi_req_be_o,
    
    //CHI Response Interface
    input  logic chi_rsp_valid_i,
    output logic chi_rsp_ready_o,
    input  logic [3:0] chi_rsp_type_i,
    input  logic [`CHI_TXNID_WIDTH-1:0] chi_rsp_txnid_i,
    input  logic [`CHI_SRCID_WIDTH-1:0] chi_rsp_srcid_i,
    input  logic [`CHI_TGTID_WIDTH-1:0] chi_rsp_tgtid_i,
    input  logic [`KIANA_XLEN-1:0] chi_rsp_addr_i,
    input  logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_XLEN-1:0] chi_rsp_data_i,
    
    //CHI Data Response Interface
    input  logic chi_drsp_valid_i,
    output logic chi_drsp_ready_o,
    input  logic [3:0] chi_drsp_type_i,
    input  logic [`CHI_TXNID_WIDTH-1:0] chi_drsp_txnid_i,
    input  logic [`CHI_SRCID_WIDTH-1:0] chi_drsp_srcid_i,
    input  logic [`CHI_TGTID_WIDTH-1:0] chi_drsp_tgtid_i,
    input  logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_XLEN-1:0] chi_drsp_data_i
);
```

## 第三步：内部信号和逻辑修改

### 3.1 添加CHI事务管理

在模块开始部分添加：

```systemverilog
  // CHI Protocol Transaction Management
  logic [`CHI_TXNID_WIDTH-1:0] chi_txn_id_counter;
  logic [`CHI_TXNID_WIDTH-1:0] chi_txn_id_counter_next;
  logic [`CHI_SRCID_WIDTH-1:0] chi_src_id;
  
  // CHI Transaction ID counter
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      chi_txn_id_counter <= 'd0;
    end else begin
      chi_txn_id_counter <= chi_txn_id_counter_next;
    end
  end
  
  assign chi_txn_id_counter_next = (chi_req_valid_o && chi_req_ready_i) ? 
                                   chi_txn_id_counter + 1'b1 : chi_txn_id_counter;
  
  // CHI Source ID assignment (simplified)
  assign chi_src_id = `CHI_SRCID_WIDTH'({2'b00, $clog2(`KIANA_DCACHE_MSHRENTRY)+`KIANA_DCACHE_SETIDXBITS+1'b0});
```

### 3.2 操作码映射

将所有TileLink操作码替换为CHI操作码：

```systemverilog
  // 读未命中请求
  assign read_miss_req_a_opcode = `CHI_REQ_READSHARED;  // 原: `TLAOP_GET
  
  // 写未命中请求
  assign write_miss_req_a_opcode = `CHI_REQ_WRITENOSNOOP;  // 原: `TLAOP_PUTPART
  
  // 无效化/刷新请求
  assign l2flush_memreq_a_opcode = is_invalidate_st1 ? `CHI_REQ_CLEANINVALID : `CHI_REQ_WRITEBACK;  // 原: `TLAOP_FLUSH
  
  // 脏数据替换请求
  assign dirty_replace_memreq_a_opcode = `CHI_REQ_WRITEUNIQUE;  // 原: `TLAOP_PUTFULL
  
  // 写命中请求
  assign invorflu_memreq_a_opcode = waitfor_l2_flush_st2 ? l2flush_memreq_a_opcode : `CHI_REQ_WRITEUNIQUE;  // 原: `TLAOP_PUTFULL
```

### 3.3 响应处理逻辑

更新响应类型判断：

```systemverilog
  // CHI Response type decoding
  assign mem_rsp_is_invorflu = (mem_rsp_d_opcode_st0 == `CHI_RSP_COMPACK) || (mem_rsp_d_opcode_st0 == `CHI_RSP_COMP);
  assign mem_rsp_is_write    = (mem_rsp_d_opcode_st0 == `CHI_RSP_COMPACK) || (mem_rsp_d_opcode_st0 == `CHI_RSP_COMP);
  assign mem_rsp_is_read     = (mem_rsp_d_opcode_st0 == `CHI_DRSP_COMPDATA) || (mem_rsp_d_opcode_st0 == `CHI_DRSP_SNPRESPDATA);
```

### 3.4 响应信号仲裁

添加CHI响应仲裁逻辑：

```systemverilog
  // CHI Response signal selection (prioritize data response over control response)
  logic [3:0] chi_rsp_type_selected;
  logic [`CHI_TXNID_WIDTH-1:0] chi_rsp_txnid_selected;
  logic [`CHI_SRCID_WIDTH-1:0] chi_rsp_srcid_selected;
  logic [`CHI_TGTID_WIDTH-1:0] chi_rsp_tgtid_selected;
  logic [`KIANA_XLEN-1:0] chi_rsp_addr_selected;
  logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_XLEN-1:0] chi_rsp_data_selected;
  
  assign chi_rsp_type_selected = chi_drsp_valid_i ? chi_drsp_type_i : chi_rsp_type_i;
  assign chi_rsp_txnid_selected = chi_drsp_valid_i ? chi_drsp_txnid_i : chi_rsp_txnid_i;
  assign chi_rsp_srcid_selected = chi_drsp_valid_i ? chi_drsp_srcid_i : chi_rsp_srcid_i;
  assign chi_rsp_tgtid_selected = chi_drsp_valid_i ? chi_drsp_tgtid_i : chi_rsp_tgtid_i;
  assign chi_rsp_addr_selected = chi_drsp_valid_i ? 'd0 : chi_rsp_addr_i;  // Data response has no address
  assign chi_rsp_data_selected = chi_drsp_valid_i ? chi_drsp_data_i : 'd0;
```

### 3.5 信号位宽更新

更新FIFO和信号位宽：

```systemverilog
  // 更新FIFO数据宽度
  stream_fifo #(
      .DATA_WIDTH(4 + `CHI_TXNID_WIDTH + `CHI_SRCID_WIDTH + `CHI_TGTID_WIDTH + `KIANA_XLEN + `KIANA_DCACHE_BLOCKWORDS * `KIANA_XLEN),
      .FIFO_DEPTH(1)
  ) mem_rsp_q (
      // ...
  );

  // 更新信号位宽定义
  logic [3:0] mem_rsp_d_opcode_st0;  // 原: [2:0]
  logic [`CHI_TXNID_WIDTH-1:0] mem_rsp_d_txnid_st0;
  logic [`CHI_SRCID_WIDTH-1:0] mem_rsp_d_srcid_st0;  // 原: mem_rsp_d_source_st0
  logic [`CHI_TGTID_WIDTH-1:0] mem_rsp_d_tgtid_st0;
  logic [`KIANA_XLEN-1:0] mem_rsp_d_addr_st0;
  logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_XLEN-1:0] mem_rsp_d_data_st0;
```

### 3.6 输出信号连接

更新输出信号连接：

```systemverilog
  // CHI Request outputs
  assign chi_req_valid_o       = mem_req_valid;
  assign chi_req_type_o        = mem_req_st3_a_opcode;  // 4-bit CHI request type
  assign chi_req_txnid_o       = chi_txn_id_counter;
  assign chi_req_srcid_o       = chi_src_id;
  assign chi_req_tgtid_o       = 'd0;  // Target ID (assumed to be 0)
  assign chi_req_addr_o        = mem_req_st3_a_addr;
  assign chi_req_size_o        = 2'b10;  // 64-byte transfer size
  assign chi_req_attr_o        = 3'b000;  // Default attributes
  assign chi_req_data_o        = mem_req_st3_a_data;
  assign chi_req_be_o          = mem_req_st3_a_mask;
```

### 3.7 握手信号更新

更新握手信号：

```systemverilog
  // CHI Response handshake signals
  assign mem_rsp_q_enq_valid = chi_rsp_valid_i || chi_drsp_valid_i;
  assign mem_rsp_q_deq_ready = mem_rsp_is_write || mem_rsp_is_invorflu || (mem_rsp_is_read && tag_allocate_write_ready_mod && mshr_missrsp_in_ready);
  assign chi_rsp_ready_o = mem_rsp_q_enq_ready && !chi_drsp_valid_i;
  assign chi_drsp_ready_o = mem_rsp_q_enq_ready;
  
  // 更新其他握手信号
  assign tag_mem_req_fire = chi_req_valid_o && chi_req_ready_i;  // 原: mem_req_valid_o && mem_req_ready_i
  assign mem_req_q_deq_ready = (wshr_pass || (invorflu_memreq_valid_st1 && wshr_pushReq_ready)) && chi_req_ready_i && !core_rsp_st2_valid_from_memrsp;  // 原: mem_req_ready_i
```

## 第四步：操作码映射表

| 原TileLink操作 | 原TileLink参数 | 新CHI操作 | 说明 |
|---------------|---------------|----------|------|
| `TLAOP_GET` | - | `CHI_REQ_READSHARED` | 读操作 |
| `TLAOP_PUTFULL` | - | `CHI_REQ_WRITEUNIQUE` | 完整写操作 |
| `TLAOP_PUTPART` | - | `CHI_REQ_WRITENOSNOOP` | 部分写操作 |
| `TLAOP_FLUSH` | `TLAPARAM_FLUSH` | `CHI_REQ_WRITEBACK` | 刷新操作 |
| `TLAOP_FLUSH` | `TLAPARAM_INV` | `CHI_REQ_CLEANINVALID` | 无效化操作 |

## 第五步：验证要点

### 5.1 功能验证
- 验证所有TileLink操作正确映射到CHI操作
- 验证事务ID管理正确
- 验证响应数据正确性
- 验证握手信号正确

### 5.2 性能验证
- 验证延迟没有显著增加
- 验证吞吐量保持
- 验证资源利用率

### 5.3 兼容性验证
- 验证与现有L1缓存逻辑的兼容性
- 验证与上级模块的接口兼容性
- 验证信号位宽正确

## 第六步：部署建议

### 6.1 渐进式部署
1. 首先在仿真环境中验证
2. 在FPGA原型上测试
3. 最后部署到ASIC

### 6.2 回退机制
- 保留TileLink定义作为备选
- 支持运行时协议切换
- 提供配置选项

### 6.3 性能优化
- 优化事务ID分配算法
- 实现响应缓存机制
- 支持流水线优化

## 总结

通过以上修改步骤，可以将L1缓存的TileLink协议接口成功改造为CHI协议接口，实现：

- ✅ 完整的协议转换
- ✅ 事务ID管理
- ✅ 响应仲裁处理
- ✅ 信号位宽适配
- ✅ 向后兼容性保持

这种直接修改的方式避免了适配器的额外开销，提供了更高效的CHI协议集成方案。
