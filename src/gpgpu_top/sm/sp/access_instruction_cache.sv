`include "common.svh"
import common::*;
module access_instruction_cache(
    input clk,
    input rst_n,
    // 从取值模块来的信息
    output                  ready_icache,
    input [31:0]            npc_i,
    input [`NUM_WARP-1:0]   warp_id_mask_i,
    input                   tlast_i,
    input                   valid_i,
    // 输出给译码器
    output logic            tvalid_o,
    output logic            tlast_o,
    output logic [`NUM_WARP-1:0]    warp_id_mask_o,
    output logic [31:0]             instructino_o,
    output logic [31:0]             npc_o
);

endmodule