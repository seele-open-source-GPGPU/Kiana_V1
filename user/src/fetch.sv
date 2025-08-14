`include "common.svh"
import common::*;
module fetch(
    input clk,
    input rst_n,
    input initialize,

    input [31:0] next_pc[32],
    input [4:0] warp_id[32],
    input [31:0] warp_mask,
    output logic [4:0] selected_warp_id,
    output logic [31:0] selected_pc,

    input s_tvalid,
    output logic s_tready,
    output logic m_tvalid,
    output logic m_tlast,
    output logic[31:0] err, // err[0] ERR_INVALID_WARP_MASK

    output logic [4:0] warp_id_update_pc,
    output logic m_tvalid_update_queue,
    output logic m_tlast_update_queue,
    input update_queue_valid
);
    logic [31:0] warp_mask_reg,_warp_mask_reg;
    logic [4:0] last_idx;
    logic [4:0] selected_id;
    logic [4:0] id_this_term;
    logic [31:0] pc_reg[32];
    logic [4:0] warp_id_reg[32];
    logic busy;

    logic [4:0] offset;
    logic [31:0] grant_next;
    logic [31:0] rotated_req;
    logic [31:0] rotated_grant;
    logic [31:0] unrotated_grant;

    logic [31:0] _err;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            s_tready<=0;
            selected_warp_id<=5'b0;
            selected_pc<='0;
            warp_mask_reg<=0;
            last_idx<=5'b11111;
            selected_id<=0;
            m_tvalid<=0;
            pc_reg<='{default:0};
            warp_id_reg<='{default:0};
            busy<=0;
            err<=0;
            m_tlast<=0;
            warp_id_update_pc<=0;
            m_tvalid_update_queue<=0;
            m_tlast_update_queue<=0;
        end 
        else begin
            _err=0;
            if(initialize) begin
                warp_id_reg<=warp_id;
                pc_reg<=next_pc;
                m_tvalid<=0;
                s_tready<=update_queue_valid;
                m_tlast<=0;
            end
            else if(update_queue_valid) begin
                s_tready<=1;
                m_tvalid<=0;
                m_tlast<=0;
                if(s_tready && s_tvalid) begin
                    warp_mask_reg<=warp_mask;
                    busy<=1;
                    if(~(|warp_mask)) _err=_err | `KIANA_SP_ERR_FETCHER_INVALID_WARP_MASK;
                    s_tready<=0;
                end
                if(busy) begin
                    _warp_mask_reg=warp_mask_reg;
                    s_tready<=0;
                    if(|_warp_mask_reg) begin
                        offset=last_idx+1;
                        rotated_req = (_warp_mask_reg >> offset) | (_warp_mask_reg << (32 - offset));
                        rotated_grant = rotated_req & (~(rotated_req - 1));
                        unrotated_grant = (rotated_grant << offset) | (rotated_grant >> (32 - offset));
                        grant_next = unrotated_grant;
                        for (int i = 0; i < 32; i++) begin
                            if (grant_next[i])
                                id_this_term = i;
                        end
                        _warp_mask_reg[id_this_term]=0;
                        m_tlast<=~(|_warp_mask_reg);
                        last_idx<=id_this_term;
                        selected_id<=id_this_term;
                        m_tvalid<=1'b1;
                        selected_warp_id<=warp_id_reg[id_this_term];
                        selected_pc<=pc_reg[id_this_term];
                        pc_reg[id_this_term]<=next_pc[id_this_term];
                        busy<=1;

                        m_tlast_update_queue<=~(|_warp_mask_reg);
                        warp_id_update_pc<=id_this_term;
                        m_tvalid_update_queue<=1;
                    end
                    else begin
                        busy<=0;
                        s_tready<=1;
                        m_tvalid<=0;
                    end
                end
                warp_mask_reg<=_warp_mask_reg;
            end
            else begin
                busy<=0;
                s_tready<=0;
                m_tvalid<=0;
            end
            err<=_err;
        end
    end
endmodule