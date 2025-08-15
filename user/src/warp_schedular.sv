`include "common.svh"
import common::*;
module warp_schedular(
    input clk,
    input rst_n,
    output logic [31:0] err,
    input [31:0] warp_ready_mask,
    input [62:0] instruction_buffer[32],
    input [31:0] pred[32],
    // 发射信息给记分牌
    output logic [4:0] target_warp,
    output logic [4:0] target_gpr_out,
    output logic [3:0] target_unir_out,
    output logic target_is_pc,
    output logic target_is_pred,
    output logic m_tvalid_ib_sb,
    output logic s_tready_schedular,
    input s_tvalid_schedular,
    // 封装为发射请求，储存在发射请求fifo中
    input m_tready_request_fifo,
    output logic m_tvalid_request_fifo,
    output logic [102:0] dispatch_request,

    input m_tready_alu,
    input m_tready_lsu,
    input m_tready_special
);  
    logic [4:0] dispatch_warp_id;
    logic [62:0] dispatched_instruction;
    logic [31:0] warp_pred;
    logic m_tvalid_alu;
    logic m_tvalid_lsu;
    logic m_tvalid_special;
    // dispatched_instruction = {rd,rs1,rs2,opcode,imm,feature_flags}; 62:58   57:53   52:48   47:40   39:8   7:0
    // 102:98 97:35 34:3 2 1 0
    assign dispatch_request={dispatch_warp_id,dispatched_instruction,warp_pred,m_tvalid_alu,m_tvalid_lsu,m_tvalid_special};
    // 根据运行单元的状态构建发射掩码
    logic [31:0] dispatch_mask_alu;
    logic [31:0] dispatch_mask_lsu;
    logic [31:0] other_instruction_mask;
    // 62:58   57:53   52:48   47:40   39:8   7:0
    // assign instruction_info_packed_input={rd,rs1,rs2,opcode,imm,feature_flags};
    logic [4:0] offset;
    logic [31:0] grant_next;
    logic [31:0] rotated_req;
    logic [31:0] rotated_grant;
    logic [31:0] unrotated_grant;
    logic [4:0] last_idx;
    logic [31:0] arbiter_mask;
    logic [4:0] selected_warp_id;

    logic [31:0] _err;
    always_comb begin
        for(int i=0;i<32;i++) begin
            dispatch_mask_alu[i]=~(instruction_buffer[i][0] && (~m_tready_alu));
            dispatch_mask_lsu[i]=~(instruction_buffer[i][1] && (~m_tready_lsu));
            other_instruction_mask[i]=~(instruction_buffer[i][0] && instruction_buffer[i][1] && ~m_tready_special);
        end
        arbiter_mask=dispatch_mask_alu & dispatch_mask_lsu & other_instruction_mask & warp_ready_mask;
    end
    // alu和lsu分作两个发射队列。互不影响。
    // 发射一条指令后等一个周期再发射
    logic waiting;
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            last_idx<=0;
            s_tready_schedular<=1;
            err<=0;
            m_tvalid_ib_sb<=0;
            target_is_pred<=0;
            target_is_pc<=0;
            target_unir_out<=0;
            target_gpr_out<=0;
            target_warp<=0;

            warp_pred<=0;
            dispatch_warp_id<=0;
            dispatched_instruction<=0;
            m_tvalid_alu<=0;
            m_tvalid_lsu<=0;
            m_tvalid_special<=0;

            m_tvalid_request_fifo<=0;
            waiting<=0;
        end
        else begin
            _err=0;
            if(|arbiter_mask && s_tready_schedular && m_tready_request_fifo && ~waiting) begin
                logic [4:0] rd;
                s_tready_schedular<=0;
                offset=last_idx+1;
                rotated_req = (arbiter_mask >> offset) | (arbiter_mask << (32 - offset));
                rotated_grant = rotated_req & (~(rotated_req - 1));
                unrotated_grant = (rotated_grant << offset) | (rotated_grant >> (32 - offset));
                grant_next = unrotated_grant;
                for (int i = 0; i < 32; i++) begin
                    if (grant_next[i])
                        selected_warp_id = i;
                end
                warp_pred<=pred[selected_warp_id];
                dispatched_instruction<=instruction_buffer[selected_warp_id];
                dispatch_warp_id<=selected_warp_id;
                rd=instruction_buffer[selected_warp_id];
                case({instruction_buffer[selected_warp_id][0],instruction_buffer[selected_warp_id][1]})
                    2'b00:begin
                        if(m_tready_special) m_tvalid_special<=1;
                        else _err=_err | `KIANA_SP_ERR_DISPATCHER_INSTRUCTION_SELECTED_WITH_EXE_UNIT_NOT_READY;
                    end
                    2'b01:begin
                        if(m_tready_alu) m_tvalid_alu<=1;
                        else _err=_err | `KIANA_SP_ERR_DISPATCHER_INSTRUCTION_SELECTED_WITH_EXE_UNIT_NOT_READY;
                    end
                    2'b10:begin
                        if(m_tready_lsu) m_tvalid_lsu<=1;
                        else _err=_err | `KIANA_SP_ERR_DISPATCHER_INSTRUCTION_SELECTED_WITH_EXE_UNIT_NOT_READY;
                    end
                    default:begin
                        _err=_err | `KIANA_SP_ERR_DISPATCHER_BOTH_LSU_ALU_USED;
                    end
                endcase
                // 发射结果写回记分牌
                target_warp<=selected_warp_id;
                if(rd<16) begin
                    target_gpr_out<={1'b1,rd[3:0]};
                    target_unir_out<=0;
                end
                else if(rd<24)begin
                    target_gpr_out<=0;
                    target_unir_out<={1'b1,rd[2:0]};
                end
                else begin
                    target_gpr_out<=0;
                    target_unir_out<=0;
                end
                target_is_pc<=instruction_buffer[selected_warp_id][2];
                target_is_pred<=instruction_buffer[selected_warp_id][4];
                m_tvalid_ib_sb<=1;
                m_tvalid_request_fifo<=1;
                waiting<=1;
            end
            else begin 
                s_tready_schedular<=1;
                waiting<=0;
            end
            if(m_tvalid_ib_sb) m_tvalid_ib_sb<=0;
            if(m_tvalid_request_fifo) m_tvalid_request_fifo<=0;
            err<=_err;
        end
    end
endmodule