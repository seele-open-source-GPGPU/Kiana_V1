`include "sp_defines.svh"
module fetch(
    input clk,
    input rst_n,
    // 和ibuffer与scoreboard的交互
    input [`NUM_WARP-1:0]           fetch_mask_i,
    input                           fetch_valid_i,
    output                          ready_o,
    // 控制面来的执行掩码
    input [`NUM_WARP-1:0]           execute_mask_i,
    // 和分支模块的交互
    input [`NUM_WARP-1:0]           npc_valid_mask_i,    
    input [31:0]                    npc_i [`NUM_WARP],
    input [`NUM_WARP-1:0]           branch_ready_i,
    
    output logic [`NUM_WARP-1:0]    update_rq_valid,
    // 输出取指信息
    input                           ready_icache,
    output [31:0]                   npc_o,
    output [`NUM_WARP-1:0]          warp_id_mask_o,
    output                          tlast_o,
    output                          valid_o
);
    typedef enum logic[1:0] { 
        IDLE,
        WAITING_NPC,
        SEND_RQ,
        UPDATE
    } State_t;
    
    State_t State;
    logic Ready;
    logic [31:0] Npc [`NUM_WARP];

    logic [`NUM_WARP-1:0] RQs;
    logic [`NUM_WARP-1:0] UpdateRQs;

    logic [`NUM_WARP-1:0] WarpIDMaskSend;
    logic [31:0] NpcSend;
    logic TLastSend;
    logic TValidSend;

    logic [`NUM_WARP-1:0] FetchMask;

    assign FetchMask=execute_mask_i & fetch_mask_i;
    assign npc_o=NpcSend;
    assign warp_id_mask_o=WarpIDMaskSend;
    assign tlast_o=TLastSend;
    assign valid_o=TValidSend;

    assign ready_o=Ready;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            State<=IDLE;
            Ready<=1;
            RQs<=0;
            Npc<='{default:0};
            UpdateRQs<=0;

            WarpIDMaskSend<=0;
            NpcSend<=0;
            TLastSend<=0;
            TValidSend<=0;

            update_rq_valid<=0;
        end
        else begin
            case (State)
                IDLE:begin
                    RQs<=0;
                    if(fetch_valid_i & (|FetchMask)) begin
                        logic NeedToWaitNpc;
                        UpdateRQs<=0;
                        Ready<=0;
                        NeedToWaitNpc=|(FetchMask & ~npc_valid_mask_i);
                        RQs<=FetchMask;
                        if(NeedToWaitNpc) begin
                            State<=WAITING_NPC;
                        end
                        else begin
                            State<=SEND_RQ;
                            UpdateRQs<=FetchMask;
                            Npc<=npc_i;
                        end
                    end
                    else begin
                        Ready<=1;
                        State<=IDLE;
                    end
                    WarpIDMaskSend<=0;
                    NpcSend<=0;
                    TLastSend<=0;
                    TValidSend<=0;
                end
                WAITING_NPC:begin
                    logic NeedToWaitNpc;
                    Ready<=0;
                    NeedToWaitNpc=|(RQs & ~npc_valid_mask_i);
                    if(NeedToWaitNpc) begin
                        State<=WAITING_NPC;
                    end
                    else begin
                        State<=SEND_RQ;
                        UpdateRQs<=RQs;
                        Npc<=npc_i;
                    end
                    WarpIDMaskSend<=0;
                    NpcSend<=0;
                    TLastSend<=0;
                    TValidSend<=0;
                end
                SEND_RQ:begin
                    logic [`NUM_WARP-1:0] WarpIDThisCycle,RQsNextCycle;
                    Ready<=0;
                    if(ready_icache) begin
                        WarpIDThisCycle=RQs & (~RQs+1);
                        RQsNextCycle=~WarpIDThisCycle & RQs;
                        RQs<=RQsNextCycle;

                        for(int i=0;i<`NUM_WARP;i++) begin
                            if(WarpIDThisCycle[i]) NpcSend<=Npc[i];
                        end
                        WarpIDMaskSend<=WarpIDThisCycle;
                        TValidSend<=1;
                        if(~|RQsNextCycle) begin
                            State<=UPDATE;
                            TLastSend<=1;
                        end 
                        else begin 
                            State<=SEND_RQ;
                            TLastSend<=0;
                        end
                    end
                    else begin
                        RQs<=RQs;
                        WarpIDMaskSend<=0;
                        NpcSend<=0;
                        TLastSend<=0;
                        TValidSend<=0;
                        
                        State<=SEND_RQ;
                    end
                end
                UPDATE:begin
                    logic UpdateRQsNextCycle;
                    UpdateRQsNextCycle=UpdateRQs & ~branch_ready_i;
                    UpdateRQs<=UpdateRQsNextCycle;

                    update_rq_valid<=branch_ready_i & UpdateRQs;
                    if(~|UpdateRQsNextCycle) begin
                        State<=IDLE;
                    end
                    else begin
                        State<=UPDATE;
                    end

                    WarpIDMaskSend<=0;
                    NpcSend<=0;
                    TLastSend<=0;
                    TValidSend<=0;
                    Ready<=0;
                end
                default:begin
                    State<=IDLE;
                    Ready<=1;
                    RQs<=0;
                    Npc<='{default:0};

                    WarpIDMaskSend<=0;
                    NpcSend<=0;
                    TLastSend<=0;
                    TValidSend<=0;
                end
            endcase
        end
    end
endmodule