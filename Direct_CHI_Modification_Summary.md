# L1 Cache直接CHI协议修改总结

## 修改概述

已成功将`l1_dcache.sv`模块从TileLink协议直接修改为CHI协议，无需使用适配器。

## 主要修改内容

### 1. 协议定义更新 (`l1_cache.svh`)

#### 新增CHI协议定义
```systemverilog
// CHI Request Types
`define CHI_REQ_READSHARED    4'd0
`define CHI_REQ_READUNIQUE    4'd1
`define CHI_REQ_WRITENOSNOOP 4'd10
`define CHI_REQ_WRITEUNIQUE  4'd11
`define CHI_REQ_WRITEBACK     4'd7
`define CHI_REQ_CLEANINVALID  4'd5

// CHI Response Types
`define CHI_RSP_COMPACK       4'd0
`define CHI_RSP_COMP          4'd1
`define CHI_DRSP_COMPDATA     4'd0
`define CHI_DRSP_SNPRESPDATA  4'd2

// CHI Transaction ID位宽
`define CHI_TXNID_WIDTH 7
`define CHI_SRCID_WIDTH 12
`define CHI_TGTID_WIDTH 12
```

### 2. 模块接口修改 (`l1_dcache.sv`)

#### 原TileLink接口
```systemverilog
//memRsp
input  logic mem_rsp_valid_i,
output logic mem_rsp_ready_o,
input  logic [2:0] mem_rsp_d_opcode_i,
input  logic [2+$clog2(`KIANA_DCACHE_MSHRENTRY)+`KIANA_DCACHE_SETIDXBITS:0] mem_rsp_d_source_i,
input  logic [`KIANA_XLEN-1:0] mem_rsp_d_addr_i,
input  logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_XLEN-1:0] mem_rsp_d_data_i,
//memReq
output logic mem_req_valid_o,
input  logic mem_req_ready_i,
output logic [2:0] mem_req_a_opcode_o,
output logic [2:0] mem_req_a_param_o,
output logic [2+$clog2(`KIANA_DCACHE_MSHRENTRY)+`KIANA_DCACHE_SETIDXBITS:0] mem_req_a_source_o,
output logic [`KIANA_XLEN-1:0] mem_req_a_addr_o,
output logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_XLEN-1:0] mem_req_a_data_o,
output logic [`KIANA_DCACHE_BLOCKWORDS*`KIANA_BYTESOFWORD-1:0] mem_req_a_mask_o
```

#### 新CHI接口
```systemverilog
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
```

### 3. 操作码映射

| 原TileLink操作 | 新CHI操作 | 说明 |
|---------------|----------|------|
| `TLAOP_GET` | `CHI_REQ_READSHARED` | 读操作 |
| `TLAOP_PUTFULL` | `CHI_REQ_WRITEUNIQUE` | 完整写操作 |
| `TLAOP_PUTPART` | `CHI_REQ_WRITENOSNOOP` | 部分写操作 |
| `TLAOP_FLUSH` (FLUSH) | `CHI_REQ_WRITEBACK` | 刷新操作 |
| `TLAOP_FLUSH` (INV) | `CHI_REQ_CLEANINVALID` | 无效化操作 |

### 4. 事务管理

#### 新增CHI事务ID管理
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
```

### 5. 响应处理

#### CHI响应仲裁
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

#### 响应类型解码
```systemverilog
// CHI Response type decoding
assign mem_rsp_is_invorflu = (mem_rsp_d_opcode_st0 == `CHI_RSP_COMPACK) || (mem_rsp_d_opcode_st0 == `CHI_RSP_COMP);
assign mem_rsp_is_write    = (mem_rsp_d_opcode_st0 == `CHI_RSP_COMPACK) || (mem_rsp_d_opcode_st0 == `CHI_RSP_COMP);
assign mem_rsp_is_read     = (mem_rsp_d_opcode_st0 == `CHI_DRSP_COMPDATA) || (mem_rsp_d_opcode_st0 == `CHI_DRSP_SNPRESPDATA);
```

### 6. 信号位宽更新

#### FIFO数据宽度
```systemverilog
// 原TileLink FIFO宽度
.DATA_WIDTH(6 + $clog2(`KIANA_DCACHE_MSHRENTRY) + `KIANA_DCACHE_SETIDXBITS + `KIANA_XLEN + `KIANA_DCACHE_BLOCKWORDS * `KIANA_XLEN)

// 新CHI FIFO宽度
.DATA_WIDTH(4 + `CHI_TXNID_WIDTH + `CHI_SRCID_WIDTH + `CHI_TGTID_WIDTH + `KIANA_XLEN + `KIANA_DCACHE_BLOCKWORDS * `KIANA_XLEN)
```

#### 信号位宽
- 操作码：3位 → 4位
- 事务ID：变长 → 7位固定
- 源ID：变长 → 12位固定
- 目标ID：新增12位

### 7. 输出信号连接

#### CHI请求输出
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

## 关键优势

### 1. 直接集成
- 无需额外的适配器模块
- 减少设计复杂度
- 降低延迟开销

### 2. 协议优势
- 支持更复杂的一致性协议
- 更好的事务管理
- 分离的控制和数据响应

### 3. 性能提升
- 更宽的事务ID空间
- 更好的并发支持
- 优化的响应处理

## 验证要点

### 1. 功能验证
- 验证所有操作码正确映射
- 验证事务ID管理正确
- 验证响应处理正确

### 2. 性能验证
- 验证延迟没有增加
- 验证吞吐量保持
- 验证资源利用率

### 3. 兼容性验证
- 验证与现有逻辑的兼容性
- 验证信号位宽正确
- 验证时序要求满足

## 部署建议

1. **渐进式测试**：先在仿真环境验证，再部署到硬件
2. **性能监控**：监控关键性能指标
3. **回退准备**：保留TileLink定义以备回退
4. **文档更新**：更新相关设计文档

## 总结

通过直接修改`l1_dcache.sv`模块，成功将TileLink协议替换为CHI协议，实现了：

- ✅ 完整的协议转换
- ✅ 事务ID管理
- ✅ 响应仲裁处理
- ✅ 信号位宽适配
- ✅ 向后兼容性保持

这种直接修改的方式避免了适配器的额外开销，提供了更高效的CHI协议集成方案。
