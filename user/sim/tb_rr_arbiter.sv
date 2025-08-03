module tb_rr_arbiter;

    parameter int N = 4;
    logic clk;
    logic rst_n;
    logic [N-1:0] req;
    logic [$clog2(N)-1:0] grant;

    // 实例化 DUT
    rr_arbiter #(.N(N)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .grant(grant)
    );

    // 产生时钟
    initial clk = 0;
    always #5 clk = ~clk;  // 10ns 时钟周期

    // 测试程序
    initial begin
        // 初始化
        rst_n = 1;
        req   = 0;
        #1;
        rst_n=0;
        #1
        rst_n = 1;
        // 测试向量组
        repeat(6) @(posedge clk); #9 req = 4'b0001; // Only req[0]
        repeat(6) @(posedge clk); #9 req = 4'b0101;
        repeat(6) @(posedge clk); #9 req = 4'b1110; // req[1~3]
        repeat(6) @(posedge clk); #9 req = 4'b1111;
        repeat(6) @(posedge clk); #9 req = 4'b1000; 
        repeat(6) @(posedge clk); #9 req = 4'b1011; 

        // 停止仿真
        repeat(5) @(posedge clk);
        $finish;
    end

    // 显示输出
    always_ff @(posedge clk) begin
        if (rst_n) begin
            $display("Time %t | req = %b | grant index = %0d", $time, req, grant);
        end
    end

endmodule
