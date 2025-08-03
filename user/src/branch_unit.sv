`include "common.svh"
import common::*;
module branch_unit(
    input clk,
    input rst_n,
    input [31:0] address_in,
    input [31:0] pred_in,
    input branch_op_t branch_op,
    input s_tvalid,
    output logic s_tready,

    output logic [31:0] pred[32],
    output logic [31:0] next_pc[32],

    output logic m_tvalid_branch,
    output logic [4:0] finish_wr_warp_id_branch,
    output logic is_finish_update_pc,
    output logic is_finish_update_pred
);
    logic [$clog2(`SIMT_STACK_DEPTH):0] top_point; // 指向栈顶下一个元素放置的位置
    logic [95:0] simt_stack [`SIMT_STACK_DEPTH][32];
    logic busy;
    
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            simt_stack<='{default:0};
            top_point<=0;
            s_tready<=1;
            busy<=0;
        end
        else begin
            if(s_tvalid && s_tready) begin
                busy<=1;
                
            end
        end
    end
endmodule