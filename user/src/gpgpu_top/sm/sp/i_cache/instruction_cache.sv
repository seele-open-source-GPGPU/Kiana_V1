`timescale 1ns/1ns
`include "../common/common.svh"
import i_cache::*;

module instruction_cache (
  input  logic                            clk               ,
  input  logic                            rst_n             ,

  input  logic                            invalid_i         ,
  // wrap
  input  logic                            core_req_valid_i  ,
  input  logic        [`XLEN-1:0]         core_req_addr_i   ,
  input  logic        [`NUM_FETCH-1:0]    core_req_mask_i   ,
  input  logic        [`DEPTH_WARP-1:0]   core_req_wid_i    ,

  input  logic                            flush_pipe_valid_i,
  input  logic        [`DEPTH_WARP-1:0]   flush_pipe_wid_i  ,

  // thread
  output logic                            core_rsp_valid_o  ,
  output logic        [`XLEN-1:0]         core_rsp_addr_o   ,
  output logic        [`NUM_FETCH*`XLEN-1:0] core_rsp_data_o,
  output logic        [`NUM_FETCH-1:0]    core_rsp_mask_o   ,
  output logic        [`DEPTH_WARP-1:0]   core_rsp_wid_o    ,
  output logic                            core_rsp_status_o , // 0 hit, 1 miss

  // next-level mem response (handle miss)
  output logic                            mem_rsp_ready_o   ,
  input  logic                            mem_rsp_valid_i   ,
  input  logic        [`DEPTH_WARP-1:0]   mem_rsp_d_source_i,
  input  logic        [`XLEN-1:0]         mem_rsp_d_addr_i  ,
  input  logic        [`DCACHE_BLOCKWORDS*`XLEN-1:0] mem_rsp_d_data_i,

  // next-level mem request (send miss request)
  input  logic                            mem_req_ready_i   ,
  output logic                            mem_req_valid_o   ,
  output logic        [`WIDBITS-1:0]      mem_req_a_source_o,
  output logic        [`XLEN-1:0]         mem_req_a_addr_o
);

  localparam int BLOCK_BITS = `DCACHE_BLOCKWORDS*32;
  localparam int BA_BITS    = `DCACHE_TAGBITS+`DCACHE_SETIDXBITS;
  localparam int FIFO_BITS  = `DEPTH_WARP+`XLEN+(`DCACHE_BLOCKWORDS*`XLEN);

  // data array access
  logic                                     dataAccess_r_req_valid;
  logic [`DCACHE_NWAYS*BLOCK_BITS-1:0]      dataAccess_w_req_data;
  logic [`DCACHE_NWAYS*BLOCK_BITS-1:0]      dataAccess_data;

  // tag array access
  logic                                     tagAccess_r_req_valid;
  logic [`DCACHE_SETIDXBITS-1:0]            tagAccess_r_req_setid;
  logic [`DCACHE_TAGBITS-1:0]               tagAccess_tagFromCore_st1;
  logic [`DCACHE_SETIDXBITS-1:0]            tagAccess_w_req_setid;
  logic [`DCACHE_TAGBITS*`DCACHE_NWAYS-1:0] tagAccess_w_req_data;
  logic [`DCACHE_TAGBITS-1:0]               tagAccess_w_req_data_scalar;
  logic [`DCACHE_WAYIDXBITS-1:0]            wayid_hit_st1; // bin
  logic                                     tagAccess_hit_st1;
  logic [`DCACHE_WAYIDXBITS-1:0]            wayid_replace_st0; // bin
  logic [`DCACHE_NSETS*`DCACHE_WAYIDXBITS-1:0] tagAccess_wayid_replacement;
  logic [`DCACHE_NWAYS-1:0]                 wayid_replace_st0_one;

  // mshr
  logic [BA_BITS-1:0]                       mshrAccess_miss_req_block_addr;
  logic [`DEPTH_WARP-1:0]                   mshrAccess_miss_req_target_info;
  logic                                     mshrAccess_miss_rsp_in_ready;
  logic [BA_BITS-1:0]                       mshrAccess_miss_rsp_in_block_addr;
  logic [BA_BITS-1:0]                       mshrAccess_miss_rsp_out_block_addr;
  logic [BA_BITS-1:0]                       mshrAccess_miss2mem_block_addr;

  // mem resp fifo
  logic                                     memRsp_fire;
  logic                                     memRsp_valid;
  logic [FIFO_BITS-1:0]                     memRsp_data_i;
  logic [FIFO_BITS-1:0]                     memRsp_data_o;
  logic [`DEPTH_WARP-1:0]                   mem_rsp_d_source_o;
  logic [`XLEN-1:0]                         mem_rsp_d_addr_o;
  logic [`DCACHE_BLOCKWORDS*`XLEN-1:0]      mem_rsp_d_data_o;

  // pipeline regs / wires
  logic [BLOCK_BITS-1:0]                    data_after_wayid_st1;
  logic                                     shouldFlushCoreRsp_st0, shouldFlushCoreRsp_st1;
  logic                                     cacheMiss_st1;
  logic                                     order_violation_st1;
  logic                                     status_st1, status_st2;

  logic [`DEPTH_WARP-1:0]                   wid_st1, wid_st2, wid_st3;
  logic [`XLEN-1:0]                         addr_st1, addr_st2;
  logic [`NUM_FETCH-1:0]                    mask_st1, mask_st2;
  logic                                     core_req_fire_st1, core_req_fire_st2;
  logic [BLOCK_BITS-1:0]                    data_after_wayid_st2;
  logic                                     shouldFlushCoreRsp_st0_r, shouldFlushCoreRsp_st1_r;
  logic                                     order_violation_st2, order_violation_st3;
  logic                                     status_st1_r;
  logic                                     cacheMiss_st2, cacheMiss_st3;

  assign wayid_replace_st0 = tagAccess_wayid_replacement[
                              (`DCACHE_WAYIDXBITS*(tagAccess_w_req_setid+1)-1)-:`DCACHE_WAYIDXBITS];


  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      wid_st1                  <= '0;
      wid_st2                  <= '0;
      wid_st3                  <= '0;
      addr_st1                 <= '0;
      addr_st2                 <= '0;
      mask_st1                 <= '0;
      mask_st2                 <= '0;
      core_req_fire_st1        <= '0;
      core_req_fire_st2        <= '0;
      data_after_wayid_st2     <= '0;
      order_violation_st2      <= '0;
      order_violation_st3      <= '0;
      shouldFlushCoreRsp_st0_r <= '0;
      shouldFlushCoreRsp_st1_r <= '0;
      status_st1_r             <= '0;
      cacheMiss_st2            <= '0;
      cacheMiss_st3            <= '0;
    end 
    else begin
      wid_st1 <= core_req_wid_i;
      wid_st2 <= wid_st1;
      wid_st3 <= wid_st2;
      addr_st1 <= core_req_addr_i;
      addr_st2 <= addr_st1;
      mask_st1 <= core_req_mask_i;
      mask_st2 <= mask_st1;
      core_req_fire_st1 <= (core_req_valid_i && !shouldFlushCoreRsp_st0);
      core_req_fire_st2 <= (core_req_fire_st1 && !shouldFlushCoreRsp_st1);
      data_after_wayid_st2 <= data_after_wayid_st1;
      order_violation_st2 <= order_violation_st1;
      order_violation_st3 <= order_violation_st2;
      shouldFlushCoreRsp_st0_r <= shouldFlushCoreRsp_st0;
      shouldFlushCoreRsp_st1_r <= shouldFlushCoreRsp_st1;
      status_st1_r <= status_st1;
      cacheMiss_st2 <= shouldFlushCoreRsp_st1 ? 'h0 : cacheMiss_st1;
      cacheMiss_st3 <= cacheMiss_st2;
    end 
  end 

  assign cacheMiss_st1 = (!tagAccess_hit_st1 && core_req_fire_st1);

  assign shouldFlushCoreRsp_st0 = (core_req_wid_i == flush_pipe_wid_i) && flush_pipe_valid_i;
  assign shouldFlushCoreRsp_st1 = (wid_st1 == flush_pipe_wid_i) && flush_pipe_valid_i;

  assign tagAccess_r_req_valid = core_req_valid_i && (!shouldFlushCoreRsp_st0);
  assign tagAccess_tagFromCore_st1 = addr_st1 >> (`XLEN-`DCACHE_TAGBITS);
  assign tagAccess_w_req_data_scalar = mshrAccess_miss_rsp_out_block_addr >> (BA_BITS-`DCACHE_TAGBITS);
  assign tagAccess_w_req_data = {`DCACHE_NWAYS{tagAccess_w_req_data_scalar}};

  assign mshrAccess_miss_req_block_addr = addr_st1 >> (`XLEN-(`DCACHE_TAGBITS+`DCACHE_SETIDXBITS));
  assign mshrAccess_miss_req_target_info = {wid_st1,addr_st1[`DCACHE_BLOCKOFFSETBITS+`DCACHE_WORDOFFSETBITS-1:0]};
  assign mshrAccess_miss_rsp_in_block_addr = mem_rsp_d_addr_o >> (`XLEN-(`DCACHE_TAGBITS+`DCACHE_SETIDXBITS));

  assign mem_req_a_addr_o = {mshrAccess_miss2mem_block_addr,{(32-BA_BITS){1'h0}}};

  assign dataAccess_r_req_valid = core_req_valid_i && !shouldFlushCoreRsp_st0;

  assign dataAccess_w_req_data = {`DCACHE_NWAYS{mem_rsp_d_data_o}};

  assign data_after_wayid_st1 = dataAccess_data[(wayid_hit_st1+1)*BLOCK_BITS-1 -: BLOCK_BITS];
  
  assign core_rsp_valid_o = core_req_fire_st2;
  assign core_rsp_data_o = data_after_wayid_st2;
  assign core_rsp_wid_o = wid_st2;
  assign core_rsp_mask_o = mask_st2;
  assign core_rsp_addr_o = addr_st2;

  assign status_st1 = shouldFlushCoreRsp_st0_r ? 1'b0 : cacheMiss_st1; 
  assign status_st2 = shouldFlushCoreRsp_st1_r ? 1'b0 : status_st1_r; 

  assign core_rsp_status_o = status_st2;

  assign memRsp_fire = memRsp_valid && mshrAccess_miss_rsp_in_ready;
  assign memRsp_data_i = {mem_rsp_d_data_i,mem_rsp_d_addr_i,mem_rsp_d_source_i};
  assign {mem_rsp_d_data_o,mem_rsp_d_addr_o,mem_rsp_d_source_o} = memRsp_data_o;

  assign order_violation_st1 = ((wid_st1 == wid_st2) && cacheMiss_st2 && !order_violation_st2) ||
                               ((wid_st1 == wid_st3) && cacheMiss_st3 && !order_violation_st3);

//handle the req ID from the core
  get_setid #(
    .DATA_WIDTH      (`XLEN                  ),
    .XLEN            (`XLEN                  ),
    .SETIDXBITS      (`DCACHE_SETIDXBITS     ),
    .BLOCK_OFFSETBITS(`DCACHE_BLOCKOFFSETBITS),
    .WORD_OFFSETBITS (`DCACHE_WORDOFFSETBITS ),
    .BA_BITS         (BA_BITS                )
    ) get_setid_tagAccess_r_req(
    .data_i(core_req_addr_i      ), 
    .data_o(tagAccess_r_req_setid)
    );
//handle the memory refill ID
  get_setid #(
    .DATA_WIDTH      (BA_BITS                ),
    .XLEN            (`XLEN                  ),
    .SETIDXBITS      (`DCACHE_SETIDXBITS     ),
    .BLOCK_OFFSETBITS(`DCACHE_BLOCKOFFSETBITS),
    .WORD_OFFSETBITS (`DCACHE_WORDOFFSETBITS ),
    .BA_BITS         (BA_BITS                )
    ) get_setid_tagAccess_w_req(
    .data_i(mshrAccess_miss_rsp_out_block_addr), 
    .data_o(tagAccess_w_req_setid             )
    );
 //store tag, judge whether hit, decide replace way
  tag_access_icache #(
    .TAG_WIDTH(`DCACHE_TAGBITS   ),
    .NUM_SET  (`DCACHE_NSETS     ),
    .NUM_WAY  (`DCACHE_NWAYS     ), 
    .SET_DEPTH(`DCACHE_SETIDXBITS), 
    .WAY_DEPTH(`DCACHE_WAYIDXBITS) 
    ) tagAccess(
    .clk                (clk                        ),
    .rst_n              (rst_n                      ),
    .invalid_i          (invalid_i                  ),
    .r_req_valid_i      (tagAccess_r_req_valid      ),
    .r_req_setid_i      (tagAccess_r_req_setid      ),
    .tagFromCore_st1_i  (tagAccess_tagFromCore_st1  ),
    .w_req_valid_i      (memRsp_fire                ),
    .w_req_setid_i      (tagAccess_w_req_setid      ),
    .w_req_data_i       (tagAccess_w_req_data       ),
    .wayid_replacement_o(tagAccess_wayid_replacement),
    .wayid_hit_st1_o    (wayid_hit_st1              ),
    .hit_st1_o          (tagAccess_hit_st1          )
    ); 
//binary to one-hot
  bin2one #(
    .ONE_WIDTH(`DCACHE_NWAYS     ),
    .BIN_WIDTH(`DCACHE_WAYIDXBITS)
    ) b2o(
    .bin(wayid_replace_st0    ),
    .oh (wayid_replace_st0_one)
    );
//Read and write cache block data by group
  sram_template #(
    .GEN_WIDTH(BLOCK_BITS        ), 
    .NUM_SET  (`DCACHE_NSETS     ), 
    .NUM_WAY  (`DCACHE_NWAYS     ), 
    .SET_DEPTH(`DCACHE_SETIDXBITS),
    .WAY_DEPTH(`DCACHE_WAYIDXBITS)
    ) dataAccess(
    .clk            (clk                   ),
    .rst_n          (rst_n                 ),
    .r_req_valid_i  (dataAccess_r_req_valid), //whether req is valid
    .r_req_setid_i  (tagAccess_r_req_setid ), //read req set ID
    .r_resp_data_o  (dataAccess_data       ), //read data
    .w_req_valid_i  (memRsp_fire           ), //mem write response valid
    .w_req_setid_i  (tagAccess_w_req_setid ), //write req set ID
    .w_req_waymask_i(wayid_replace_st0_one ), //one-hot, decide which way to write
    .w_req_data_i   (dataAccess_w_req_data )  //write block data
    );

//merge miss, handle memory refill
  mshr_icache #(
    .TI_WIDTH       (`WIDBITS              ), 
    .BA_BITS        (BA_BITS               ),
    .WID_BITS       (`DEPTH_WARP           ), 
    .NUM_ENTRY      (`DCACHE_MSHRENTRY     ), 
    .NUM_SUB_ENTRY  (`DCACHE_MSHRSUBENTRY  ), 
    .ENTRY_DEPTH    (`DCACHE_ENTRY_DEPTH   ), 
    .SUB_ENTRY_DEPTH(`DCACHE_SUBENTRY_DEPTH) 
    ) mshrAccess(
    .clk                      (clk                               ),
    .rst_n                    (rst_n                             ),
    .miss_req_valid_i         (cacheMiss_st1                     ),
    .miss_req_block_addr_i    (mshrAccess_miss_req_block_addr    ),
    .miss_req_target_info_i   (mshrAccess_miss_req_target_info   ),
    .miss_rsp_in_ready_o      (mshrAccess_miss_rsp_in_ready      ),
    .miss_rsp_in_valid_i      (memRsp_valid                      ),
    .miss_rsp_in_block_addr_i (mshrAccess_miss_rsp_in_block_addr ),
    .miss_rsp_out_ready_i     (1'h1                              ),
    .miss_rsp_out_block_addr_o(mshrAccess_miss_rsp_out_block_addr),
    .miss2mem_ready_i         (mem_req_ready_i                   ),
    .miss2mem_valid_o         (mem_req_valid_o                   ),
    .miss2mem_block_addr_o    (mshrAccess_miss2mem_block_addr    ),
    .miss2mem_instr_id_o      (mem_req_a_source_o                )
    );      
//Temporarily stores memory backfill data (data + addr + warp ID) waiting to be written to cache
  stream_fifo_pipe_true #(
    .DATA_WIDTH(FIFO_BITS),
    .FIFO_DEPTH(2        )
    ) memRsp(
    .clk      (clk                         ),
    .rst_n    (rst_n                       ),
    .w_ready_o(mem_rsp_ready_o             ),
    .w_valid_i(mem_rsp_valid_i             ),
    .w_data_i (memRsp_data_i               ),
    .r_valid_o(memRsp_valid                ),
    .r_ready_i(mshrAccess_miss_rsp_in_ready),
    .r_data_o (memRsp_data_o               )
    );

endmodule
