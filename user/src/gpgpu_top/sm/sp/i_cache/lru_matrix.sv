`timescale 1ns/1ns

module lru_matrix #(
  parameter int NUM_WAY   = 4, // number way of one set    
  parameter int WAY_DEPTH = 2
)(
  input  logic                  clk,
  input  logic                  rst_n,

  input  logic                  update_entry_i,   // 输入更新条件
  input  logic [WAY_DEPTH-1:0]  update_index_i,   // 输入更新的 wayId
  output logic [WAY_DEPTH-1:0]  lru_index_o       // 输出替换用的 wayId
);

  // LRU 矩阵（按行打平）
  logic [NUM_WAY*NUM_WAY-1:0] matrix_nxt;
  logic [NUM_WAY-1:0]         lru_index_nxt;
  logic [NUM_WAY-1:0]         lru_index_nxt_oh;
  logic [WAY_DEPTH-1:0]       lru_index_nxt_bin;

  genvar j, k;
  generate
    for (j = 0; j < NUM_WAY; j = j + 1) begin : row_loop

      // 如果第 j 行全是 0，说明 way j 比所有其它 way 都旧
      always_comb begin
        if (matrix_nxt[NUM_WAY*(j+1)-1 -: NUM_WAY] == {NUM_WAY{1'b0}}) begin
          lru_index_nxt[j] = 1'b1;
        end
        else begin
          lru_index_nxt[j] = 1'b0;
        end
      end

      // 有新的访存请求时更新 LRU 矩阵
      for (k = 0; k < NUM_WAY; k = k + 1) begin : column_loop
        always_ff @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            matrix_nxt[NUM_WAY*j+k] <= 1'b0;
          end
          else if (update_entry_i && k == update_index_i) begin
            matrix_nxt[NUM_WAY*j+k] <= 1'b0;
          end
          else if (update_entry_i && j == update_index_i) begin
            matrix_nxt[NUM_WAY*j+k] <= 1'b1;
          end
        end
      end

    end
  endgenerate

  assign lru_index_o = lru_index_nxt_bin;

  // 有多个行为 0 时，用固定优先级仲裁器判断
  fixed_pri_arb #(
    .ARB_WIDTH(NUM_WAY)
  ) U_fixed_pri_arb (
    .req   (lru_index_nxt    ),
    .grant (lru_index_nxt_oh )
  );

  one2bin #(
    .ONE_WIDTH(NUM_WAY),
    .BIN_WIDTH(WAY_DEPTH)
  ) U_one2bin (
    .oh  (lru_index_nxt_oh ),
    .bin (lru_index_nxt_bin)
  );

endmodule
