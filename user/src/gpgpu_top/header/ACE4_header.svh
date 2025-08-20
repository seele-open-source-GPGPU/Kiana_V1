`ifndef _ACE4
`define _ACE4

package ACE4_channel;

// ==================== 全局参数定义 ====================
// ACE4 基本参数
`define ACE_DATA_WIDTH   64    // 数据总线宽度（例：64bit）
`define ACE_ADDR_WIDTH   32    // 地址总线宽度
`define ACE_ID_WIDTH     4     // 事务 ID 宽度（支持多 outstanding 事务）
`define ACE_LEN_WIDTH    8     // Burst 长度宽度（传输拍数）
`define ACE_SIZE_WIDTH   3     // 每拍传输字节数编码
`define ACE_BURST_WIDTH  2     // Burst 类型宽度（FIXED/INCR/WRAP）
`define ACE_LOCK_WIDTH   1     // Lock 信号宽度（原子锁）
`define ACE_CACHE_WIDTH  4     // Cache 属性
`define ACE_PROT_WIDTH   3     // Protection 属性
`define ACE_QOS_WIDTH    4     // QoS 服务等级
`define ACE_REGION_WIDTH 4     // Region 区域标识
`define ACE_RESP_WIDTH   2     // 响应编码（OKAY/SLVERR/DECERR）
`define ACE_STRB_WIDTH   (`ACE_DATA_WIDTH/8) // 字节使能

// ACE 扩展参数
`define ACE_SNOOP_WIDTH    4   // Snoop 类型宽度（AR/AW 通道和 AC 通道）
`define ACE_DOMAIN_WIDTH   2   // Domain 属性（Non-shareable/Inner/Outer/System）
`define ACE_BAR_WIDTH      2   // Barrier 屏障提示（顺序约束）
`define ACE_CRRESP_WIDTH   5   // CRRESP 响应类型编码（实现相关）

// ==================== 写地址通道（AW） ====================
typedef struct packed {
  logic [`ACE_ID_WIDTH-1:0]     awid;      // 写事务 ID
  logic [`ACE_ADDR_WIDTH-1:0]   awaddr;    // 写地址
  logic [`ACE_LEN_WIDTH-1:0]    awlen;     // Burst 长度
  logic [`ACE_SIZE_WIDTH-1:0]   awsize;    // 每拍大小（字节数）
  logic [`ACE_BURST_WIDTH-1:0]  awburst;   // Burst 类型
  logic [`ACE_LOCK_WIDTH-1:0]   awlock;    // 原子锁
  logic [`ACE_CACHE_WIDTH-1:0]  awcache;   // Cache 属性
  logic [`ACE_PROT_WIDTH-1:0]   awprot;    // Protection 属性
  logic                         awvalid;   // 地址有效
  logic                         awready;   // 从设备准备好
  logic [`ACE_QOS_WIDTH-1:0]    awqos;     // QoS
  logic [`ACE_REGION_WIDTH-1:0] awregion;  // 区域标识

  // ==== ACE 扩展字段 ====
  logic [`ACE_SNOOP_WIDTH-1:0]  awsnoop;   // 写事务类型（WriteUnique/WriteBack/Evict 等）
  logic [`ACE_DOMAIN_WIDTH-1:0] awdomain;  // 域属性（内/外/系统共享）
  logic [`ACE_BAR_WIDTH-1:0]    awbar;     // 屏障提示（Barrier）
  logic                         awunique;  // 唯一写提示（可选，部分实现）
} ace_aw_t;

// ==================== 写数据通道（W） ====================
typedef struct packed {
  logic [`ACE_DATA_WIDTH-1:0] wdata;     // 写数据
  logic [`ACE_STRB_WIDTH-1:0] wstrb;     // 字节掩码
  logic                      wlast;     // 最后一个拍
  logic                      wvalid;    // 数据有效
  logic                      wready;    // 从设备就绪
} ace_w_t;

// ==================== 写响应通道（B） ====================
typedef struct packed {
  logic [`ACE_ID_WIDTH-1:0]   bid;       // 写事务 ID
  logic [`ACE_RESP_WIDTH-1:0] bresp;     // 写响应（OKAY/SLVERR/DECERR）
  logic                      bvalid;    // 响应有效
  logic                      bready;    // 主设备就绪
} ace_b_t;

// ==================== 读地址通道（AR） ====================
typedef struct packed {
  logic [`ACE_ID_WIDTH-1:0]     arid;      // 读事务 ID
  logic [`ACE_ADDR_WIDTH-1:0]   araddr;    // 读地址
  logic [`ACE_LEN_WIDTH-1:0]    arlen;     // Burst 长度
  logic [`ACE_SIZE_WIDTH-1:0]   arsize;    // 每拍大小
  logic [`ACE_BURST_WIDTH-1:0]  arburst;   // Burst 类型
  logic [`ACE_LOCK_WIDTH-1:0]   arlock;    // 原子锁
  logic [`ACE_CACHE_WIDTH-1:0]  arcache;   // Cache 属性
  logic [`ACE_PROT_WIDTH-1:0]   arprot;    // Protection 属性
  logic                        arvalid;   // 地址有效
  logic                        arready;   // 从设备就绪
  logic [`ACE_QOS_WIDTH-1:0]   arqos;     // QoS
  logic [`ACE_REGION_WIDTH-1:0] arregion;  // 区域标识

  // ==== ACE 扩展字段 ====
  logic [`ACE_SNOOP_WIDTH-1:0]  arsnoop;   // 读事务类型（ReadShared/ReadUnique/ReadClean 等）
  logic [`ACE_DOMAIN_WIDTH-1:0] ardomain;  // 域属性（内/外/系统共享）
  logic [`ACE_BAR_WIDTH-1:0]    arbar;     // 屏障提示
} ace_ar_t;

// ==================== 读数据通道（R） ====================
typedef struct packed {
  logic [`ACE_ID_WIDTH-1:0]   rid;       // 读事务 ID
  logic [`ACE_DATA_WIDTH-1:0] rdata;     // 读数据
  logic [`ACE_RESP_WIDTH-1:0] rresp;     // 读响应
  logic                      rlast;     // 最后一个拍
  logic                      rvalid;    // 数据有效
  logic                      rready;    // 主设备就绪
} ace_r_t;

// ==================== ACE 额外通道 ====================

// Snoop 请求通道（AC：ACE 专用）
typedef struct packed {
  logic                         acvalid;  // Snoop 请求有效
  logic                         acready;  // 从设备准备好
  logic [`ACE_SNOOP_WIDTH-1:0]  acsnoop;  // Snoop 类型（Clean/MakeInv/ReadShared 等）
  logic [`ACE_ADDR_WIDTH-1:0]   acaddr;   // 目标行地址（对齐）
  logic [`ACE_PROT_WIDTH-1:0]   acprot;   // 保护属性（可选）
} ace_ac_t;

// Snoop 响应通道（CR：Cache Response）
typedef struct packed {
  logic                         crvalid;  // 响应有效
  logic                         crready;  // 主设备就绪
  logic [`ACE_CRRESP_WIDTH-1:0] crresp;   // 响应类型（ShareClean/UniqueDirty 等）
} ace_cr_t;

// Snoop 数据通道（CD：Cache Data）
typedef struct packed {
  logic                         cdvalid;  // 数据有效
  logic                         cdready;  // 对端就绪
  logic [`ACE_DATA_WIDTH-1:0]   cddata;   // Snoop 返回数据
  logic                         cdlast;   // 最后一拍
} ace_cd_t;

endpackage


`endif