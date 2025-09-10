`timescale 1ns/1ns
`include "../define.svh"
//`include "L2cache_define.v"

module banked_store (
  input logic                                   clk                 ,
  input logic                                   rst_n               ,

  input logic   [`KIANA_WAY_BITS-1:0]                 sinkD_adr_way_i     ,
  input logic   [`KIANA_SET_BITS-1:0]                 sinkD_adr_set_i     ,
  input logic   [`KIANA_OUTER_MASK_BITS-1:0]          sinkD_adr_mask_i    ,
  input logic   [`KIANA_L2CACHE_BEATBYTES*8-1:0]      sinkD_dat_data_i    ,
  input logic                                   sinkD_adr_valid_i   ,
  output logic                                  sinkD_adr_ready_o   ,

  input logic   [`KIANA_WAY_BITS-1:0]                 sourceD_radr_way_i  ,
  input logic   [`KIANA_SET_BITS-1:0]                 sourceD_radr_set_i  ,
  input logic   [`KIANA_INNER_MASK_BITS-1:0]          sourceD_radr_mask_i ,
  output logic  [`KIANA_L2CACHE_BEATBYTES*8-1:0]      sourceD_rdat_data_o ,
  input logic                                   sourceD_radr_valid_i,
  output logic                                  sourceD_radr_ready_o,

  input logic   [`KIANA_WAY_BITS-1:0]                 sourceD_wadr_way_i  ,
  input logic   [`KIANA_SET_BITS-1:0]                 sourceD_wadr_set_i  ,
  input logic   [`KIANA_INNER_MASK_BITS-1:0]          sourceD_wadr_mask_i ,
  input logic   [`KIANA_L2CACHE_BEATBYTES*8-1:0]      sourceD_wdat_data_i ,
  input logic                                   sourceD_wadr_valid_i,
  output logic                                  sourceD_wadr_ready_o
  );

  localparam  MASK_BITS   = (`KIANA_INNER_MASK_BITS > `KIANA_OUTER_MASK_BITS) ? `KIANA_INNER_MASK_BITS 
                                                                  : `KIANA_OUTER_MASK_BITS;
  localparam  INNER_BYTES = `KIANA_L2CACHE_BEATBYTES                                      ;
  localparam  OUTER_BYTES = `KIANA_L2CACHE_BEATBYTES                                      ;
  localparam  ROW_BYTES   = (INNER_BYTES > OUTER_BYTES) ? INNER_BYTES : OUTER_BYTES ;//ROW_BYTES < `KIANA_L2CACHE_SIZEBYTES 
  localparam  ROW_ENTRIES = `KIANA_L2CACHE_SIZEBYTES / ROW_BYTES                          ;//8
  localparam  ROW_BITS    = $clog2(ROW_ENTRIES)                                     ;
  localparam  NUM_BANKS   = ROW_BYTES / `KIANA_L2CACHE_WRITEBYTES                         ;//8
  localparam  CODE_BITS   = 8 * `KIANA_L2CACHE_WRITEBYTES                                 ;//8 
  localparam  SINGLE_PORT = 1'b0                                                    ;//dual port

  logic    [`KIANA_SET_BITS-1:0]                           set_sel                        ;
  logic    [`KIANA_WAY_BITS-1:0]                           way_sel                        ;
  logic    [`KIANA_L2CACHE_NWAYS-1:0]                      waymask                        ;
  logic    [`KIANA_L2CACHE_BEATBYTES*8-1:0]                data_sel                       ;
  logic    [CODE_BITS-1:0]                           bank_datain     [0:NUM_BANKS-1];
  logic    [`KIANA_L2CACHE_NWAYS*CODE_BITS-1:0]            bank_set_datain [0:NUM_BANKS-1];             
  logic    [MASK_BITS-1:0]                           mask_sel                       ;
  logic    [NUM_BANKS-1:0]                           sram_template_wen              ;   
  logic    [CODE_BITS*`KIANA_L2CACHE_NWAYS*NUM_BANKS-1:0]  sram_template_rdata            ;
  logic     [`KIANA_INNER_MASK_BITS-1:0]                    sourceD_radr_mask_reg          ;

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sourceD_radr_mask_reg <= 'd0;
    end
    else begin
      sourceD_radr_mask_reg <= sourceD_radr_mask_i;
    end
  end

  //assign set_index   = sourceD_radr_set_i * `L2CACHE_NWAYS + sourceD_radr_way_i                      ;
  assign data_sel    = sinkD_adr_valid_i ? sinkD_dat_data_i : sourceD_wdat_data_i                    ;
  assign mask_sel    = sinkD_adr_valid_i ? sinkD_adr_mask_i : sourceD_wadr_mask_i                    ;
  assign set_sel     = sinkD_adr_valid_i ? sinkD_adr_set_i  : sourceD_wadr_set_i                     ;
  assign way_sel     = sinkD_adr_valid_i ? sinkD_adr_way_i  : sourceD_wadr_way_i                     ;
  assign sram_template_wen = {NUM_BANKS{(sourceD_wadr_valid_i || sinkD_adr_valid_i)}} & mask_sel     ;
  //assign set_idx_sel = sinkD_adr_valid_i ? (sinkD_adr_set_i * `L2CACHE_NWAYS + sinkD_adr_way_i) : 
  //                                         (sourceD_wadr_set_i * `L2CACHE_NWAYS + sourceD_wadr_way_i);

  //way_sel to waymask(bin to one)
  bin2one #(
    .ONE_WIDTH(`KIANA_L2CACHE_NWAYS),
    .BIN_WIDTH(`KIANA_WAY_BITS     )
  )
  U_bin2one (
    .bin(way_sel),
    .oh (waymask)
    );

  genvar  i;
  generate
    for(i=0;i<NUM_BANKS;i=i+1) begin:gen_i
      //for(j=0;j<`L2CACHE_NWAYS;j=j+1) begin:gen_j
      assign bank_datain[i]     = data_sel[(i+1)*CODE_BITS-1-:CODE_BITS];
          //assign bank_set_datain[i][(j+1)*CODE_BITS-1-:CODE_BITS] = (j==way_sel) ? bank_datain[i] : 'd0;
      
      //sram_template
      sram_template #(
        .GEN_WIDTH(CODE_BITS             ),
        .NUM_SET  (`KIANA_L2CACHE_NSETS        ),
        .NUM_WAY  (`KIANA_L2CACHE_NWAYS        ),
        .SET_DEPTH($clog2(`KIANA_L2CACHE_NSETS)),
        .WAY_DEPTH($clog2(`KIANA_L2CACHE_NWAYS))
      )
      U_cc_banks (
        .clk            (clk                                      ), 
        .rst_n          (rst_n                                    ),
                     
        .r_req_valid_i  (sourceD_radr_valid_i                     ),
        .r_req_setid_i  (sourceD_radr_set_i                       ),
                     
        .r_resp_data_o  (sram_template_rdata[(i+1)*CODE_BITS*`KIANA_L2CACHE_NWAYS-1-:CODE_BITS*`KIANA_L2CACHE_NWAYS]),
                     
        .w_req_valid_i  (sram_template_wen[i]                     ),
        .w_req_setid_i  (set_sel                                  ),
        .w_req_waymask_i(waymask                                  ),
        .w_req_data_i   (bank_set_datain[i]                       )
        );

      assign sourceD_rdat_data_o[(i+1)*CODE_BITS-1-:CODE_BITS] =  sram_template_rdata[i*CODE_BITS*`KIANA_L2CACHE_NWAYS+(sourceD_radr_way_i+1)*CODE_BITS-1-:CODE_BITS] /*& {CODE_BITS{sourceD_radr_mask_reg[i]}}*/; 
      
      //end
    end
  endgenerate

  genvar j,k;
  generate
    for(j=0;j<NUM_BANKS;j=j+1) begin:gen_j
      for(k=0;k<`KIANA_L2CACHE_NWAYS;k=k+1) begin:gen_k
          assign bank_set_datain[j][(k+1)*CODE_BITS-1-:CODE_BITS] = (k==way_sel) ? bank_datain[j] : 'd0;
      end
    end
  endgenerate

  assign sourceD_wadr_ready_o = !sinkD_adr_valid_i;
  assign sinkD_adr_ready_o    = 1'b1              ;
  assign sourceD_radr_ready_o = 1'b1              ;

endmodule
