`include "sp_defines.svh"

module branch_unit #(parameter SIMT_STACK_DEPTH=16)(
    input clk,
    input rst_n,
    // 从执行单元来的
    input SmitStackOperation_t op,
    input [31:0] addr_i,
    input [`NUM_THREAD-1:0] predicate_i,
    input valid_exe_i,
    input [$clog2(`NUM_WARP)-1:0] warp_id,
    // 从取指单元来的
    input [`NUM_WARP-1:0] valid_fetch_i,
    // 从控制面来的信号
    input [`NUM_WARP-1:0] initialize,
    input [31:0] init_pc [`NUM_WARP],
    // 输出
    output [31:0] npc_o [`NUM_WARP],
    output [`NUM_THREAD-1:0] predicate_o [`NUM_WARP],
    output [`NUM_WARP-1:0] ready_o,
    output [`NUM_WARP-1:0] valid_o,
    output logic irq_INTERRUPT_SIMT_STACK_OP_CONFLICT_o,
    output logic irq_INTERRUPT_SIMT_STACK_OVERFLOW_o,
    output logic irq_INTERRUPT_SIMT_STACK_UNDERFLOW_o
);
    logic [`NUM_WARP-1:0] warp_id_one_hot;
    logic [2:0] irq_all [`NUM_WARP];

    always @(*) begin
        warp_id_one_hot=1;
        if(warp_id<`NUM_WARP) begin
            warp_id_one_hot=warp_id_one_hot<<warp_id;
        end
        else warp_id_one_hot=0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            irq_INTERRUPT_SIMT_STACK_OP_CONFLICT_o<=0;
            irq_INTERRUPT_SIMT_STACK_OVERFLOW_o<=0;
            irq_INTERRUPT_SIMT_STACK_UNDERFLOW_o<=0;
        end
        else begin
            logic [2:0] irq_temp;
            irq_temp=0;
            for(int i=0;i<`NUM_WARP;i++) begin
                irq_temp=irq_temp | irq_all[i];
            end
            {irq_INTERRUPT_SIMT_STACK_OP_CONFLICT_o,irq_INTERRUPT_SIMT_STACK_OVERFLOW_o,irq_INTERRUPT_SIMT_STACK_UNDERFLOW_o}<=irq_temp;
        end
    end

    genvar i;
    generate
        for(i=0;i<`NUM_WARP;i++) begin
            simt_stack #(
                .SIMT_STACK_DEPTH(SIMT_STACK_DEPTH)
            ) u_simt_stack (
                .clk           (clk),
                .rst_n         (rst_n),

                // 执行侧（仅命中 warp_id 的那路为有效）
                .op            (op),
                .addr_i        (addr_i),
                .predicate_i   (predicate_i),
                .valid_exe_i   (warp_id_one_hot[i]),

                // 取指侧（逐 Warp）
                .valid_fetch_i (valid_fetch_i[i]),

                // 控制面（逐 Warp）
                .initialize    (initialize[i]),
                .init_pc       (init_pc[i]),

                // 输出（逐 Warp）
                .npc_o         (npc_o[i]),
                .predicate_o   (predicate_o[i]),
                .ready_o       (ready_o[i]),
                .valid_o       (valid_o[i]),
                .irq_o         (irq_all[i])
            );
        end
    endgenerate
endmodule
// simt stack栈底条目总是存在
// simt stack的深度是2的幂次
module simt_stack #(parameter SIMT_STACK_DEPTH=16)(
    input clk,
    input rst_n,

    // 从执行单元来的信号
    input SmitStackOperation_t op,
    input [31:0] addr_i,
    input [`NUM_THREAD-1:0] predicate_i,
    input valid_exe_i,
    // 从取指单元来的信号
    input valid_fetch_i,
    // 从控制面来的信号
    input initialize,
    input [31:0] init_pc,

    output logic [31:0] npc_o,
    output logic [`NUM_THREAD-1:0] predicate_o,
    output ready_o,
    output valid_o,
    output logic [2:0] irq_o
);
    typedef struct packed {
        logic [31:0] npc;
        logic [31:0] rpc;
        logic [`NUM_WARP-1:0] predicate; 
    } SimtStackItem;

    typedef enum logic[1:0] { 
        IDLE,
        RUNNING,
        CHECK_AND_POP,
        FINISH
    } SimtStackStates_t;



    localparam STACK_PTR_WIDTH=$clog2(SIMT_STACK_DEPTH);
    // simt stack数据结构
    // 栈指针多一位，如果全是1则表示空的，最高位1别的位不是全1就是上溢
    SimtStackItem Stack [SIMT_STACK_DEPTH];
    logic [STACK_PTR_WIDTH:0] StackPtr;
    // 中断
    logic [2:0] Irq;
    // 当前状态，当前要操作的地址和操作类型
    SimtStackStates_t State;
    SmitStackOperation_t Op;
    logic [31:0] Addr;
    logic Valid,Ready;
    logic [`NUM_THREAD-1:0] Predicate;
    // 独立的RPC寄存器，当下次分支时用这个
    logic [31:0] Rpc;

    assign ready_o=Ready;
    assign valid_o=Valid;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            predicate_o<=0;
            npc_o<=0;
            irq_o<=0;

            StackPtr<='1;
            State<=IDLE;
            Stack<='{default:0};
            Addr<=0;
            Op<=NOP;
            Valid<=1;
            Ready<=1;
            Rpc<=0;
            Predicate<=0;
        end
        else begin
            Irq=0;
            if(initialize) begin
                StackPtr<=0;
                State<=IDLE;
                Stack[0].rpc<='1;
                Stack[0].npc<=init_pc;
                Stack[0].predicate<='1;
                Addr<=0;
                Op<=NOP;
                Valid<=1;
                Ready<=1;
                Rpc<=0;
                Predicate<='1;
            end
            else begin
                case (State)
                    IDLE:begin
                        case ({valid_exe_i,valid_fetch_i})
                            2'b00:begin
                                State<=IDLE;
                                Addr<=0;
                                Op<=NOP;
                                Ready<=1;
                                Predicate<='1;
                            end
                            2'b01:begin
                                State<=RUNNING;
                                Addr<=0;
                                Op<=PC_ADD_4;
                                Valid<=0;
                                Ready<=0;
                                Predicate<='1;
                            end
                            2'b10:begin
                                State<=RUNNING;
                                Addr<=addr_i;
                                Op<=op;
                                Valid<=0;
                                Ready<=0;
                                Predicate<=predicate_i;
                            end
                            2'b11:begin
                                Irq=Irq | 3'b100;//INTERRUPT_SIMT_STACK_OP_CONFLICT;
                                State<=IDLE;
                                Addr<=0;
                                Op<=NOP;
                                Ready<=1;
                                Predicate<='1;
                            end
                        endcase
                    end
                    RUNNING:begin
                        Valid<=0;
                        Ready<=0;
                        case (Op)
                            SETRPC:begin
                                Rpc<=Addr;
                                State<=CHECK_AND_POP;
                            end
                            NOP:begin
                                State<=CHECK_AND_POP;
                            end
                            PC_ADD_4:begin
                                State<=CHECK_AND_POP;
                                Stack[StackPtr[STACK_PTR_WIDTH-1:0]].npc<=Stack[StackPtr[STACK_PTR_WIDTH-1:0]].npc+4;
                            end
                            PUSH:begin
                                logic [STACK_PTR_WIDTH:0] StackPtrNext;
                                StackPtrNext=StackPtr+1;
                                if(StackPtrNext[STACK_PTR_WIDTH]) begin
                                    State<=IDLE;
                                    Irq=Irq | 3'b010;//INTERRUPT_SIMT_STACK_OVERFLOW;
                                    Ready<=1;
                                end 
                                else begin
                                    State<=CHECK_AND_POP;
                                    Stack[StackPtrNext[STACK_PTR_WIDTH-1:0]].npc<=Addr;
                                    Stack[StackPtrNext[STACK_PTR_WIDTH-1:0]].rpc<=Rpc;
                                    Stack[StackPtrNext[STACK_PTR_WIDTH-1:0]].predicate<=Predicate;
                                    StackPtr<=StackPtrNext;
                                end
                            end
                            POP:begin
                                logic [STACK_PTR_WIDTH:0] StackPtrNext;
                                StackPtrNext=StackPtr-1;
                                if(~|StackPtr) begin
                                    Irq=Irq | 3'b001;//INTERRUPT_SIMT_STACK_UNDERFLOW;
                                    State<=IDLE;
                                    Ready<=1;
                                end
                                else begin
                                    State<=CHECK_AND_POP;
                                    StackPtr<=StackPtrNext;
                                end
                            end
                            FLUSH:begin
                                State<=FINISH;
                                StackPtr<=0;
                                Stack[0].rpc<='1;
                                Stack[0].npc<=init_pc;
                                Stack[0].predicate<='1;
                            end
                            JUMP:begin
                                State<=CHECK_AND_POP;
                                Stack[StackPtr[STACK_PTR_WIDTH-1:0]].npc<=Addr;
                            end
                            BRANCH:begin
                                logic [STACK_PTR_WIDTH:0] StackPtr2,StackPtr1;
                                StackPtr1=StackPtr+1;
                                StackPtr2=StackPtr+2;
                                if(StackPtr2[STACK_PTR_WIDTH]) begin
                                    Irq=Irq | `INTERRUPT_SIMT_STACK_OVERFLOW;
                                    State<=IDLE;
                                    Ready<=1;
                                end
                                else begin
                                    State<=CHECK_AND_POP;
                                    StackPtr<=StackPtr2;

                                    Stack[StackPtr[STACK_PTR_WIDTH-1:0]].npc<=Rpc;

                                    Stack[StackPtr1[STACK_PTR_WIDTH-1:0]].npc<=Stack[StackPtr[STACK_PTR_WIDTH-1:0]].npc+4;
                                    Stack[StackPtr1[STACK_PTR_WIDTH-1:0]].rpc<=Rpc;
                                    Stack[StackPtr1[STACK_PTR_WIDTH-1:0]].predicate<=(~Predicate) & Stack[StackPtr[STACK_PTR_WIDTH-1:0]].predicate;

                                    Stack[StackPtr2[STACK_PTR_WIDTH-1:0]].npc<=Addr;
                                    Stack[StackPtr2[STACK_PTR_WIDTH-1:0]].rpc<=Rpc;
                                    Stack[StackPtr2[STACK_PTR_WIDTH-1:0]].predicate<=Predicate & Stack[StackPtr[STACK_PTR_WIDTH-1:0]].predicate;
                                end
                            end
                        endcase
                    end
                    CHECK_AND_POP:begin
                        logic IsRpcNpcEqual,IsNegligible;
                        IsRpcNpcEqual=Stack[StackPtr[STACK_PTR_WIDTH-1:0]].npc==Stack[StackPtr[STACK_PTR_WIDTH-1:0]].rpc;
                        IsNegligible=~|Stack[StackPtr[STACK_PTR_WIDTH-1:0]].predicate;
                        Valid<=0;
                        Ready<=0;
                        
                        if(IsRpcNpcEqual | IsNegligible) begin
                            if(|StackPtr) begin
                                StackPtr<=StackPtr-1;
                                State<=CHECK_AND_POP;
                            end
                            else State<=FINISH;
                        end
                        else State<=FINISH;
                    end
                    FINISH:begin
                        Valid<=1;
                        Ready<=1;
                        State<=IDLE;
                        npc_o<=Stack[StackPtr[STACK_PTR_WIDTH-1:0]].npc;
                        predicate_o<=Stack[StackPtr[STACK_PTR_WIDTH-1:0]].predicate;
                    end
                endcase
            end
            irq_o<=Irq;
        end
    end
endmodule