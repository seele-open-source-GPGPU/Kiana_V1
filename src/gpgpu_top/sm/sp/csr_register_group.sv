`include "sp_defines.svh"
module csr_register_group(
    input clk,
    input rst_n,

    input [15:0]    w_addr,
    input [31:0]    w_data,
    input           w_vld,

    input [`NUM_SP_INTERRUPT-1:0]   ir_mask,
    input [`NUM_SP_INTERRUPT-1:0]   ir_clear,
    input [`NUM_SP_INTERRUPT-1:0]   ir_force,
    input [`NUM_SP_INTERRUPT-1:0]   irq_inner,

    input                           ir_mask_vld,
    input                           ir_clear_vld,

    input [`NUM_WARP-1:0]           finished_i,
    input                           finished_vld,

    input [`NUM_WARP-1:0]           pending_i,
    input                           pending_vld,
    input [`NUM_WARP-1:0]           pending_clear_i,
    input                           pending_clear_vld,

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

    output [`NUM_WARP-1:0]          finished_o,
    output [`NUM_WARP-1:0]          pending_o,
    output                          ir,
    output [`NUM_SP_INTERRUPT-1:0]  ir_events
);
    logic [31:0]                    WorkGroupEachSlots [`NUM_WARP];
    logic [$clog2(`NUM_WARP)-1:0]   WarpIdEachSlots [`NUM_WARP];
    logic [31:0]                    InitPCEachSlots [`NUM_WARP];
    logic [`NUM_WARP-1:0]           ExecuteMask;

    logic [`NUM_WARP-1:0]           Finished;
    logic [`NUM_WARP-1:0]           Pending;

    logic [`NUM_SP_INTERRUPT-1:0]   IrPending;
    logic [`NUM_SP_INTERRUPT-1:0]   IrMask;
    logic                           Ir;

    logic [`NUM_SP_INTERRUPT-1:0]   Ir_CSR_INVALID_ADDR;

    logic [`NUM_WARP-1:0]           FenceW;
    logic [`NUM_WARP-1:0]           FenceR;

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

    assign finished_o=Finished;
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

            if(ir_clear_vld) clear_mask=ir_clear;
            else clear_mask=0;

            if(ir_mask_vld) mask=ir_mask;
            else mask=IrMask;
            IrMask<=mask;

            pending=((IrPending | (irq_inner | Ir_CSR_INVALID_ADDR)) & ~clear_mask) | ir_force;
            IrPending<=pending;
            Ir<=|(pending & ~mask);
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            WorkGroupEachSlots<='{default:0};
            WarpIdEachSlots<='{default:0};
            InitPCEachSlots<='{default:32'h114514};
            ExecuteMask<=0;
            Ir_CSR_INVALID_ADDR<=0;
            Finished<=0;
        end
        else begin
            if(finished_vld) Finished<=finished_i;
            Ir_CSR_INVALID_ADDR<=0;
            if(w_vld) begin
                if(|w_addr[15:7]) Ir_CSR_INVALID_ADDR<=`INTERRUPT_CSR_INVALID_ADDR;
                case (w_addr[6:5])
                    2'b00:begin
                        if(w_addr[4:0]>=`NUM_WARP) Ir_CSR_INVALID_ADDR<=`INTERRUPT_CSR_INVALID_ADDR;
                        else WorkGroupEachSlots[w_addr[4:0]]<=w_data;
                    end
                    2'b01:begin
                        if(w_addr[4:0]>=`NUM_WARP) Ir_CSR_INVALID_ADDR<=`INTERRUPT_CSR_INVALID_ADDR;
                        else WarpIdEachSlots[w_addr[4:0]]<=w_data[$clog2(`NUM_WARP)-1:0];
                    end
                    2'b10:begin
                        if(w_addr[4:0]>=`NUM_WARP) Ir_CSR_INVALID_ADDR<=`INTERRUPT_CSR_INVALID_ADDR;
                        else begin 
                            InitPCEachSlots[w_addr[4:0]]<=w_data;
                            Finished[w_addr[4:0]]<=0;
                        end
                    end
                    2'b11:begin
                        if(|w_addr[4:0]) Ir_CSR_INVALID_ADDR<=`INTERRUPT_CSR_INVALID_ADDR;
                        else ExecuteMask<=w_data[`NUM_WARP-1:0];
                    end
                endcase
            end
        end
    end

endmodule