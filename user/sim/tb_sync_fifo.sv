module tb_sync_fifo;

    // 参数化
    parameter WIDTH = 9;
    parameter DEPTH = 1;

    // DUT IO
    logic clk;
    logic rst;
    logic [WIDTH-1:0] w_data;
    logic w_en, r_en;
    logic [WIDTH-1:0] r_data;
    logic full, empty;

    // 实例化 DUT
    sync_fifo #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .w_data(w_data),
        .w_en(w_en),
        .r_en(r_en),
        .r_data(r_data),
        .full(full),
        .empty(empty),
        .r_data_valid(r_data_valid)
    );

    // 时钟生成
    initial clk = 0;
    always #5 clk = ~clk; // 10ns clock period

    clocking cb @(posedge clk);
        default input #1 output #1;
        output w_data,r_en,w_en;
        input r_data,full,empty,r_data_valid;
    endclocking
    
    function bit rnd_bit();
        return $urandom_range(0,1);
    endfunction

    typedef logic[WIDTH-1:0] Word;
    function automatic bit compare_word_queues(Word words_in[$], Word words_out[$]);
        if (words_in.size() != words_out.size())
            return 0;
        for (int i = 0; i < words_in.size(); i++) begin
            if (words_in[i] !== words_out[i])
                return 0;
        end
        return 1;
    endfunction

    task write(Word item);
        while(cb.full) @(cb);
        cb.w_en <= 1;
        cb.w_data <= item;
        @(cb);
        cb.w_en <= 0;
    endtask

    task read();
        while(cb.empty) @(cb);
        cb.r_en <= 1;
        @(cb);
        cb.r_en <= 0;
    endtask
    // 测试过程
    initial begin
        Word words_in[$];
        Word words_out[$];

        // 初始化
        w_en = 0;
        r_en = 0;
        w_data = 0;
        rst = 0;
        #1;
        rst = 1;
        #1
        rst = 0;
        @(cb);

        for (int i = 0; i < 100; i++) begin
            words_in.push_back($random);
        end
        
        fork
            begin
                forever begin
                    if(cb.r_data_valid) words_out.push_back(cb.r_data);
                    @(cb);
                end
            end
            begin
                foreach (words_in[i]) begin
                    write(words_in[i]);
                end
            end
            begin
                forever begin
                    if(rnd_bit()) read();
                    else @(cb);
                end
            end
        join_none
        

        repeat(1000) @(cb);
        $display("words_in: %p\n",words_in);
        $display("words_out: %p\n",words_out);
        $display("%s\n",compare_word_queues(words_in,words_out)?"Success":"Failed");
        #1 $finish;
    end

endmodule