`timescale 1ns / 1ps
`include "../l1_cache.svh"
import d_cache::*;

module tag_access_top_v2 #(
    parameter NUM_SET  = `KIANA_DCACHE_NSETS,   // 32
    parameter NUM_WAY  = `KIANA_DCACHE_NWAYS,   // 2
    parameter TAG_BITS = `KIANA_DCACHE_TAGBITS  // 24   
) (
    input logic clk,
    input logic rst_n,

    // From coreReq_pipe0
    input logic                        probeRead_valid_i,   // Probe Channel
    output logic                       probeRead_ready_o,   // Probe Channel
    input logic  [$clog2(NUM_SET)-1:0] probeRead_setIdx_i,  // Probe Channel
    input logic  [       TAG_BITS-1:0] tagFromCore_st1_i,
    input logic                        probeIsWrite_st1_i,

    //From coreReq_pipe1
    input logic coreReq_q_deq_fire_i,

    // To coreReq_pipe1
    output logic               hit_st1_o,
    output logic [NUM_WAY-1:0] waymaskHit_st1_o,

    // From memRsp_pipe0
    input logic                       allocateWrite_valid_i,   // Allocate Channel
    input logic [$clog2(NUM_SET)-1:0] allocateWrite_setIdx_i,  // Allocate Channel
    input logic [       TAG_BITS-1:0] allocateWriteData_st1_i,

    // From memRsp_pipe1
    input logic allocateWriteTagSRAMWValid_st1_i,

    // for flush: in order to not change way_dirty
    input logic mem_req_fire_i,

    // To memRsp_pipe1
    output logic                   needReplace_o,
    output logic [    NUM_WAY-1:0] waymaskReplacement_st1_o,  // onehot,for SRAMTemplate
    output logic [`KIANA_XLEN-1:0] addrReplacement_st1_o,

    // For InvOrFlu
    output logic                       hasDirty_st0_o,
    output logic [$clog2(NUM_SET)-1:0] dirtySetIdx_st0_o,
    output logic [$clog2(NUM_WAY)-1:0] dirtyWayMask_st0_o,
    output logic [       TAG_BITS-1:0] dirtyTag_st1_o,

    // For InvOrFlu and LRSC
    input logic                               flushChoosen_valid_i,
    input logic [$clog2(NUM_SET)+NUM_WAY-1:0] flushChoosen_i,        // [flushChoosen_setIdx,flushChoosen_waymask]

    // For Inv
    input logic invalidateAll_i,
    input logic tagready_st1_i

);

  logic                                             probeRead_fire;
  logic                                             probeRead_fire_q;
  logic                                             allocateWrite_fire;
  logic                                             allocateWrite_fire_q;


  // for probeRead buffer
  logic                                              probeRead_buf_valid;
  logic                                              probeRead_buf_ready;
  logic [                       $clog2(NUM_SET)-1:0] probeRead_buf_setIdx;
  logic                                              probeRead_ready_out;

  // for tagAccess read req arbiter(3to1)
  logic [                                     3-1:0] tagAccessRArb_in_valid;
  logic [                                     3-1:0] tagAccessRArb_in_ready;
  logic [                     $clog2(NUM_SET)*3-1:0] tagAccessRArb_in_setIdx;
  logic [                                     3-1:0] tagAccessRArb_valid_oh;
  logic [                                     2-1:0] tagAccessRArb_valid_bin;
  logic                                              tagAccessRArb_out_valid;
  logic [                       $clog2(NUM_SET)-1:0] tagAccessRArb_out_setIdx;

  // for timeAccess write req arbiter(2to1)
  logic [                                     2-1:0] timeAccessWArb_in_valid;
  logic [`KIANA_LENGTH_REPLACE_TIME*NUM_WAY*2-1 : 0] timeAccessWArb_in_data;
  logic [                             NUM_WAY*2-1:0] timeAccessWArb_in_waymask;
  logic [                     $clog2(NUM_SET)*2-1:0] timeAccessWArb_in_setIdx;
  logic [                                     2-1:0] timeAccessWArb_valid_oh;
  logic                                              timeAccessWArb_valid_bin;
  logic                                              timeAccessWArb_out_valid;
  logic [  `KIANA_LENGTH_REPLACE_TIME*NUM_WAY-1 : 0] timeAccessWArb_out_data;
  logic [                               NUM_WAY-1:0] timeAccessWArb_out_waymask;
  logic [                       $clog2(NUM_SET)-1:0] timeAccessWArb_out_setIdx;

  // for timeAccess write req conflict
  logic                                              timeAccessWArb_conflict;
  logic                                               timeAccessWArb_conflict_q;

  // RegNext
  logic  [                       $clog2(NUM_SET)-1:0] probeRead_setIdx_q;


  // for tagchecker module
  logic [                      TAG_BITS*NUM_WAY-1:0] tagchecker_tag_of_set;
  logic [                              TAG_BITS-1:0] tagchecker_tag_from_pipe;
  logic [                               NUM_WAY-1:0] tagchecker_valid_of_way;
  logic [                               NUM_WAY-1:0] tagchecker_waymask;
  logic                                              tagchecker_cache_hit;
  logic [                       $clog2(NUM_WAY)-1:0] tagchecker_waymask_bin;

  // register for way vaild and dirty
  logic  [                       NUM_WAY*NUM_SET-1:0] way_valid;
  logic  [                       NUM_WAY*NUM_SET-1:0] way_dirty;

  // RegEnable
  logic  [                       $clog2(NUM_SET)-1:0] probeRead_setIdx_st1;
  logic  [                       $clog2(NUM_SET)-1:0] allocateWrite_setIdx_st1;

  // for cacheHit_hold buffer
  logic                                              cacheHit_hold_w_ready;
  logic                                              cacheHit_hold_w_valid;
  logic [                             NUM_WAY+1-1:0] cacheHit_hold_w_data;  // cacheHit_hold_data = [hit,waymask]
  logic                                              cacheHit_hold_r_valid;
  logic                                              cacheHit_hold_r_ready;
  logic [                             NUM_WAY+1-1:0] cacheHit_hold_r_data;  // cacheHit_hold_data = [hit,waymask]

  // for lru_matrix
  logic                                              replacement_set_is_full;
  logic [                       $clog2(NUM_WAY)-1:0] replacement_waymask_st1_bin;
  logic [                               NUM_WAY-1:0] replacement_waymask_st1_oh;
  logic [                               NUM_SET-1:0] lru_update_entry;
  logic  [                               NUM_SET-1:0] probeRead_valid_of_setIdx;
  logic  [                               NUM_SET-1:0] allocateWrite_valid_of_setIdx;
  logic [                       $clog2(NUM_WAY)-1:0] lru_update_index;
  logic [               $clog2(NUM_WAY)*NUM_SET-1:0] lru_index_out;


  logic [                      TAG_BITS*NUM_WAY-1:0] tagBodyAccess_resp_data;

  logic [              TAG_BITS+$clog2(NUM_SET)-1:0] tag_and_set;  //  [tag,set]

  // For InvOrFlu
  logic                                              hasDirty_st0;
  logic [                       $clog2(NUM_SET)-1:0] choosenDirty_setIdx_st0;
  logic [                               NUM_SET-1:0] set_dirty;
  logic [                       NUM_WAY*NUM_SET-1:0] way_dirty_after_valid;
  logic [                               NUM_WAY-1:0] choosenDirty_set_valid;
  logic [                       $clog2(NUM_WAY)-1:0] choosenDirty_waymask_st0;  //  onehot -> bin
  logic [                              TAG_BITS-1:0] choosenDirty_tag_st1;
  //logic  [NUM_SET-1:0]           set_dirty_oh;
  logic                                              set_dirty_zero;
  logic [                       $clog2(NUM_SET)-1:0] set_dirty_bin;
  logic [                               NUM_WAY-1:0] choosenDirty_set_valid_oh;
  logic [                       $clog2(NUM_WAY)-1:0] choosenDirty_set_valid_bin;

  logic [                       $clog2(NUM_SET)-1:0] flushChoosen_setIdx;
  logic [                               NUM_WAY-1:0] flushChoosen_waymask;
  logic [                       $clog2(NUM_WAY)-1:0] flushChoosen_waymask_bin;


  assign probeRead_fire     = probeRead_valid_i & probeRead_ready_o;
  assign allocateWrite_fire = allocateWrite_valid_i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      probeRead_fire_q     <= 1'b0;
      allocateWrite_fire_q <= 1'b0;
    end else begin
      probeRead_fire_q     <= (probeRead_fire_q && !coreReq_q_deq_fire_i) ? probeRead_fire_q : probeRead_fire;
      allocateWrite_fire_q <= allocateWrite_fire;
    end
  end

  assign probeRead_buf_ready                                           = tagready_st1_i;

  // SRAM to store tag
  // For probe
  assign tagAccessRArb_in_valid[1]                                     = probeRead_valid_i;
  assign probeRead_ready_o                                             = tagAccessRArb_in_ready[1];
  assign tagAccessRArb_in_setIdx[$clog2(NUM_SET)*2-1-:$clog2(NUM_SET)] = probeRead_setIdx_i;
  // For allocate
  assign tagAccessRArb_in_valid[0]                                     = allocateWrite_valid_i;
  assign tagAccessRArb_in_setIdx[$clog2(NUM_SET)*1-1-:$clog2(NUM_SET)] = allocateWrite_setIdx_i;
  // For hasDirty
  assign tagAccessRArb_in_valid[2]                                     = flushChoosen_valid_i || invalidateAll_i;
  assign tagAccessRArb_in_setIdx[$clog2(NUM_SET)*3-1-:$clog2(NUM_SET)] = choosenDirty_setIdx_st0;

  assign tagAccessRArb_in_ready[0]                                     = 1'b1;
  assign tagAccessRArb_in_ready[1]                                     = !tagAccessRArb_in_valid[0];
  assign tagAccessRArb_in_ready[2]                                     = !tagAccessRArb_in_valid[1];
  assign tagAccessRArb_out_valid                                       = tagAccessRArb_in_valid[tagAccessRArb_valid_bin];
  assign tagAccessRArb_out_setIdx                                      = tagAccessRArb_in_setIdx[$clog2(NUM_SET)*(tagAccessRArb_valid_bin+1)-1-:$clog2(NUM_SET)];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      probeRead_setIdx_q <= 'b0;
    end else begin
      probeRead_setIdx_q <= (probeRead_fire_q && !coreReq_q_deq_fire_i) ? probeRead_setIdx_q : probeRead_setIdx_i;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      allocateWrite_setIdx_st1 <= 'b0;
    end else if (allocateWrite_fire) begin
      allocateWrite_setIdx_st1 <= allocateWrite_setIdx_i;
    end else begin
      allocateWrite_setIdx_st1 <= allocateWrite_setIdx_st1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      probeRead_setIdx_st1 <= 'b0;
    end else if (probeRead_fire) begin
      probeRead_setIdx_st1 <= probeRead_setIdx_i;
    end else begin
      probeRead_setIdx_st1 <= probeRead_setIdx_st1;
    end
  end

  assign tagchecker_tag_of_set             = tagBodyAccess_resp_data;  // st1
  assign tagchecker_tag_from_pipe          = tagFromCore_st1_i;  // st1
  assign tagchecker_valid_of_way           = way_valid[NUM_WAY*(probeRead_setIdx_st1+1)-1-:NUM_WAY];  // st1

  // Queue
  assign cacheHit_hold_w_valid             = probeRead_buf_valid;
  assign cacheHit_hold_w_data[NUM_WAY-1:0] = !probeRead_buf_ready ? tagchecker_waymask : 1'b0;  // waymask
  assign cacheHit_hold_w_data[NUM_WAY]     = tagchecker_cache_hit && !probeRead_buf_ready;  // hit
  assign cacheHit_hold_r_ready             = probeRead_buf_ready;

  assign hit_st1_o                         = ((tagchecker_cache_hit && probeRead_fire_q)  /*|| cacheHit_hold_r_data[NUM_WAY]  && cacheHit_hold_r_valid*/) && probeRead_buf_valid;
  assign waymaskHit_st1_o                  = tagchecker_waymask;

  assign flushChoosen_setIdx               = flushChoosen_i[$clog2(NUM_SET)+NUM_WAY-1:NUM_WAY];
  assign flushChoosen_waymask              = flushChoosen_i[NUM_WAY-1:0];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      way_dirty <= {(NUM_WAY * NUM_SET) {1'b0}};
    end else if (hit_st1_o && !(probeRead_fire_q && !coreReq_q_deq_fire_i) && probeIsWrite_st1_i) begin
      way_dirty[NUM_WAY*probeRead_setIdx_q+tagchecker_waymask_bin] <= 1'b1;
    end else if (flushChoosen_valid_i) begin
      way_dirty[NUM_WAY*flushChoosen_setIdx+flushChoosen_waymask_bin] <= 1'b0;
    end else if (needReplace_o) begin
      way_dirty[NUM_WAY*allocateWrite_setIdx_st1+replacement_waymask_st1_bin] <= 1'b0;
    end else begin
      way_dirty <= way_dirty;
    end
  end

  assign needReplace_o = way_dirty[NUM_WAY*allocateWrite_setIdx_st1+replacement_waymask_st1_bin] && allocateWrite_fire_q;

  genvar i;
  generate
    for (i = 0; i < NUM_SET; i = i + 1) begin : lru_input_loop
      always_comb begin
        if (probeRead_fire_q && i == probeRead_setIdx_st1 && hit_st1_o) begin
          probeRead_valid_of_setIdx[i]     = 1'b1;
          allocateWrite_valid_of_setIdx[i] = 1'b0;
        end else if (allocateWriteTagSRAMWValid_st1_i && i == allocateWrite_setIdx_st1) begin
          probeRead_valid_of_setIdx[i]     = 1'b0;
          allocateWrite_valid_of_setIdx[i] = 1'b1;
        end else begin
          probeRead_valid_of_setIdx[i]     = 1'b0;
          allocateWrite_valid_of_setIdx[i] = 1'b0;
        end
      end
    end
  endgenerate

  // when not full, output PriorityEncoder(~io.validOfSet)))
  logic [        NUM_WAY-1:0] way_nvalid    [0:NUM_SET-1];
  logic [        NUM_WAY-1:0] way_nvalid_oh [0:NUM_SET-1];
  logic [$clog2(NUM_WAY)-1:0] way_nvalid_bin[0:NUM_SET-1];

  genvar n;
  generate
    for (n = 0; n < NUM_SET; n = n + 1) begin : NOT_FULL_WAY_OUTPUT
      assign way_nvalid[n] = ~way_valid[NUM_WAY*(n+1)-1-:NUM_WAY];

      fixed_pri_arb #(
          .ARB_WIDTH(NUM_WAY)
      ) nvalid_oh (
          .req  (way_nvalid[n]),
          .grant(way_nvalid_oh[n])
      );

      one2bin #(
          .ONE_WIDTH(NUM_WAY),
          .BIN_WIDTH($clog2(NUM_WAY))
      ) nvalid_bin (
          .oh (way_nvalid_oh[n]),
          .bin(way_nvalid_bin[n])
      );

    end
  endgenerate

  assign waymaskReplacement_st1_o    = replacement_waymask_st1_oh;
  assign lru_update_entry            = allocateWrite_valid_of_setIdx | probeRead_valid_of_setIdx;
  assign lru_update_index            = (probeRead_fire_q && hit_st1_o) ? tagchecker_waymask_bin : replacement_waymask_st1_bin;
  assign replacement_waymask_st1_bin = &way_valid[NUM_WAY*(allocateWrite_setIdx_st1+1)-1-:NUM_WAY] ? lru_index_out[$clog2(NUM_WAY)*(allocateWrite_setIdx_st1+1)-1-:$clog2(NUM_WAY)] : way_nvalid_bin[allocateWrite_setIdx_st1];
  assign replacement_set_is_full     = way_valid[NUM_WAY*(allocateWrite_setIdx_st1+1)-1-:NUM_WAY] == {NUM_WAY{1'b1}};

  assign tag_and_set                 = {tagBodyAccess_resp_data[TAG_BITS*(replacement_waymask_st1_bin+1)-1-:TAG_BITS], allocateWrite_setIdx_st1};
  assign addrReplacement_st1_o       = {tag_and_set, {(`KIANA_DCACHE_BLOCKOFFSETBITS + `KIANA_DCACHE_WORDOFFSETBITS) {1'b0}}};  // tag + setIdx + blockOffset + wordOffset

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      way_valid <= {(NUM_WAY * NUM_SET) {1'b0}};
    end else if (allocateWrite_fire_q && !replacement_set_is_full) begin
      way_valid[NUM_WAY*allocateWrite_setIdx_st1+replacement_waymask_st1_bin] <= 1'b1;
    end else if (invalidateAll_i) begin
      way_valid <= {(NUM_WAY * NUM_SET) {1'b0}};
    end else begin
      way_valid <= way_valid;
    end
  end

  assign way_dirty_after_valid = way_valid & way_dirty;

  genvar j;
  generate
    for (j = 0; j < NUM_SET; j = j + 1) begin : set_loop
      assign set_dirty[j] = |way_dirty_after_valid[NUM_WAY*(j+1)-1-:NUM_WAY];
    end
  endgenerate

  logic [$clog2(NUM_WAY)-1:0] choosenDirty_waymask_st1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      choosenDirty_waymask_st1 <= 'd0;
    end else begin
      choosenDirty_waymask_st1 <= choosenDirty_waymask_st0;
    end
  end

  assign hasDirty_st0             = |set_dirty;
  assign choosenDirty_setIdx_st0  = set_dirty_bin;
  assign choosenDirty_set_valid   = way_dirty_after_valid[NUM_WAY*(choosenDirty_setIdx_st0+1)-1-:NUM_WAY];
  assign choosenDirty_waymask_st0 = choosenDirty_set_valid_bin;
  assign choosenDirty_tag_st1     = tagBodyAccess_resp_data[TAG_BITS*(choosenDirty_waymask_st1+1)-1-:TAG_BITS];

  assign hasDirty_st0_o           = hasDirty_st0;
  assign dirtySetIdx_st0_o        = choosenDirty_setIdx_st0;
  assign dirtyWayMask_st0_o       = choosenDirty_waymask_st0;
  assign dirtyTag_st1_o           = choosenDirty_tag_st1;





  stream_fifo_pipe_true #(
      .DATA_WIDTH($clog2(NUM_SET)),
      .FIFO_DEPTH(1)                 //can't be zero
  ) U_probe_read_buffer (
      .clk      (clk),
      .rst_n    (rst_n),
      .w_ready_o(probeRead_ready_out),
      .w_valid_i(probeRead_valid_i),
      .w_data_i (probeRead_setIdx_i),
      .r_valid_o(probeRead_buf_valid),
      .r_ready_i(probeRead_buf_ready),
      .r_data_o (probeRead_buf_setIdx)
  );

  sram_template_l1d_tag #(
      .GEN_WIDTH(TAG_BITS),
      .NUM_SET  (NUM_SET),
      .NUM_WAY  (NUM_WAY),          //way should >= 1
      .SET_DEPTH($clog2(NUM_SET)),
      .WAY_DEPTH($clog2(NUM_WAY))
  ) U_tag_body_access (
      .clk            (clk),
      .rst_n          (rst_n),
      .r_req_valid_i  (tagAccessRArb_out_valid),
      .r_req_setid_i  (tagAccessRArb_out_setIdx),
      .r_resp_data_o  (tagBodyAccess_resp_data),                                      //[GEN_WIDTH-1:0] [0:NUM_WAY-1]
      .w_req_valid_i  (  /*allocateWrite_fire_q*/ allocateWriteTagSRAMWValid_st1_i),
      .w_req_setid_i  (allocateWrite_setIdx_st1),
      .w_req_waymask_i(replacement_waymask_st1_oh),
      .w_req_data_i   ({NUM_WAY{allocateWriteData_st1_i}})
  );

  fixed_pri_arb #(
      .ARB_WIDTH(3)
  ) U_fixed_pri_tagAccessRArb (
      .req  (tagAccessRArb_in_valid),
      .grant(tagAccessRArb_valid_oh)
  );

  one2bin #(
      .ONE_WIDTH(3),
      .BIN_WIDTH(2)
  ) U_one2bin_tagAccessRArb (
      .oh (tagAccessRArb_valid_oh),
      .bin(tagAccessRArb_valid_bin)
  );

  genvar k;
  generate
    for (k = 0; k < NUM_SET; k = k + 1) begin : lru_module_loop

      lru_matrix #(
          .NUM_WAY  (NUM_WAY),
          .WAY_DEPTH($clog2(NUM_WAY))
      ) U_lru_matrix (
          .clk           (clk),
          .rst_n         (rst_n),
          .update_entry_i(lru_update_entry[k]),
          .update_index_i(lru_update_index),
          .lru_index_o   (lru_index_out[$clog2(NUM_WAY)*(k+1)-1-:$clog2(NUM_WAY)])
      );

    end
  endgenerate

  bin2one #(
      .ONE_WIDTH(NUM_WAY),
      .BIN_WIDTH($clog2(NUM_WAY))
  ) U_bin2one_lru_index_out (
      .bin(replacement_waymask_st1_bin),
      .oh (replacement_waymask_st1_oh)
  );



  tag_checker #(
      .NUM_WAY (NUM_WAY),
      .TAG_BITS(TAG_BITS)
  ) U_tag_checker (
      .tag_of_set_i   (tagchecker_tag_of_set),
      .tag_from_pipe_i(tagchecker_tag_from_pipe),
      .valid_of_way_i (tagchecker_valid_of_way),
      .waymask_o      (tagchecker_waymask),        //  onehot
      .cache_hit_o    (tagchecker_cache_hit)

  );


  stream_fifo #(
      .DATA_WIDTH(NUM_WAY + 1),
      .FIFO_DEPTH(1)             //can't be zero
  ) U_cacheHit_hold (
      .clk      (clk),
      .rst_n    (rst_n),
      .w_ready_o(cacheHit_hold_w_ready),
      .w_valid_i(cacheHit_hold_w_valid),
      .w_data_i (cacheHit_hold_w_data),
      .r_valid_o(cacheHit_hold_r_valid),
      .r_ready_i(cacheHit_hold_r_ready),
      .r_data_o (cacheHit_hold_r_data)
  );

  one2bin #(
      .ONE_WIDTH(NUM_WAY),
      .BIN_WIDTH($clog2(NUM_WAY))
  ) U_one2bin_tagchecker_waymask (
      .oh (tagchecker_waymask),
      .bin(tagchecker_waymask_bin)
  );

  lzc #(
      .WIDTH    (NUM_SET),
      .MODE     (1'b0),
      .CNT_WIDTH($clog2(NUM_SET))
  ) x_bin (
      .in_i   (set_dirty),
      .cnt_o  (set_dirty_bin),
      .empty_o(set_dirty_zero)
  );


  fixed_pri_arb #(
      .ARB_WIDTH(NUM_WAY)
  ) U_fixed_pri_choosenDirty_set_valid (
      .req  (choosenDirty_set_valid),
      .grant(choosenDirty_set_valid_oh)
  );


  one2bin #(
      .ONE_WIDTH(NUM_WAY),
      .BIN_WIDTH($clog2(NUM_WAY))
  ) U_one2bin_chooseDirty_set_valid (
      .oh (choosenDirty_set_valid_oh),
      .bin(choosenDirty_set_valid_bin)
  );

  one2bin #(
      .ONE_WIDTH(NUM_WAY),
      .BIN_WIDTH($clog2(NUM_WAY))
  ) flush_choosen_waymask_oh2bin (
      .oh (flushChoosen_waymask),
      .bin(flushChoosen_waymask_bin)
  );




endmodule
