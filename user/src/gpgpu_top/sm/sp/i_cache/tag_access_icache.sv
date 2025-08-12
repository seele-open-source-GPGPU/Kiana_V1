`timescale 1ns / 1ns

module tag_access_icache #(
    parameter int TAG_WIDTH = 7,
    parameter int NUM_SET   = 32,
    parameter int NUM_WAY   = 2,
    parameter int SET_DEPTH = 5,
    parameter int WAY_DEPTH = 1
) (
    input logic clk,
    input logic rst_n,

    input logic                 invalid_i,
    input logic                 r_req_valid_i,
    input logic [SET_DEPTH-1:0] r_req_setid_i,

    input logic [TAG_WIDTH-1:0] tagFromCore_st1_i,  //tag from warp_scheduler 

    input logic                         w_req_valid_i,
    input logic [        SET_DEPTH-1:0] w_req_setid_i,
    input logic [NUM_WAY*TAG_WIDTH-1:0] w_req_data_i,

    output logic [NUM_SET*WAY_DEPTH-1:0] wayid_replacement_o,
    output logic [        WAY_DEPTH-1:0] wayid_hit_st1_o,      //hit way
    output logic                         hit_st1_o
);

  logic [NUM_WAY*TAG_WIDTH-1:0] tagBodyAccess_r_resp_data_o;
  logic [  NUM_SET*NUM_WAY-1:0] way_valid;
  logic                         r_req_valid_i_r;
  logic [        SET_DEPTH-1:0] r_req_setid_i_r;
  logic [          NUM_WAY-1:0] wayid_replacement_one;
  logic [          NUM_SET-1:0] lru_valid;
  logic [NUM_SET*WAY_DEPTH-1:0] lru_update_index;
  //打两拍
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r_req_valid_i_r <= 'h0;
      r_req_setid_i_r <= 'h0;
    end else begin
      r_req_valid_i_r <= r_req_valid_i;
      r_req_setid_i_r <= r_req_setid_i;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      way_valid <= 'h0;
    end  //有写请求，把要写的那路置1
    else if (w_req_valid_i) begin
      //起始set下标加要被替换的way编号=全局bit下标
      way_valid[(w_req_setid_i*NUM_WAY)+wayid_replacement_o[(WAY_DEPTH*(w_req_setid_i+1)-1)-:WAY_DEPTH]] <= 'h1;
    end else if (invalid_i) begin
      way_valid <= 'h0;
    end else begin
      way_valid <= way_valid;
    end
  end

  //逐个set 生成LRU 的“是否更新”信号和“更新哪一条way”信号
  genvar i;
  generate
    for (i = 0; i < NUM_SET; i = i + 1) begin : B1
      //命中该set或者写入该set，满足任一条件就置1,否则0
      assign lru_valid[i]                                       = ((hit_st1_o && (i == r_req_setid_i_r)) || (w_req_valid_i && (i == w_req_setid_i))) ? 1'h1 : 1'h0;
      //若命中该 set，用命中的路的index。若写入该set，用该set的将被替换的路的index。否则给0
      assign lru_update_index[((WAY_DEPTH*(i+1))-1)-:WAY_DEPTH] = (hit_st1_o && (i == r_req_setid_i_r)) ? wayid_hit_st1_o : (((w_req_valid_i) && (i == w_req_setid_i)) ? wayid_replacement_o[(WAY_DEPTH*(i+1)-1)-:WAY_DEPTH] : 'h0);

      //缓存置换算法（lru）矩阵
      lru_matrix #(
          .NUM_WAY  (NUM_WAY),
          .WAY_DEPTH(WAY_DEPTH)
      ) replacement (
          .clk           (clk),
          .rst_n         (rst_n),
          .update_entry_i(lru_valid[i]),
          .update_index_i(lru_update_index[(WAY_DEPTH*(i+1)-1)-:WAY_DEPTH]),
          .lru_index_o   (wayid_replacement_o[(WAY_DEPTH*(i+1)-1)-:WAY_DEPTH])
      );
    end
  endgenerate

  sram_template #(
      .GEN_WIDTH(TAG_WIDTH),
      .NUM_SET  (NUM_SET),
      .NUM_WAY  (NUM_WAY),
      .SET_DEPTH(SET_DEPTH),
      .WAY_DEPTH(WAY_DEPTH)
  ) tagBodyAccess (
      .clk            (clk),
      .rst_n          (rst_n),
      .r_req_valid_i  (r_req_valid_i),
      .r_req_setid_i  (r_req_setid_i),
      .r_resp_data_o  (tagBodyAccess_r_resp_data_o),
      .w_req_valid_i  (w_req_valid_i),
      .w_req_setid_i  (w_req_setid_i),
      .w_req_waymask_i(wayid_replacement_one),
      .w_req_data_i   (w_req_data_i)
  );

  tag_checker_icache #(
      .TAG_WIDTH(TAG_WIDTH),
      .NUM_WAY  (NUM_WAY),
      .WAY_DEPTH(WAY_DEPTH)
  ) iTagChecker (
      .r_req_valid_i  (r_req_valid_i_r),
      .tag_of_set_i   (tagBodyAccess_r_resp_data_o),
      .tag_from_pipe_i(tagFromCore_st1_i),
      .way_valid_i    (way_valid[(NUM_WAY*(r_req_setid_i_r+1)-1)-:NUM_WAY]),
      .wayid_o        (wayid_hit_st1_o),
      .cache_hit_o    (hit_st1_o)
  );

  bin2one #(
      .ONE_WIDTH(NUM_WAY),
      .BIN_WIDTH(WAY_DEPTH)
  ) bin2one (
      .bin(wayid_replacement_o[(WAY_DEPTH*(w_req_setid_i+1)-1)-:WAY_DEPTH]),
      .oh (wayid_replacement_one)
  );

endmodule
