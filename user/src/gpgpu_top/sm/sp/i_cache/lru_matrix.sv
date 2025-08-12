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
/*=============================================================================
含义：
  matrix[j][k] = 1  表示  way j  比  way k  更新（j 更“新”）
  matrix[j][k] = 0  表示  way j  比  way k  更旧
  （对角线 j==k 无意义，可忽略）

存储方式（按行打平）：
  matrix_flat[ NUM_WAY*j + k ]  ↔  matrix[j][k]

矩阵布局（j 为行 / k 为列）：
            k=0   k=1   k=2   k=3
  j=0     [  ? ,   ? ,   ? ,   ? ]
  j=1     [  ? ,   ? ,   ? ,   ? ]
  j=2     [  ? ,   ? ,   ? ,   ? ]
  j=3     [  ? ,   ? ,   ? ,   ? ]

更新规则（访问了某个 way = X）：
  1) 将第 X 行全部置 1    → X 比所有其它 way 都新
  2) 将第 X 列全部置 0    → 其它所有 way 都比 X 旧
  （实现上：遍历所有 j,k：
     if (k==X) matrix[j][k]=0;
     if (j==X) matrix[j][k]=1;            // 两者同时满足时按代码顺序生效
   ）

选择 LRU（最旧的 way）：
  “某一行 全为 0”  ⇒  对应的 j 即为当前 LRU 候选；
  若有多个候选（多行全 0），用固定优先级仲裁器选一个。

示例：访问序列为 2 → 0
 初始（全 0，任意行均为 LRU 候选）
            0    1    2    3          （行全 0 → 该行是 LRU 候选）
  row 0    [0,   0,   0,   0]   ← LRU
  row 1    [0,   0,   0,   0]   ← LRU
  row 2    [0,   0,   0,   0]   ← LRU
  row 3    [0,   0,   0,   0]   ← LRU

 访问 way=2 后（第2行全1，第2列全0）
            0    1    2    3
  row 0    [0,   0,   0,   0]   ← LRU 候选
  row 1    [0,   0,   0,   0]   ← LRU 候选
  row 2    [1,   1,   -,   1]   （自比位“-”无意义，可忽略）
  row 3    [0,   0,   0,   0]   ← LRU 候选

 再访问 way=0（第0行全1，第0列全0）
            0    1    2    3
  row 0    [-,   1,   1,   1]   （way0 最新）
  row 1    [0,   0,   0,   0]   ← LRU 候选
  row 2    [1,   1,   -,   1]
  row 3    [0,   0,   0,   0]   ← LRU 候选

此时 LRU = 在“行全 0”的 {row1, row3} 中按固定优先级选出者。
=============================================================================*/