`ifndef _GLOBAL
`define _GLOBAL

// ===================== 基础位宽定义 =====================
`define IWTH             32       // 指令宽度 Instruction Width
`define AWTH             64       // 地址宽度 Address Width
`define DWTH             64       // 数据宽度 Data Width

// ===================== 物理寄存器相关 =====================
`define PHY_REG          64
`define PHY_REG_WTH      $clog2(`PHY_REG)

`define PHY_FP_REG       64
`define PHY_FP_REG_WTH   $clog2(`PHY_FP_REG)

// ===================== ROB 配置 =====================
`define ROB_LEN          8
`define ROB_WTH          $clog2(`ROB_LEN)

// typedef logic [SIZE_WTH-1:0]        size_t;   
// typedef logic [SOURCE_WTH-1:0]      source_t;
// typedef logic [ADDRESS_WTH-1:0]     address_t;
// typedef logic [MASK_WTH-1:0]        mask_t;
// typedef logic [DATA_WTH-1:0]        data_t;
// typedef logic [SINK_WTH-1:0]        sink_t;

//     localparam PARAM_WTH = 3;
//     localparam SIZE_WTH = 8;
//     localparam SOURCE_WTH = 6;
//     localparam ADDRESS_WTH = 64;
//     localparam DATA_WTH = 64;
//     localparam MASK_WTH = 8;
//     localparam SINK_WTH = 4;

`endif