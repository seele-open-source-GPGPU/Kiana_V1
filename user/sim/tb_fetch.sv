`timescale 1ns/1ns

module tb_fetch;

    logic clk, rst_n;
    logic initialize;
    logic [31:0] next_pc[32];
    logic [31:0] warp_id[32];
    logic [31:0] warp_mask;
    logic [31:0] selected_warp_id;
    logic [31:0] selected_pc;
    logic s_tvalid, s_tready, m_tvalid;

    // DUT 实例
    fetch uut (
        .clk(clk),
        .rst_n(rst_n),
        .initialize(initialize),
        .next_pc(next_pc),
        .warp_id(warp_id),
        .warp_mask(warp_mask),
        .selected_warp_id(selected_warp_id),
        .selected_pc(selected_pc),
        .s_tvalid(s_tvalid),
        .s_tready(s_tready),
        .m_tvalid(m_tvalid)
    );

    // 时钟生成
    initial clk = 0;
    always #5 clk = ~clk;
    clocking cb @(posedge clk);
        default input #1 output #1;
        output initialize,next_pc,warp_id,warp_mask,s_tvalid;
        input selected_warp_id,selected_pc,s_tready,m_tvalid;
    endclocking

    // 初始化 warp 数据
    task init_warp_data();
        
    endtask

    // 波形输出（可选）
    initial begin
        $dumpfile("../fetch_tb.vcd");
        $dumpvars(0);
        
        rst_n=1;
        initialize=0;
        next_pc='{default:0};
        warp_id='{default:0};
        warp_mask=0;
        s_tvalid=0;
        #1 rst_n=0;
        #1 rst_n=1;
        @cb;
        cb.initialize<=1;
        for (int i = 0; i < 32; i++) begin
            cb.next_pc[i] <= 32'h1000 + i * 4;
            cb.warp_id[i] <= i;
        end
        @cb;
        cb.initialize<=0;
        while(~cb.s_tready) @cb;
        cb.s_tvalid<=1;
        for(int j=0;j<32;j++) begin
            cb.next_pc[j]<=next_pc[j]+4;
        end
        cb.warp_mask<=$urandom;

        repeat(50) @cb;
        $dumpflush;
        #1 $finish;
    end

endmodule
