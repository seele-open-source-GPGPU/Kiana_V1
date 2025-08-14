`include "common.svh"
import common::*;
module instruction_buffer_and_scoreboard(
    input clk,
    input rst_n,
    // 与译码器的接口
    input [4:0] warp_id_decoder,
    input s_tvalid_decoder,
    input s_tlast_decoder,
    input [4:0] rd,
    input [4:0] rs1,
    input [4:0] rs2,
    input [7:0] opcode,
    input [31:0] imm,
    input [7:0] feature_flags, // [0]:alu [1]:lsu [2]:write_pc [3]:depends on pc [4]:write_pred [5]:depends on pred
    // 和调度器的接口
    input m_tready_schedular,
    input [4:0] target_warp,
    input [4:0] target_gpr_in, // | valid 1b | gpr-id 4b |
    input [3:0] target_unir_in, // | valid 1b | unir-id 3b |
    input target_is_pc,
    input target_is_pred,
    input s_tvalid_schedular,
    output [31:0] warp_ready_mask,
    output logic [62:0] instruction_buffer[32],
    output logic m_tvalid_schedular,

    // 与取指模块的接口
    input m_tready_fetch,
    output logic m_tvalid_fetch,
    output logic [31:0] warp_fetch_mask,
    // 与寄存器文件的接口
    input s_tvalid_rf,
    input [4:0] finish_wr_warp_id_rf,
    input [4:0] finish_wr_gpr,
    input [3:0] finish_wr_unir,
    // 与分支模块的接口
    input s_tvalid_bar,
    input [4:0] finish_wr_warp_id_bar,
    input is_finish_update_pc,
    input is_finish_update_pred,
    // 错误码
    output logic err
);
    // 组合逻辑信号
    logic [15:0] _scoreboard_gpr[32];
    logic [7:0] _scoreboard_uni;
    logic _scoreboard_pred [32];
    logic _scoreboard_pc [32];
    logic [31:0] _instruction_buffer_ready;
    logic [62:0] _instruction_buffer [32];
    logic [62:0] instruction_info_packed_input;

    logic [15:0] scoreboard_gpr[32];
    logic [7:0] scoreboard_uni;
    logic scoreboard_pred [32];
    logic scoreboard_pc [32];
    logic waiting_for_feed_back;
    logic [31:0] instruction_buffer_valid;
    logic [31:0] instruction_buffer_ready;

    logic [31:0] _err;

    // 62:58   57:53   52:48   47:40   39:8   7:0
    assign instruction_info_packed_input={rd,rs1,rs2,opcode,imm,feature_flags};
    assign warp_ready_mask=instruction_buffer_ready;
    
    always_comb begin
        // 接收指令输入
        for(int i=0;i<32;i++) begin
            if(warp_id_decoder==i && s_tvalid_decoder && waiting_for_feed_back) _instruction_buffer[i]=instruction_info_packed_input;
            else _instruction_buffer[i]=instruction_buffer[i];
        end

        // 即时更新sb
        _scoreboard_gpr=scoreboard_gpr;
        _scoreboard_uni=scoreboard_uni;
        _scoreboard_pred=scoreboard_pred;
        _scoreboard_pc=scoreboard_pc;
        if(s_tvalid_schedular) begin
            if(target_gpr_in[4])  _scoreboard_gpr[target_warp][target_gpr_in[3:0]]=1;
            if(target_unir_in[3]) _scoreboard_uni[target_unir_in[2:0]]=1;
            if(target_is_pc)      _scoreboard_pc[target_warp]=1;
            if(target_is_pred)    _scoreboard_pred[target_warp]=1;
        end
        if(s_tvalid_rf) begin
            if(finish_wr_gpr[4])  _scoreboard_gpr[finish_wr_warp_id_rf][finish_wr_gpr[3:0]]=0;
            if(finish_wr_unir[3]) _scoreboard_uni[finish_wr_unir[2:0]]=0;
        end
        if(s_tvalid_bar) begin
            if(is_finish_update_pc) _scoreboard_pc[finish_wr_warp_id_bar]=0;
            if(is_finish_update_pred) _scoreboard_pred[finish_wr_warp_id_bar]=0;
        end

        // 即时更新ib_ready
        for(int i=0;i<32;i++) begin
            logic rs1_used,rs2_used,rd_used,pc_used,pred_used;
            rs1_used=~(&_instruction_buffer[i][57:53]);
            rs2_used=~(&_instruction_buffer[i][52:48]);
            rd_used =~(&_instruction_buffer[i][62:58]);
            pc_used = _instruction_buffer[i][2] || _instruction_buffer[i][3];
            pred_used = _instruction_buffer[i][4] || _instruction_buffer[i][5];
            
            if(rs1<16)      _instruction_buffer_ready[i]= ~(_scoreboard_gpr[i][rs1[3:0]] && rs1_used);
            else if(rs1<24) _instruction_buffer_ready[i]= (~(_scoreboard_uni[rs1[2:0]] && rs1_used)) && _instruction_buffer_ready[i];

            if(rs2<16)      _instruction_buffer_ready[i]= ~(_scoreboard_gpr[i][rs2[3:0]] && rs2_used)&& _instruction_buffer_ready[i];
            else if(rs2<24) _instruction_buffer_ready[i]= (~(_scoreboard_uni[rs2[2:0]] && rs2_used)) && _instruction_buffer_ready[i];

            if(rd<16)       _instruction_buffer_ready[i]= ~(_scoreboard_gpr[i][rd[3:0]] && rd_used)&& _instruction_buffer_ready[i];
            else if(rd<24)  _instruction_buffer_ready[i]= (~(_scoreboard_uni[rd[2:0]] && rd_used)) && _instruction_buffer_ready[i];
            
            _instruction_buffer_ready[i]= ~(pc_used && _scoreboard_pc[i]) && _instruction_buffer_ready[i];
            _instruction_buffer_ready[i]= ~(pred_used && _scoreboard_pred[i]) && _instruction_buffer_ready[i];
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            instruction_buffer<='{default:0};
            instruction_buffer_ready<=0;
            instruction_buffer_valid<=0;

            scoreboard_gpr<='{default:0};
            scoreboard_uni<=0;
            scoreboard_pred<='{default:0};
            scoreboard_pc<='{default:0};

            waiting_for_feed_back<=0;
            err<=0;
            warp_fetch_mask<=0;
            m_tvalid_schedular<=0;
        end
        else begin
            _err=0;
            // 首先是指令缓存接口 取值模块
            // 接收
            if(s_tvalid_decoder && waiting_for_feed_back) begin
                // 开始传输
                if(instruction_buffer_valid[warp_id_decoder]) _err<=_err | `KIANA_SP_ERR_INSTRUCTION_BUFFER_SLOT_WRONG_OVERRIDE;
                instruction_buffer_valid[warp_id_decoder]<=1;
                if(s_tlast_decoder) begin
                    waiting_for_feed_back<=0;
                end
                else begin
                    waiting_for_feed_back<=1;
                end
                m_tvalid_fetch<=0;
            end
            // 发送
            else if(~waiting_for_feed_back && m_tready_fetch && (~&instruction_buffer_valid)) begin
                waiting_for_feed_back<=1;
                warp_fetch_mask<=~instruction_buffer_valid;
                m_tvalid_fetch<=1;
            end
            else begin
                m_tvalid_fetch<=0;
            end
            instruction_buffer<=_instruction_buffer;

            // 其次是调度器接口
            scoreboard_gpr <=_scoreboard_gpr;
            scoreboard_uni <=_scoreboard_uni;
            scoreboard_pred<=_scoreboard_pred;
            scoreboard_pc  <=_scoreboard_pc;
            instruction_buffer_ready<=_instruction_buffer_ready;
            if(s_tvalid_schedular) begin
                // 如果这条指令需要写入pc或谓词，就不把valid置为0
                if(instruction_buffer[target_warp][2] || instruction_buffer[target_warp][4]) instruction_buffer_valid[target_warp]<=1;
                else instruction_buffer_valid[target_warp]<=0;
                m_tvalid_schedular<=1;
            end
            else if(~m_tready_schedular) m_tvalid_schedular<=0;
            // bar接口
            if(s_tvalid_bar) begin
                if(instruction_buffer[finish_wr_warp_id_bar][2]==is_finish_update_pc && instruction_buffer[finish_wr_warp_id_bar][4]==is_finish_update_pred) begin
                    instruction_buffer_valid[finish_wr_warp_id_bar]<=0;
                end
            end
            err<=_err;
        end
    end
endmodule