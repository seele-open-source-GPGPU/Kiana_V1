`include "common.svh"
import common::*;
module branch_unit(
    input clk,
    input rst_n,
    // 执行模块输入
    input [31:0] address_imm_in,
    input [31:0] pred_in,
    input branch_op_t branch_op,
    input s_tvalid_exe,
    input [4:0] warp_id_exe,
    output logic s_tready_exe,
    // 输出给fetch
    output logic [31:0] pred[32],
    output logic [31:0] next_pc[32],
    // 输出给记分牌，指令缓冲
    output logic m_tvalid_ib_sb,
    output logic [4:0] finish_wr_warp_id_branch,
    output logic is_finish_update_pc,
    output logic is_finish_update_pred,

    output logic [31:0] err,
    // fetch的接口
    input s_tvalid_fetch,
    input s_tlast_fetch,
    input [4:0] warp_id_fetch,
    output logic update_queue_valid
);
    // 将操作划分为pc+4（a）和非pc+4（b）两类操作
    // 理论上对于一个warp来说，b类操作提交前不会出现a类操作
    // 所有a类操作都会存储在缓冲区中，理论上所有缓冲区中的a执行完毕前b操作的通道与之不重叠
    // 所以可以同时调度多个a类和一个b类操作
    logic [31:0] address_imm_in_reg;
    logic [31:0] pred_in_reg;
    branch_op_t branch_op_reg_exe;
    logic [4:0] warp_id_exe_reg;

    wire [31:0] err_s[32];
    always_comb begin
        for(int i=0;i<32;i++) err=err | err_s[i];
    end

    logic [31:0] op_finished_s;
    wire [31:0] is_finished_op_a_type_s;
    logic ready_to_dispatch_b_type_op;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            address_imm_in_reg<=0;
            pred_in_reg<=0;
            branch_op_reg_exe<=BRA_NOP;
            warp_id_exe_reg<=0;

            m_tvalid_ib_sb<=0;
            finish_wr_warp_id_branch<='0;
            is_finish_update_pc<=0;
            is_finish_update_pred<=0;

            ready_to_dispatch_b_type_op<=0;
        end
        else begin
            m_tvalid_ib_sb<=0;
            // b类操作，先接受指令，存起来，调度每个通道自己负责
            if(s_tvalid_exe && s_tready_exe) begin
                address_imm_in_reg<=address_imm_in;
                pred_in_reg<=pred_in;
                branch_op_reg_exe<=branch_op;
                warp_id_exe_reg<=warp_id_exe;
                s_tready_exe<=0;
                ready_to_dispatch_b_type_op<=1;
            end
            // 每轮检测，如果执行b类操作的通道好了就发送结果给记分牌
            // a类操作不需要反馈什么
            if(~s_tready_exe) begin
                if(op_finished_s[warp_id_exe_reg] && ~is_finished_op_a_type_s[warp_id_exe_reg]) begin
                    s_tready_exe<=1;
                    m_tvalid_ib_sb<=1;
                    finish_wr_warp_id_branch<=warp_id_exe_reg;
                    is_finish_update_pc<=1;
                    is_finish_update_pred<=1;
                    ready_to_dispatch_b_type_op<=0;
                end
            end
        end
    end

    logic [31:0] warp_id_queue_valid;
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            warp_id_queue_valid<=0;
            update_queue_valid<=1;
        end
        else begin
            if(update_queue_valid && s_tvalid_fetch) begin
                warp_id_queue_valid[warp_id_fetch]<=1;
                if(s_tlast_fetch) begin
                    update_queue_valid<=0;
                end
            end
            else if(~update_queue_valid) begin
                update_queue_valid<=~(|warp_id_queue_valid);
            end
        end
    
        for(int i=0;i<32;i++) begin
            if(op_finished_s[i] && is_finished_op_a_type_s[i]) warp_id_queue_valid[i]<=0;
        end
    end
    genvar warp_id;
    generate
        for(warp_id=0;warp_id<32;warp_id++) begin
            branch_op_t branch_op_this_warp;
            logic s_tvalid_this;
            simt_stack u_simt_stack(
                .clk(clk),
                .rst_n(rst_n),
                .branch_op(branch_op_this_warp),
                .address_imm_in(address_imm_in_reg),
                .pred_in(pred_in_reg),
                .s_tvalid(s_tvalid_this),
                .npc_tos(next_pc[warp_id]),
                .pred_tos(pred[warp_id]),
                .err(err_s[warp_id]),
                .op_finished(op_finished_s[warp_id]),
                .is_finished_op_a_type(is_finished_op_a_type_s[warp_id])
            );
            // 给每个simt stack维护一个状态机
            always @(posedge clk or negedge rst_n) begin
                if(~rst_n) begin
                    branch_op_this_warp<=BRA_NOP;
                    s_tvalid_this<=0;
                end
                else begin
                    // 发射操作
                    if(warp_id_queue_valid[warp_id]) begin
                        branch_op_this_warp<=BRA_PC_ADD_4;
                        s_tvalid_this<=1;
                    end
                    else if(ready_to_dispatch_b_type_op && warp_id_exe==warp_id) begin
                        branch_op_this_warp<=branch_op_reg_exe;
                        s_tvalid_this<=1;
                    end 
                    else if(s_tvalid_this) s_tvalid_this<=0;
                end
            end
        end
    endgenerate

    
endmodule

module simt_stack(
    input clk,
    input rst_n,
    input branch_op_t branch_op,
    input [31:0] address_imm_in,
    input [31:0] pred_in,
    input s_tvalid,
    
    output logic [31:0] npc_tos,
    output logic [31:0] pred_tos,

    output logic [31:0] err,
    output logic op_finished,
    output logic is_finished_op_a_type
);
    logic [95:0] items [`SIMT_STACK_DEPTH];
    logic [$clog2(`SIMT_STACK_DEPTH):0] top_pointer;

    logic [31:0] _err;

    branch_op_t branch_op_reg;
    logic [31:0] address_imm_in_reg;
    logic [31:0] pred_in_reg;
    typedef enum logic[1:0] {
        IDLE,
        OPERATION,
        CHECK_AND_POP,
        SET_RESULT
    } simt_stack_op_state_t;
    simt_stack_op_state_t state;

    `define TOS_PTR top_pointer-1

    function automatic [31:0] addr_bias(input [31:0] addr, input [15:0] bias);
        reg [32:0] result;
        result = {1'b0, addr} + {{17{bias[15]}}, bias};
        return result[31:0];
    endfunction

    function automatic [31:0] get_npc(input [95:0] item);
        return item[63:32];
    endfunction

    function automatic [31:0] get_rpc(input [95:0] item);
        return item[95:64];
    endfunction

    function automatic [31:0] get_pred(input [95:0] item);
        return item[31:0];
    endfunction


    always@ (posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            top_pointer<=0;
            branch_op_reg<=BRA_NOP;
            address_imm_in_reg<=0;
            pred_in_reg<=0;
            err<=0;
            pred_tos<=0;
            npc_tos<=0;
            state<=IDLE;
            items<='{default:0};
            op_finished<=0;
            is_finished_op_a_type<=0;
        end
        else begin
            _err=0;
            op_finished<=0;
            if(s_tvalid && state==IDLE) begin
                state<=OPERATION;
                address_imm_in_reg<=address_imm_in;
                pred_in_reg<=pred_in;
                branch_op_reg<=branch_op;
            end
            if(state==OPERATION) begin
                // 进行操作
                case(branch_op) 
                    BRA_POP: begin
                        if(top_pointer==0) _err<=_err | `KIANA_SP_ERR_SIMT_STACK_UNDERFLOW;
                        top_pointer<=top_pointer-1;
                    end
                    BRA_PUSH: begin
                        logic [31:0] rpc,npc;
                        rpc=addr_bias(get_rpc(items[`TOS_PTR]),address_imm_in_reg[31:16]);
                        npc=addr_bias(get_npc(items[`TOS_PTR]),address_imm_in_reg[15:0]);

                        if(top_pointer>`SIMT_STACK_DEPTH) _err<=_err | `KIANA_SP_ERR_SIMT_STACK_OVERFLOW;
                        top_pointer<=top_pointer+1;
                        items[`TOS_PTR+1]<={rpc,npc,pred_in_reg};
                    end
                    BRA_FLUSH: begin
                        top_pointer<=0;
                    end
                    BRA_PC_ADD_4: begin
                        top_pointer<=top_pointer;
                        items[`TOS_PTR][63:32]<=get_npc(items[`TOS_PTR])+4;
                    end
                    BRA_JUMP: begin
                        top_pointer<=top_pointer;
                        items[`TOS_PTR][63:32]<=address_imm_in_reg;
                    end
                    BRA_BRANCH: begin
                        logic [31:0] rpc,npc,pred_tos,pred_jump,pred_not_jump;
                        pred_tos=get_pred(items[`TOS_PTR]);
                        if((pred_jump | pred_tos)!=pred_tos) _err<=_err | `KIANA_SP_ERR_BRANCH_UNIT_BRANCH_ERR;
                        pred_not_jump=(~pred_jump) & pred_tos;

                        rpc=addr_bias(get_rpc(items[`TOS_PTR]),address_imm_in_reg[31:16]);
                        npc=addr_bias(get_npc(items[`TOS_PTR]),address_imm_in_reg[15:0]);

                        if(top_pointer>`SIMT_STACK_DEPTH-1) _err<=_err | `KIANA_SP_ERR_SIMT_STACK_OVERFLOW;
                        top_pointer<=top_pointer+2;
                        items[`TOS_PTR][63:32]<=rpc;
                        items[`TOS_PTR+1][31:0] <=pred_not_jump;
                        items[`TOS_PTR+1][63:32] <=get_npc(items[`TOS_PTR])+4;
                        items[`TOS_PTR+1][95:64] <=rpc;

                        items[`TOS_PTR+2][31:0] <=pred_jump;
                        items[`TOS_PTR+2][63:32] <=npc;
                        items[`TOS_PTR+2][95:64] <=rpc;
                    end
                    BRA_NOP: begin
                        _err<=`KIANA_SP_ERR_BRANCH_UNIT_INVALID_OP;
                    end
                endcase
                // 检测是否有满足出栈条件的
                if(items[`TOS_PTR][95:64]==items[`TOS_PTR][63:32]) state<=CHECK_AND_POP;
                else state<=SET_RESULT;
            end
            else if(state==CHECK_AND_POP) begin
                top_pointer<=top_pointer-1;
                if(items[`TOS_PTR-1][95:64]==items[`TOS_PTR-1][63:32]) state<=CHECK_AND_POP;
                else state<=SET_RESULT;
            end
            else if(state==SET_RESULT) begin
                npc_tos<=get_npc(items[`TOS_PTR]);
                pred_tos<=get_pred(items[`TOS_PTR]);
                op_finished<=1;
                if(branch_op==BRA_PC_ADD_4) is_finished_op_a_type<=1;
                else is_finished_op_a_type<=0;
            end
            else begin
                state<=IDLE;
            end
            if(op_finished) op_finished<=0;
            err<=_err;
        end
    end
endmodule