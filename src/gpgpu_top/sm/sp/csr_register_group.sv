`include "sp_defines.svh"
module csr_register_group#(parameter CSR_META_DATA_INIT_ADDR=11'b0000_0000_000)(
    input clk,
    input rst_n,
    // slots的元数据
    input [15:0]    w_addr,
    input [31:0]    w_data,
    input           w_vld,
    output [`NUM_WARP-1:0]          initialize_simt_stack_o,
    output [31:0]                   work_group_each_slots_o [`NUM_WARP],
    output [$clog2(`NUM_WARP)-1:0]  warp_id_each_slots_o [`NUM_WARP],
    output [31:0]                   init_pc_each_slots_o [`NUM_WARP],
    output [`NUM_WARP-1:0]          execute_mask_o,
    output [31:0]                   num_threads_per_wg_o,
    output [31:0]                   num_workgroup_o,
    // 中断相关
    input [`NUM_SP_INTERRUPT-1:0]   ir_mask,
    input [`NUM_SP_INTERRUPT-1:0]   ir_clear,
    input [`NUM_SP_INTERRUPT-1:0]   ir_force,
    input [`NUM_SP_INTERRUPT-1:0]   irq_inner,

    input                           ir_mask_vld,
    input                           ir_clear_vld,
    output                          ir,
    output [`NUM_SP_INTERRUPT-1:0]  ir_events,
    // warp完成相关
    input [`NUM_WARP-1:0]           finished_i,
    input                           finished_vld,
    output [`NUM_WARP-1:0]          finished_o,
    // 线程同步相关
    input [`NUM_WARP-1:0]           pending_i,  
    input                           pending_vld,
    input [`NUM_WARP-1:0]           pending_clear_i,
    input                           pending_clear_vld,
    output [`NUM_WARP-1:0]          pending_o,
    // 内存屏障相关
    input [`NUM_WARP-1:0]           fence_w_i,
    input                           fence_w_vld,
    input [`NUM_WARP-1:0]           fence_w_clear_i,
    input                           fence_w_clear_vld,

    input [`NUM_WARP-1:0]           fence_r_i,
    input                           fence_r_vld,
    input [`NUM_WARP-1:0]           fence_r_clear_i,
    input                           fence_r_clear_vld,

    output [`NUM_WARP-1:0]          fence_r_o,
    output [`NUM_WARP-1:0]          fence_w_o,
    // 通用CSR相关
    input [$clog2(`NUM_COMMON_CSR)-1:0] common_csr_id,
    input                               common_csr_vld,
    input [31:0]                        common_csr_data_i,
    output logic [31:0]                 common_csr_data_o,
    input [1:0]                         common_csr_op, // 0:写，1:按位或，2:写1清零

    input [$clog2(`NUM_COMMON_CSR)-1:0] common_csr_id_inner,
    input                               common_csr_vld_inner,
    input [31:0]                        common_csr_data_i_inner,
    output logic [31:0]                 common_csr_data_o_inner,
    input [1:0]                         common_csr_op_inner
);
    // 信号定义：元数据和warp完成
    logic [31:0]                    WorkGroupEachSlots [`NUM_WARP];
    logic [$clog2(`NUM_WARP)-1:0]   WarpIdEachSlots [`NUM_WARP];
    logic [31:0]                    InitPCEachSlots [`NUM_WARP];
    logic [`NUM_WARP-1:0]           ExecuteMask;
    logic [31:0]                    NumWorkgroup;
    logic [31:0]                    NumThreadInPerWorkgroup;
    logic [`NUM_WARP-1:0]           InitializeSimtStack;

    logic [`NUM_WARP-1:0]           Finished;
    // 信号定义：线程同步挂起
    logic [`NUM_WARP-1:0]           Pending;
    // 信号定义：中断
    logic [`NUM_SP_INTERRUPT-1:0]   IrPending;
    logic [`NUM_SP_INTERRUPT-1:0]   IrMask;
    logic                           Ir;

    logic                           Ir_CSR_INVALID_ADDR;
    logic                           Ir_CSR_INVALID_COMMON_CSR_OP;
    // 信号定义：内存栅栏
    logic [`NUM_WARP-1:0]           FenceW;
    logic [`NUM_WARP-1:0]           FenceR;
    // 信号定义：通用CSR
    logic [31:0]                    CommonCSRReg[`NUM_COMMON_CSR]; 



    // 内存栅栏的实现
    assign fence_r_o=FenceR;
    assign fence_w_o=FenceW;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            FenceR<=0;
            FenceW<=0;
        end
        else begin
            if(fence_w_clear_vld) begin
                if(fence_w_vld) FenceW<=(FenceW | fence_w_i) & ~fence_w_clear_i;
                else FenceW<=FenceW & ~fence_w_clear_i;
            end
            else begin
                if(fence_w_vld) FenceW<=FenceW | fence_w_i;
            end

            if(fence_r_clear_vld) begin
                if(fence_r_vld) FenceR<=(FenceR | fence_r_i) & ~fence_r_clear_i;
                else FenceR<=FenceR & ~fence_r_clear_i;
            end
            else begin
                if(fence_r_vld) FenceR<=FenceR | fence_r_i;
            end
        end
    end
    // 线程同步挂起的实现
    assign pending_o=Pending;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            Pending<=0;
        end
        else begin
            if(pending_clear_vld) begin
                if(pending_vld) Pending<=(Pending | pending_i) & ~pending_clear_i;
                else Pending<=Pending & ~pending_clear_i;
            end
            else begin
                if(pending_vld) Pending<=Pending | pending_i;
            end
        end
    end
    // 中断实现
    assign ir=Ir;
    assign ir_events=IrPending;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            IrPending<=0;
            IrMask<=0;
            Ir<=0;
        end
        else begin
            logic [`NUM_SP_INTERRUPT-1:0] clear_mask;
            logic [`NUM_SP_INTERRUPT-1:0] mask;
            logic [`NUM_SP_INTERRUPT-1:0] pending;
            logic [`NUM_SP_INTERRUPT-1:0] irq_inside_csr;
            irq_inside_csr=0;
            irq_inside_csr[0]=Ir_CSR_INVALID_ADDR;
            irq_inside_csr[1]=Ir_CSR_INVALID_COMMON_CSR_OP;

            if(ir_clear_vld) clear_mask=ir_clear;
            else clear_mask=0;

            if(ir_mask_vld) mask=ir_mask;
            else mask=IrMask;
            IrMask<=mask;

            pending=((IrPending | (irq_inner | irq_inside_csr)) & ~clear_mask) | ir_force;
            IrPending<=pending;
            Ir<=|(pending & ~mask);
        end
    end
    // 元数据和warp结束的实现
    assign work_group_each_slots_o=WorkGroupEachSlots;
    assign warp_id_each_slots_o=WarpIdEachSlots;
    assign init_pc_each_slots_o=InitPCEachSlots;
    assign execute_mask_o=ExecuteMask;
    assign num_threads_per_wg_o=NumThreadInPerWorkgroup;
    assign num_workgroup_o=NumWorkgroup;
    assign initialize_simt_stack_o=InitializeSimtStack;

    assign finished_o=Finished;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            WorkGroupEachSlots<='{default:0};
            WarpIdEachSlots<='{default:0};
            InitPCEachSlots<='{default:0};
            ExecuteMask<=0;
            Ir_CSR_INVALID_ADDR<=0;
            Finished<=0;
            NumWorkgroup<=0;
            NumThreadInPerWorkgroup<=0;
            InitializeSimtStack<=0;
        end
        else begin
            InitializeSimtStack<=0;
            if(finished_vld) Finished<=finished_i;
            Ir_CSR_INVALID_ADDR<=0;
            if(w_vld) begin
                case (w_addr[15:5]-CSR_META_DATA_INIT_ADDR)
                    11'b0000_0000_000:begin
                        if(w_addr[4:0]>=`NUM_WARP) Ir_CSR_INVALID_ADDR<=1;//`INTERRUPT_CSR_METADATA_INVALID_ADDR;
                        else WorkGroupEachSlots[w_addr[4:0]]<=w_data;
                    end
                    11'b0000_0000_001:begin
                        if(w_addr[4:0]>=`NUM_WARP) Ir_CSR_INVALID_ADDR<=1;//`INTERRUPT_CSR_METADATA_INVALID_ADDR;
                        else WarpIdEachSlots[w_addr[4:0]]<=w_data[$clog2(`NUM_WARP)-1:0];
                    end
                    11'b0000_0000_010:begin
                        if(w_addr[4:0]>=`NUM_WARP) Ir_CSR_INVALID_ADDR<=1;//`INTERRUPT_CSR_METADATA_INVALID_ADDR;
                        else begin 
                            InitPCEachSlots[w_addr[4:0]]<=w_data;
                            Finished[w_addr[4:0]]<=0;
                            InitializeSimtStack[w_addr[4:0]]<=1;
                        end
                    end
                    11'b0000_0000_011:begin
                        if(|w_addr[4:0]) Ir_CSR_INVALID_ADDR<=1;//`INTERRUPT_CSR_METADATA_INVALID_ADDR;
                        else ExecuteMask<=w_data[`NUM_WARP-1:0];
                    end
                    11'b0000_0000_100:begin
                        NumThreadInPerWorkgroup<=w_data;
                    end
                    11'b0000_0000_101:begin
                        NumWorkgroup<=w_data;
                    end
                    default:begin
                        Ir_CSR_INVALID_ADDR<=1;//`INTERRUPT_CSR_METADATA_INVALID_ADDR;
                    end
                endcase
            end
        end
    end
    // 通用csr的实现
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            CommonCSRReg<='{default:0};
            Ir_CSR_INVALID_COMMON_CSR_OP<=0;
        end
        else begin
            logic [31:0] com_csr_next,com_csr_next_inner;
            logic [31:0] com_csr_old,com_csr_old_inner;
            Ir_CSR_INVALID_COMMON_CSR_OP<=0;
            com_csr_old=CommonCSRReg[common_csr_id];
            com_csr_old_inner=CommonCSRReg[common_csr_id_inner];

            if(common_csr_vld) begin
                common_csr_data_o<=com_csr_old;

                if(common_csr_op==0) begin
                    com_csr_next=common_csr_data_i;
                end
                else if(common_csr_op==1) begin
                    com_csr_next=com_csr_old | common_csr_data_i;
                end
                else if(common_csr_op==2) begin
                    com_csr_next=com_csr_old & ~common_csr_data_i;
                end
                else begin
                    Ir_CSR_INVALID_COMMON_CSR_OP<=1;//`INTERRUPT_CSR_INVALID_COMMON_CSR_OP;
                end
            end
            else com_csr_next=com_csr_old;

            if(common_csr_vld_inner) begin
                common_csr_data_o_inner<=com_csr_old_inner;

                if(common_csr_op_inner==0) begin
                    com_csr_next_inner=common_csr_data_i_inner;
                end
                else if(common_csr_op_inner==1) begin
                    com_csr_next_inner=com_csr_old_inner | common_csr_data_i_inner;
                end
                else if(common_csr_op_inner==2) begin
                    com_csr_next_inner=com_csr_old_inner & ~common_csr_data_i_inner;
                end
                else begin
                    Ir_CSR_INVALID_COMMON_CSR_OP<=1;//`INTERRUPT_CSR_INVALID_COMMON_CSR_OP;
                end
            end   
            else com_csr_next_inner=com_csr_old_inner;  

            if(common_csr_vld && common_csr_vld_inner && (common_csr_id==common_csr_id_inner)) begin
                if(common_csr_id[$clog2(`NUM_COMMON_CSR)-1]) begin
                    CommonCSRReg[common_csr_id]<=com_csr_next;
                end
                else begin
                    CommonCSRReg[common_csr_id_inner]<=com_csr_next_inner;
                end
            end
            else begin
                CommonCSRReg[common_csr_id]<=com_csr_next;
                CommonCSRReg[common_csr_id_inner]<=com_csr_next_inner;
            end
        end
    end
endmodule