`timescale  1ns/1ns
`include "../define.svh"
import l2_cache::*;

module Scheduler#
( parameter dir_result_buffer_data_in_width = `KIANA_TAG_BITS + `KIANA_WAY_BITS + 4 + `KIANA_SET_BITS + `KIANA_L2C_BITS + `KIANA_OP_BITS +`KIANA_SIZE_BITS + `KIANA_SOURCE_BITS + `KIANA_TAG_BITS + `KIANA_OFFSET_BITS + `KIANA_PUT_BITS + `KIANA_DATA_BITS + `KIANA_MASK_BITS + `KIANA_PARAM_BITS ,
  parameter writebuffer_data_in_width = `KIANA_SET_BITS + `KIANA_L2C_BITS + `KIANA_OP_BITS + `KIANA_SIZE_BITS + `KIANA_SOURCE_BITS + `KIANA_TAG_BITS +  `KIANA_OFFSET_BITS + `KIANA_PUT_BITS + `KIANA_DATA_BITS + `KIANA_MASK_BITS + `KIANA_PARAM_BITS
)
(

  input logic                               clk                    ,
  input logic                               rst_n                  ,
  //in_a part flipped Decoupled and its handshake sigansls
  input logic                               sche_in_a_valid_i      ,
  output logic                              sche_in_a_ready_o      ,
  
  input logic  [`KIANA_OP_BITS-1:0]               sche_in_a_opcode_i     ,
  input logic  [`KIANA_SIZE_BITS-1:0]             sche_in_a_size_i       ,
  input logic  [`KIANA_SOURCE_BITS-1:0]           sche_in_a_source_i     ,
  input logic  [`KIANA_ADDRESS_BITS-1:0]          sche_in_a_addresss_i   ,
  input logic  [`KIANA_MASK_BITS-1:0]             sche_in_a_mask_i       ,
  input logic  [`KIANA_DATA_BITS-1:0]             sche_in_a_data_i       ,
  input logic  [`KIANA_PARAM_BITS-1:0]            sche_in_a_param_i      ,
  
  // in_d part Decoupled and its handshake sigansls
  output logic                              sche_in_d_valid_o      ,
  input logic                               sche_in_d_ready_i      ,
  
  output logic [`KIANA_ADDRESS_BITS-1:0]          sche_in_d_address_o    ,
  output logic [`KIANA_OP_BITS-1:0]               sche_in_d_opcode_o     ,
  output logic [`KIANA_SIZE_BITS-1:0]             sche_in_d_size_o       ,
  output logic [`KIANA_SOURCE_BITS-1:0]           sche_in_d_source_o     ,
  output logic [`KIANA_DATA_BITS-1:0]             sche_in_d_data_o       ,
  output logic [`KIANA_PARAM_BITS-1:0]            sche_in_d_param_o      ,

  output logic                              finish_issue_o         ,
  
  // out_a part Decoupled and its handshake sigansls
  output logic                              sche_out_a_valid_o     ,
  input logic                               sche_out_a_ready_i     ,
  
  output logic [`KIANA_OP_BITS-1:0]               sche_out_a_opcode_o    ,
  output logic [`KIANA_SIZE_BITS-1:0]             sche_out_a_size_o      ,
  output logic [`KIANA_SOURCE_BITS-1:0]           sche_out_a_source_o    ,
  output logic [`KIANA_ADDRESS_BITS-1:0]          sche_out_a_addresss_o  ,
  output logic [`KIANA_MASK_BITS-1:0]             sche_out_a_mask_o      ,
  output logic [`KIANA_DATA_BITS-1:0]             sche_out_a_data_o      ,
  output logic [`KIANA_PARAM_BITS-1:0]            sche_out_a_param_o     ,
  
  // out_d part Decoupled and its handshake sigansls
  input logic                               sche_out_d_valid_i     ,
  output logic                              sche_out_d_ready_o     ,
  input logic  [`KIANA_OP_BITS-1:0]               sche_out_d_opcode_i    ,
  //input logic  [`KIANA_SIZE_BITS-1:0]             sche_out_d_size_i      ,
  input logic  [`KIANA_SOURCE_BITS-1:0]           sche_out_d_source_i    ,
  input logic  [`KIANA_DATA_BITS-1:0]             sche_out_d_data_i      
  //input logic  [`KIANA_PARAM_BITS-1:0]            sche_out_d_param_i     
  );

  logic flush_ready;
  
  //  flip Decoupled FullRequest
  logic                                 sourceA_req_ready_o      ;
  logic                                 sourceA_req_valid_i      ;
  //sourceA req part handshake signals
  logic  [`KIANA_SET_BITS-1:0]                sourceA_req_set_i        ;
  //logic  [`KIANA_L2C_BITS-1:0]                sourceA_req_l2cidx_i     ;
  logic  [`KIANA_OP_BITS-1:0]                 sourceA_req_opcode_i     ;
  logic  [`KIANA_SIZE_BITS-1:0]               sourceA_req_size_i       ;
  logic  [`KIANA_SOURCE_BITS-1:0]             sourceA_req_source_i     ;
  logic  [`KIANA_TAG_BITS-1:0]                sourceA_req_tag_i        ;
  logic  [`KIANA_OFFSET_BITS-1:0]             sourceA_req_offset_i     ;
  logic  [`KIANA_PUT_BITS-1:0]                sourceA_req_put_i        ;
  logic  [`KIANA_DATA_BITS-1:0]               sourceA_req_data_i       ;
  logic  [`KIANA_MASK_BITS-1:0]               sourceA_req_mask_i       ;
  logic  [`KIANA_PARAM_BITS-1:0]              sourceA_req_param_i      ;
  //req part
  logic                                 sourceA_a_ready_i        ;
  logic                                 sourceA_a_valid_o        ;
  //a part decoupled 
  logic  [`KIANA_OP_BITS-1:0]                 sourceA_a_opcode_o       ;
  logic  [`KIANA_SIZE_BITS-1:0]               sourceA_a_size_o         ;
  logic  [`KIANA_SOURCE_BITS-1:0]             sourceA_a_source_o       ;
  logic  [`KIANA_ADDRESS_BITS-1:0]            sourceA_a_address_o      ;
  logic  [`KIANA_MASK_BITS-1:0]               sourceA_a_mask_o         ;
  logic  [`KIANA_DATA_BITS-1:0]               sourceA_a_data_o         ;
  logic  [`KIANA_PARAM_BITS-1:0]              sourceA_a_param_o        ;
  //above part is the Source A
  logic                                 SourceD_req_from_mem_i   ;
  logic                                 SourceD_req_hit_i        ;
  logic  [`KIANA_WAY_BITS-1:0]                SourceD_req_way_i        ;
  logic                                 SourceD_req_dirty_i      ;
  logic                                 SourceD_req_flush_i      ;
  logic                                 SourceD_req_last_flush_i ;
  logic  [`KIANA_SET_BITS-1:0]                SourceD_req_set_i        ;
  //logic  [`KIANA_L2C_BITS-1:0]                SourceD_req_l2cidx_i     ;
  logic  [`KIANA_OP_BITS-1:0]                 SourceD_req_opcode_i     ;
  logic  [`KIANA_SIZE_BITS-1:0]               SourceD_req_size_i       ;
  logic  [`KIANA_SOURCE_BITS-1:0]             SourceD_req_source_i     ;
  logic  [`KIANA_TAG_BITS-1:0]                SourceD_req_tag_i        ;
  logic  [`KIANA_OFFSET_BITS-1:0]             SourceD_req_offset_i     ;
  logic  [`KIANA_PUT_BITS-1:0]                SourceD_req_put_i        ;
  logic  [`KIANA_DATA_BITS-1:0]               SourceD_req_data_i       ;
  logic  [`KIANA_MASK_BITS-1:0]               SourceD_req_mask_i       ;
  logic  [2:0]                          SourceD_req_param_i      ;
  logic                                 SourceD_req_valid_i      ;
  logic                                 SourceD_req_ready_o      ;
  logic  [`KIANA_ADDRESS_BITS-1:0]            SourceD_d_address_o      ;
  logic  [`KIANA_OP_BITS-1:0]                 SourceD_d_opcode_o       ;
  logic  [`KIANA_SIZE_BITS-1:0]               SourceD_d_size_o         ;
  logic  [`KIANA_SOURCE_BITS-1:0]             SourceD_d_source_o       ;
  logic  [`KIANA_DATA_BITS-1:0]               SourceD_d_data_o         ;
  logic  [2:0]                          SourceD_d_param_o        ;
  logic                                 SourceD_d_valid_o        ;
  logic                                 SourceD_d_ready_i        ;
  logic  [`KIANA_PUT_BITS-1:0]                SourceD_pb_pop_index_o   ;
  logic                                 SourceD_pb_pop_valid_o   ;
  logic                                 SourceD_pb_pop_ready_i   ;
  logic  [`KIANA_DATA_BITS-1:0]               SourceD_pb_beat_data_i   ;
  logic  [`KIANA_MASK_BITS-1:0]               SourceD_pb_beat_mask_i   ;
  logic  [`KIANA_WAY_BITS-1:0]                SourceD_bs_radr_way_o    ;
  logic  [`KIANA_SET_BITS-1:0]                SourceD_bs_radr_set_o    ;
  logic  [`KIANA_INNER_MASK_BITS-1:0]         SourceD_bs_radr_mask_o   ;
  logic                                 SourceD_bs_radr_valid_o  ;
  logic                                 SourceD_bs_radr_ready_i  ;
  logic  [`KIANA_L2CACHE_BEATBYTES*8-1:0]     SourceD_bs_rdat_data_i   ;
  logic  [`KIANA_WAY_BITS-1:0]                SourceD_bs_wadr_way_o    ;
  logic  [`KIANA_SET_BITS-1:0]                SourceD_bs_wadr_set_o    ;
  logic  [`KIANA_INNER_MASK_BITS-1:0]         SourceD_bs_wadr_mask_o   ;
  logic                                 SourceD_bs_wadr_valid_o  ;
  logic                                 SourceD_bs_wadr_ready_i  ;
  logic  [`KIANA_L2CACHE_BEATBYTES*8-1:0]     SourceD_bs_wdat_data_o   ;
  logic  [`KIANA_SET_BITS-1:0]                SourceD_a_set_o          ;
  //logic  [`KIANA_L2C_BITS-1:0]                SourceD_a_l2cidx_o       ;
  logic  [`KIANA_OP_BITS-1:0]                 SourceD_a_opcode_o       ;
  logic  [`KIANA_SIZE_BITS-1:0]               SourceD_a_size_o         ;
  logic  [`KIANA_SOURCE_BITS-1:0]             SourceD_a_source_o       ;
  logic  [`KIANA_TAG_BITS-1:0]                SourceD_a_tag_o          ;
  logic  [`KIANA_OFFSET_BITS-1:0]             SourceD_a_offset_o       ;
  logic  [`KIANA_PUT_BITS-1:0]                SourceD_a_put_o          ;
  logic  [`KIANA_DATA_BITS-1:0]               SourceD_a_data_o         ;
  logic  [`KIANA_MASK_BITS-1:0]               SourceD_a_mask_o         ;
  logic  [2:0]                          SourceD_a_param_o        ;
  logic                                 SourceD_a_valid_o        ;
  logic                                 SourceD_a_ready_i        ;
  logic                                 SourceD_mshr_wait_o      ;
  logic                                 SourceD_finish_issue_o   ;
  //above is the SourceD part.
  //Decoupled FullRequest
  logic                                 sinkA_req_ready_i        ;
  logic                                 sinkA_req_valid_o        ;
  //sinkA req part handshake signals
  logic  [`KIANA_SET_BITS-1:0]                sinkA_req_set_o          ;
  //logic  [`KIANA_L2C_BITS-1:0]                sinkA_req_l2cidx_o       ;
  logic  [`KIANA_OP_BITS-1:0]                 sinkA_req_opcode_o       ;
  logic  [`KIANA_SIZE_BITS-1:0]               sinkA_req_size_o         ;
  logic  [`KIANA_SOURCE_BITS-1:0]             sinkA_req_source_o       ;
  logic  [`KIANA_TAG_BITS-1:0]                sinkA_req_tag_o          ;
  logic  [`KIANA_OFFSET_BITS-1:0]             sinkA_req_offset_o       ;
  logic  [`KIANA_PUT_BITS-1:0]                sinkA_req_put_o          ;
  logic  [`KIANA_DATA_BITS-1:0]               sinkA_req_data_o         ;
  logic  [`KIANA_MASK_BITS-1:0]               sinkA_req_mask_o         ;
  logic  [`KIANA_PARAM_BITS-1:0]              sinkA_req_param_o        ;
  //Flipped(Decoupled -TLBundleA_lite   
  logic                                 sinkA_a_ready_o          ;
  logic                                 sinkA_a_valid_i          ;
  //sinkA a part handshake signals
  logic   [`KIANA_OP_BITS-1:0]                sinkA_a_opcode_i         ;
  logic   [`KIANA_SIZE_BITS-1:0]              sinkA_a_size_i           ;
  logic   [`KIANA_SOURCE_BITS-1:0]            sinkA_a_source_i         ;
  logic   [`KIANA_ADDRESS_BITS-1:0]           sinkA_a_address_i        ;
  logic   [`KIANA_MASK_BITS-1:0]              sinkA_a_mask_i           ;
  logic   [`KIANA_DATA_BITS-1:0]              sinkA_a_data_i           ;
  logic   [`KIANA_PARAM_BITS-1:0]             sinkA_a_param_i          ;
  logic                                 sinkA_pb_pop_ready_o     ;
  logic                                 sinkA_pb_pop_valid_i     ;
  logic   [`KIANA_PUT_BITS-1:0]               sinkA_pb_pop_index_i     ;
  logic   [`KIANA_DATA_BITS-1:0]              sinkA_pb_beat_data_o     ;
  logic   [`KIANA_MASK_BITS-1:0]              sinkA_pb_beat_mask_o     ;
  logic                                 sinkA_empty_o            ;
  //above is the sinkA port
  logic   [`KIANA_OP_BITS-1:0]                sinkD_d_opcode_i         ;
  logic   [`KIANA_SOURCE_BITS-1:0]            sinkD_d_source_i         ;
  logic   [`KIANA_DATA_BITS-1:0]              sinkD_d_data_i           ;
  logic                                 sinkD_d_valid_i          ;
  logic                                 sinkD_d_ready_o          ;
  //logic       [`KIANA_PUT_BITS-1:0]            sinkD_put_i            ;
  //logic      [`KIANA_PUT_BITS-1:0]            sinkD_index_o          ;
  logic   [`KIANA_SOURCE_BITS-1:0]            sinkD_source_o           ;
  logic   [`KIANA_OP_BITS-1:0]                sinkD_resp_opcode_o      ;
  logic   [`KIANA_SOURCE_BITS-1:0]            sinkD_resp_source_o      ;
  logic   [`KIANA_DATA_BITS-1:0]              sinkD_resp_data_o        ;
  logic                                 sinkD_resp_valid_o       ;
  //above is the sinkD part
  //write port
  logic                                 dir_write_valid_i        ;
  logic                                 dir_write_ready_o        ;
  logic [`KIANA_WAY_BITS-1:0]                 dir_write_way_i          ;
  //tag is the write data
  logic [`KIANA_TAG_BITS-1:0]                 dir_write_tag_i          ;
  logic [`KIANA_SET_BITS-1:0]                 dir_write_set_i          ;
  //read port
  logic                                 dir_read_valid_i         ;
  logic                                 dir_read_ready_o         ;
  logic [`KIANA_SET_BITS-1:0]                 dir_read_set_i           ;
  //logic [`KIANA_L2C_BITS-1:0]                 dir_read_l2cidx_i        ;
  logic [`KIANA_OP_BITS-1:0]                  dir_read_opcode_i        ;
  logic [`KIANA_SIZE_BITS-1:0]                dir_read_size_i          ;
  logic [`KIANA_SOURCE_BITS-1:0]              dir_read_source_i        ;
  logic [`KIANA_TAG_BITS-1:0]                 dir_read_tag_i           ;
  logic [`KIANA_OFFSET_BITS-1:0]              dir_read_offset_i        ;
  logic [`KIANA_PUT_BITS-1:0]                  dir_read_put_i          ;
  logic [`KIANA_DATA_BITS-1:0]                dir_read_data_i          ;
  logic [`KIANA_MASK_BITS-1:0]                dir_read_mask_i          ;
  logic [`KIANA_PARAM_BITS-1:0]               dir_read_param_i         ;
  //result port
  logic                                 dir_result_valid_o       ;
  logic                                 dir_result_ready_i       ;
  logic [`KIANA_TAG_BITS-1:0]                 dir_result_victim_tag_o  ;
  logic [`KIANA_WAY_BITS-1:0]                 dir_result_way_o         ;
  logic                                 dir_result_hit_o         ;
  logic                                 dir_result_dirty_o       ;
  logic                                 dir_result_flush_o       ;
  logic                                 dir_result_last_flush_o  ;
  logic [`KIANA_SET_BITS-1:0]                 dir_result_set_o         ;
  //logic [`KIANA_L2C_BITS-1:0]                 dir_result_l2cidx_o      ;
  logic [`KIANA_OP_BITS-1:0]                  dir_result_opcode_o      ;
  logic [`KIANA_SIZE_BITS-1:0]                dir_result_size_o        ;
  logic [`KIANA_SOURCE_BITS-1:0]              dir_result_source_o      ;
  logic [`KIANA_TAG_BITS-1:0]                 dir_result_tag_o         ;
  logic [`KIANA_OFFSET_BITS-1:0]              dir_result_offset_o      ;
  logic [`KIANA_PUT_BITS-1:0]                  dir_result_put_o        ;
  logic [`KIANA_DATA_BITS-1:0]                dir_result_data_o        ;
  logic [`KIANA_MASK_BITS-1:0]                dir_result_mask_o        ;
  logic [`KIANA_PARAM_BITS-1:0]               dir_result_param_o       ;
  //ready port
  logic                                 dir_ready_o              ;
  //flush port
  logic                                 dir_flush_i              ;
  //invalidate port
  logic                                 dir_invalidate_i         ;
  //tagmatch port
  logic                                 dir_tag_match_i          ;
  //above is the directory_test port
  logic   [`KIANA_WAY_BITS-1:0]               bank_s_sinkD_adr_way_i     ;
  logic   [`KIANA_SET_BITS-1:0]               bank_s_sinkD_adr_set_i     ;
  logic   [`KIANA_OUTER_MASK_BITS-1:0]        bank_s_sinkD_adr_mask_i    ;
  logic   [`KIANA_L2CACHE_BEATBYTES*8-1:0]    bank_s_sinkD_dat_data_i    ;
  logic                                 bank_s_sinkD_adr_valid_i   ;
  logic                                 bank_s_sinkD_adr_ready_o   ;
  logic   [`KIANA_WAY_BITS-1:0]               bank_s_sourceD_radr_way_i  ;
  logic   [`KIANA_SET_BITS-1:0]               bank_s_sourceD_radr_set_i  ;
  logic   [`KIANA_INNER_MASK_BITS-1:0]        bank_s_sourceD_radr_mask_i ;
  logic  [`KIANA_L2CACHE_BEATBYTES*8-1:0]     bank_s_sourceD_rdat_data_o ;
  logic                                 bank_s_sourceD_radr_valid_i;
  logic                                 bank_s_sourceD_radr_ready_o;
  logic   [`KIANA_WAY_BITS-1:0]               bank_s_sourceD_wadr_way_i  ;
  logic   [`KIANA_SET_BITS-1:0]               bank_s_sourceD_wadr_set_i  ;
  logic   [`KIANA_INNER_MASK_BITS-1:0]        bank_s_sourceD_wadr_mask_i ;
  logic   [`KIANA_L2CACHE_BEATBYTES*8-1:0]    bank_s_sourceD_wdat_data_i ;
  logic                                 bank_s_sourceD_wadr_valid_i;
  logic                                 bank_s_sourceD_wadr_ready_o;
  //above is the banked_store port
  //it is listbuffer class
  logic                                 requests_push_ready_o      ;//data out
  logic                                 requests_push_valid_i      ;//data in
  logic [`KIANA_PUT_BITS-1:0]                 requests_push_index_i      ;//data in
  //logic [`KIANA_PUTLISTS-1:0]                 requests_push_index_req    ;
  logic [`KIANA_DATA_BITS-1:0]                requests_push_data_data_i  ;//data in;
  logic [`KIANA_MASK_BITS-1:0]                requests_push_data_mask_i  ;//data in;
  logic [`KIANA_PUT_BITS-1:0]                 requests_push_data_put_i   ;
  logic [`KIANA_OP_BITS-1:0]                  requests_push_data_opcode_i;
  logic [`KIANA_SOURCE_BITS-1:0]              requests_push_data_source_i;
  logic [`KIANA_PUTLISTS-1:0]                 requests_valid_o           ;//data out
  logic                                 requests_pop_valid_i       ;//data in
  logic [`KIANA_PUT_BITS-1:0]                 requests_pop_data_i        ;//data in
  logic [`KIANA_DATA_BITS-1:0]                requests_data_data_o       ;//data out
  logic [`KIANA_MASK_BITS-1:0]                requests_data_mask_o       ;//data out
  logic [`KIANA_PUT_BITS-1:0]                 requests_data_put_o        ;
  logic [`KIANA_OP_BITS-1:0]                  requests_data_opcode_o     ;
  logic [`KIANA_SOURCE_BITS-1:0]              requests_data_source_o     ;
  //above is the listbuffer port
  //logic allocted signals
  //below is the MSHR instance part
  logic  [`KIANA_MSHRS-1:0             ]      mshr_alloc_valid_i          ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_alloc_hit_i            ;
  logic  [`KIANA_MSHRS*`KIANA_WAY_BITS-1:0   ]      mshr_alloc_way_i            ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_alloc_dirty_i          ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_alloc_flush_i          ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_alloc_last_flush_i     ;
  logic  [`KIANA_MSHRS*`KIANA_SET_BITS-1:0   ]      mshr_alloc_set_i            ;
  //logic [`KIANA_MSHRS*`KIANA_L2C_BITS-1:0  ]      mshr_alloc_l2cidx_i         ;
  logic  [`KIANA_MSHRS*`KIANA_OP_BITS-1:0    ]      mshr_alloc_opcode_i         ;
  logic  [`KIANA_MSHRS*`KIANA_SIZE_BITS-1:0  ]      mshr_alloc_size_i           ;
  logic  [`KIANA_MSHRS*`KIANA_SOURCE_BITS-1:0]      mshr_alloc_source_i         ;
  logic  [`KIANA_MSHRS*`KIANA_TAG_BITS-1:0   ]      mshr_alloc_tag_i            ;
  logic  [`KIANA_MSHRS*`KIANA_OFFSET_BITS-1:0]      mshr_alloc_offset_i         ;
  logic  [`KIANA_MSHRS*`KIANA_PUT_BITS-1:0   ]      mshr_alloc_put_i            ;
  logic  [`KIANA_MSHRS*`KIANA_DATA_BITS-1:0  ]      mshr_alloc_data_i           ;
  logic  [`KIANA_MSHRS*`KIANA_MASK_BITS-1:0  ]      mshr_alloc_mask_i           ;
  logic  [`KIANA_MSHRS*`KIANA_PARAM_BITS-1:0 ]      mshr_alloc_param_i          ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_status_hit_o           ;
  logic  [`KIANA_MSHRS*`KIANA_WAY_BITS-1:0   ]      mshr_status_way_o           ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_status_dirty_o         ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_status_flush_o         ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_status_last_flush_o    ;
  logic  [`KIANA_MSHRS*`KIANA_SET_BITS-1:0   ]      mshr_status_set_o           ;
  //logic  [`KIANA_MSHRS*`KIANA_L2C_BITS-1:0 ]      mshr_status_l2cidx_o        ;
  logic  [`KIANA_MSHRS*`KIANA_OP_BITS-1:0    ]      mshr_status_opcode_o        ;
  logic  [`KIANA_MSHRS*`KIANA_SIZE_BITS-1:0  ]      mshr_status_size_o          ;
  logic  [`KIANA_MSHRS*`KIANA_SOURCE_BITS-1:0]      mshr_status_source_o        ;
  logic  [`KIANA_MSHRS*`KIANA_TAG_BITS-1:0   ]      mshr_status_tag_o           ;
  logic  [`KIANA_MSHRS*`KIANA_OFFSET_BITS-1:0]      mshr_status_offset_o        ;
  logic  [`KIANA_MSHRS*`KIANA_PUT_BITS-1:0   ]      mshr_status_put_o           ;
  logic  [`KIANA_MSHRS*`KIANA_DATA_BITS-1:0  ]      mshr_status_data_o          ;
  logic  [`KIANA_MSHRS*`KIANA_MASK_BITS-1:0  ]      mshr_status_mask_o          ;
  logic  [`KIANA_MSHRS*`KIANA_PARAM_BITS-1:0 ]      mshr_status_param_o         ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_valid_i                ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_wait_i                 ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_mixed_i                ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_a_ready_i     ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_a_valid_o     ;
  logic  [`KIANA_MSHRS*`KIANA_SET_BITS-1:0   ]      mshr_schedule_a_set_o       ;
  //logic  [`KIANA_MSHRS*`KIANA_L2C_BITS-1:0 ]      mshr_schedule_a_l2cidx_o    ;
  logic  [`KIANA_MSHRS*`KIANA_OP_BITS-1:0    ]      mshr_schedule_a_opcode_o    ;
  logic  [`KIANA_MSHRS*`KIANA_SIZE_BITS-1:0  ]      mshr_schedule_a_size_o      ;
  logic  [`KIANA_MSHRS*`KIANA_SOURCE_BITS-1:0]      mshr_schedule_a_source_o    ;
  logic  [`KIANA_MSHRS*`KIANA_TAG_BITS-1:0   ]      mshr_schedule_a_tag_o       ;
  logic  [`KIANA_MSHRS*`KIANA_OFFSET_BITS-1:0]      mshr_schedule_a_offset_o    ;
  logic  [`KIANA_MSHRS*`KIANA_PUT_BITS-1:0   ]      mshr_schedule_a_put_o       ;
  logic  [`KIANA_MSHRS*`KIANA_DATA_BITS-1:0  ]      mshr_schedule_a_data_o      ;
  logic  [`KIANA_MSHRS*`KIANA_MASK_BITS-1:0  ]      mshr_schedule_a_mask_o      ;
  logic  [`KIANA_MSHRS*`KIANA_PARAM_BITS-1:0 ]      mshr_schedule_a_param_o     ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_d_ready_i     ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_d_valid_o     ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_d_hit_o       ;
  logic  [`KIANA_MSHRS*`KIANA_WAY_BITS-1:0   ]      mshr_schedule_d_way_o       ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_d_dirty_o     ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_d_flush_o     ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_d_last_flush_o;
  logic  [`KIANA_MSHRS*`KIANA_SET_BITS-1:0   ]      mshr_schedule_d_set_o       ;
  logic  [`KIANA_MSHRS*`KIANA_OP_BITS-1:0    ]      mshr_schedule_d_opcode_o    ;
  logic  [`KIANA_MSHRS*`KIANA_SIZE_BITS-1:0  ]      mshr_schedule_d_size_o      ;
  logic  [`KIANA_MSHRS*`KIANA_SOURCE_BITS-1:0]      mshr_schedule_d_source_o    ;
  logic  [`KIANA_MSHRS*`KIANA_TAG_BITS-1:0   ]      mshr_schedule_d_tag_o       ;
  logic  [`KIANA_MSHRS*`KIANA_OFFSET_BITS-1:0]      mshr_schedule_d_offset_o    ;
  logic  [`KIANA_MSHRS*`KIANA_PUT_BITS-1:0   ]      mshr_schedule_d_put_o       ;
  logic  [`KIANA_MSHRS*`KIANA_DATA_BITS-1:0  ]      mshr_schedule_d_data_o      ;
  logic  [`KIANA_MSHRS*`KIANA_MASK_BITS-1:0  ]      mshr_schedule_d_mask_o      ;
  logic  [`KIANA_MSHRS*`KIANA_PARAM_BITS-1:0 ]      mshr_schedule_d_param_o     ; 
  logic  [`KIANA_MSHRS*`KIANA_DATA_BITS-1:0  ]      mshr_schedule_data_o        ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_dir_ready_i   ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_schedule_dir_valid_o   ;
  logic  [`KIANA_MSHRS*`KIANA_WAY_BITS-1:0   ]      mshr_schedule_dir_way_o     ;
  logic  [`KIANA_MSHRS*`KIANA_TAG_BITS-1:0   ]      mshr_schedule_dir_data_tag_o;
  logic  [`KIANA_MSHRS*`KIANA_SET_BITS-1:0   ]      mshr_schedule_dir_set_o     ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_merge_valid_i          ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_merge_ready            ;
  logic  [`KIANA_MSHRS*`KIANA_MASK_BITS-1:0  ]      mshr_merge_mask_i           ;
  logic  [`KIANA_MSHRS*`KIANA_DATA_BITS-1:0  ]      mshr_merge_data_i           ;    
  logic  [`KIANA_MSHRS*`KIANA_OP_BITS-1:0    ]      mshr_merge_opcode_i         ;
  logic  [`KIANA_MSHRS*`KIANA_PUT_BITS-1:0   ]      mshr_merge_put_i            ;
  logic  [`KIANA_MSHRS*`KIANA_SOURCE_BITS-1:0]      mshr_merge_source_i         ;
  logic  [`KIANA_MSHRS-1:0             ]      mshr_sinked_valid_i         ;
  logic  [`KIANA_MSHRS*`KIANA_OP_BITS-1:0    ]      mshr_sinked_opcode_i        ;
  logic  [`KIANA_MSHRS*`KIANA_SOURCE_BITS-1:0]      mshr_sinked_source_i        ;
  logic  [`KIANA_MSHRS*`KIANA_DATA_BITS-1:0  ]      mshr_sinked_data_i          ;
  //above is the MSHR part
  //val request = Wire(Decoupled(new FullRequest(params)))
  logic                                 request_ready_i             ;
  logic                                 request_valid_o             ;
  //sourceA req part handshake signals
  logic  [`KIANA_SET_BITS-1:0]                request_set_o               ;
  logic  [`KIANA_L2C_BITS-1:0]                request_l2cidx_o            ;
  logic  [`KIANA_OP_BITS-1:0]                 request_opcode_o            ;
  logic  [`KIANA_SIZE_BITS-1:0]               request_size_o              ;
  logic  [`KIANA_SOURCE_BITS-1:0]             request_source_o            ;
  logic  [`KIANA_TAG_BITS-1:0]                request_tag_o               ;
  logic  [`KIANA_OFFSET_BITS-1:0]             request_offset_o            ;
  logic  [`KIANA_PUT_BITS-1:0]                request_put_o               ;
  logic  [`KIANA_DATA_BITS-1:0]               request_data_o              ;
  logic  [`KIANA_MASK_BITS-1:0]               request_mask_o              ;
  logic  [`KIANA_PARAM_BITS-1:0]              request_param_o             ;
  logic                                  issue_flush_invalidate      ; //init 0
  logic  [`KIANA_MSHRS-1 : 0]                 mshr_request                ;
  //schedule and its definination
  logic                                  schedule_a_ready_i          ;
  logic                                  schedule_a_valid_o          ;
  //logic  schedule part handshake signals
  logic  [`KIANA_SET_BITS-1:0]                 schedule_a_set_o            ;
  //logic  [`KIANA_L2C_BITS-1:0]               schedule_a_l2cidx_o         ;
  logic  [`KIANA_OP_BITS-1:0]                  schedule_a_opcode_o         ;
  logic  [`KIANA_SIZE_BITS-1:0]                schedule_a_size_o           ;
  logic  [`KIANA_SOURCE_BITS-1:0]              schedule_a_source_o         ;
  logic  [`KIANA_TAG_BITS-1:0]                 schedule_a_tag_o            ;
  logic  [`KIANA_OFFSET_BITS-1:0]              schedule_a_offset_o         ;
  logic  [`KIANA_PUT_BITS-1:0]                 schedule_a_put_o            ;
  logic  [`KIANA_DATA_BITS-1:0]                schedule_a_data_o           ;
  logic  [`KIANA_MASK_BITS-1:0]                schedule_a_mask_o           ;
  logic  [`KIANA_PARAM_BITS-1:0]               schedule_a_param_o          ;
  //schedule part d  : Decoupled DirectoryResult_lite
  logic                                  schedule_d_ready_i          ;
  logic                                  schedule_d_valid_o          ;
  //schedule part d handshake signals
  logic                                  schedule_d_hit_o            ;
  logic  [`KIANA_WAY_BITS-1:0]                 schedule_d_way_o            ;
  logic                                  schedule_d_dirty_o          ;
  logic                                  schedule_d_flush_o          ;
  logic                                  schedule_d_last_flush_o     ;
  logic  [`KIANA_SET_BITS-1:0]                 schedule_d_set_o            ;
  //logic  [`KIANA_L2C_BITS-1:0]                 schedule_d_l2cidx_o         ;
  logic  [`KIANA_OP_BITS-1:0]                  schedule_d_opcode_o         ;
  logic  [`KIANA_SIZE_BITS-1:0]                schedule_d_size_o           ;
  logic  [`KIANA_SOURCE_BITS-1:0]              schedule_d_source_o         ;
  logic  [`KIANA_TAG_BITS-1:0]                 schedule_d_tag_o            ;
  logic  [`KIANA_OFFSET_BITS-1:0]              schedule_d_offset_o         ;
  logic  [`KIANA_PUT_BITS-1:0]                 schedule_d_put_o            ;
  logic  [`KIANA_DATA_BITS-1:0]                schedule_d_data_o           ;
  logic  [`KIANA_MASK_BITS-1:0]                schedule_d_mask_o           ;
  logic  [`KIANA_PARAM_BITS-1:0]               schedule_d_param_o          ;
  //schedule  data part   
  logic  [`KIANA_DATA_BITS-1:0]                schedule_data_o             ;
  //logic  schedule dir part
  logic                                  schedule_dir_ready_i        ;
  logic                                  schedule_dir_valid_o        ;
  //schedule part dir handshake signals
  logic  [`KIANA_WAY_BITS-1:0]                 schedule_dir_way_o          ;
  logic  [`KIANA_TAG_BITS-1:0]                 schedule_dir_data_tag_o     ;
  logic  [`KIANA_SET_BITS-1:0]                 schedule_dir_set_o          ;
  logic                                 mshr_free                       ;
  logic                                 mshr_empty                      ;
  logic                                 putbuffer_empty                 ;
  logic                                 invalidate_ready                ;
  logic [`KIANA_MSHRS-1:0]                    mshr_insertOH_zip_mshrs         ;
  logic [`KIANA_PUTLISTS-1:0]                 mshr_validOH                    ;
  logic                                 writebuffer_enq_valid           ;
  logic                                 writebuffer_deq_valid           ;
  logic                                 writebuffer_enq_ready           ;
  logic                                 writebuffer_deq_ready           ;
  logic                                 writebuffer_enq_fire            ;
  logic                                 writebuffer_deq_fire            ;
  logic  [`KIANA_SET_BITS-1:0]                writebuffer_enq_set             ;
  logic  [`KIANA_SET_BITS-1:0]                writebuffer_deq_set             ;
  //logic  [`KIANA_L2C_BITS-1:0]                writebuffer_enq_l2cidx          ;
  //logic  [`KIANA_L2C_BITS-1:0]                writebuffer_deq_l2cidx          ;
  logic  [`KIANA_OP_BITS-1:0]                 writebuffer_enq_opcode          ;
  logic  [`KIANA_OP_BITS-1:0]                 writebuffer_deq_opcode          ;
  logic  [`KIANA_SIZE_BITS-1:0]               writebuffer_enq_size            ;
  logic  [`KIANA_SIZE_BITS-1:0]               writebuffer_deq_size            ;
  logic  [`KIANA_SOURCE_BITS-1:0]             writebuffer_enq_source          ;
  logic  [`KIANA_SOURCE_BITS-1:0]             writebuffer_deq_source          ;
  logic  [`KIANA_TAG_BITS-1:0]                writebuffer_enq_tag             ;
  logic  [`KIANA_TAG_BITS-1:0]                writebuffer_deq_tag             ;
  logic  [`KIANA_OFFSET_BITS-1:0]             writebuffer_enq_offset          ;
  logic  [`KIANA_OFFSET_BITS-1:0]             writebuffer_deq_offset          ;
  logic  [`KIANA_PUT_BITS-1:0]                writebuffer_enq_put             ;
  logic  [`KIANA_PUT_BITS-1:0]                writebuffer_deq_put             ;
  logic  [`KIANA_DATA_BITS-1:0]               writebuffer_enq_data            ;
  logic  [`KIANA_DATA_BITS-1:0]               writebuffer_deq_data            ;
  logic  [`KIANA_MASK_BITS-1:0]               writebuffer_enq_mask            ;
  logic  [`KIANA_MASK_BITS-1:0]               writebuffer_deq_mask            ;
  logic  [`KIANA_PARAM_BITS-1:0]              writebuffer_enq_param           ;
  logic  [`KIANA_PARAM_BITS-1:0]              writebuffer_deq_param           ;
  logic  [writebuffer_data_in_width-1:0]writebuffer_data_in             ;
  logic  [writebuffer_data_in_width-1:0]writebuffer_data_out            ;
  logic  [`KIANA_MSHRS-1:0]                   tagMatches                      ;
  logic  [$clog2(`KIANA_MSHRS)-1:0]           tagMatches2uint                 ;//tagMatches2uint is the one hot code tagMatches to uint code.
  logic                                 is_pending                      ;
  logic                                 alloc                           ;
  logic                                 pending_index                   ;//val pending_index = OHToUInt(Mux(is_pending,tagMatches,0.U))
  logic  [`KIANA_PUTLISTS-1 :0]               mshr_insertOH_init,mshr_insertOH;//width is `KIANA_PUTLISTS-1 + 1.
  logic  [$clog2(`KIANA_PUTLISTS)-1:0]        mshr_insertOH2uint              ;
  logic                                 dir_result_buffer_enq_valid     ;
  logic                                 dir_result_buffer_enq_ready     ;
  logic                                 dir_result_buffer_enq_fire      ;
  logic                                 dir_result_buffer_deq_valid     ;
  logic                                 dir_result_buffer_deq_ready     ;
  logic                                 dir_result_buffer_deq_fire      ;
  logic  [`KIANA_DATA_BITS-1:0]               full_mask                       ;
  logic  [`KIANA_DATA_BITS-1:0]               merge_data                      ;
  logic   [`KIANA_MSHRS-1:0]                   robin_filter                    ;//init 0
  logic  [2*`KIANA_MSHRS-1:0]                 robin_request                   ;
  logic  [$clog2(`KIANA_MSHRS)-1:0]           mshr_select                     ;
  logic  [2*`KIANA_MSHRS:0]                   mshr_selectOH2                  ;//width of its 2*`KIANA_MSHRS -1 +1
  logic  [`KIANA_MSHRS-1:0]                   mshr_selectOH                   ;
  
  //below is the instance IO port
  SourceA   SourceA_dut(
  //.clk                           (clk                    ),
  //.rst_n                         (rst_n                  ),
  .sourceA_req_ready_o           (sourceA_req_ready_o    ),
  .sourceA_req_valid_i           (sourceA_req_valid_i    ),
  .sourceA_req_set_i             (sourceA_req_set_i      ),
  //.sourceA_req_l2cidx_i          (sourceA_req_l2cidx_i   ),
  .sourceA_req_opcode_i          (sourceA_req_opcode_i   ),
  .sourceA_req_size_i            (sourceA_req_size_i     ),
  .sourceA_req_source_i          (sourceA_req_source_i   ),
  .sourceA_req_tag_i             (sourceA_req_tag_i      ),
  .sourceA_req_offset_i          (sourceA_req_offset_i   ),
  //.sourceA_req_put_i             (sourceA_req_put_i      ),
  .sourceA_req_data_i            (sourceA_req_data_i     ),
  .sourceA_req_mask_i            (sourceA_req_mask_i     ),
  //.sourceA_req_param_i           (sourceA_req_param_i    ),
  .sourceA_a_ready_i             (sourceA_a_ready_i      ),
  .sourceA_a_valid_o             (sourceA_a_valid_o      ),
  .sourceA_a_opcode_o            (sourceA_a_opcode_o     ),
  .sourceA_a_size_o              (sourceA_a_size_o       ),
  .sourceA_a_source_o            (sourceA_a_source_o     ),
  .sourceA_a_address_o           (sourceA_a_address_o    ),
  .sourceA_a_mask_o              (sourceA_a_mask_o       ),
  .sourceA_a_data_o              (sourceA_a_data_o       ),
  .sourceA_a_param_o             (sourceA_a_param_o      )
  //above part is the Source A
  );
  
  sourceD sourceD_dut(
  .clk                            (clk                     ),
  .rst_n                          (rst_n                   ),
  .req_from_mem_i                 (SourceD_req_from_mem_i  ),
  .req_hit_i                      (SourceD_req_hit_i       ),
  .req_way_i                      (SourceD_req_way_i       ),
  .req_dirty_i                    (SourceD_req_dirty_i     ),
  .req_flush_i                    (SourceD_req_flush_i     ),
  .req_last_flush_i               (SourceD_req_last_flush_i),
  .req_set_i                      (SourceD_req_set_i       ),
  //.req_l2cidx_i                   (SourceD_req_l2cidx_i    ),
  .req_opcode_i                   (SourceD_req_opcode_i    ),
  .req_size_i                     (SourceD_req_size_i      ),
  .req_source_i                   (SourceD_req_source_i    ),
  .req_tag_i                      (SourceD_req_tag_i       ),
  .req_offset_i                   (SourceD_req_offset_i    ),
  .req_put_i                      (SourceD_req_put_i       ),
  .req_data_i                     (SourceD_req_data_i      ),
  .req_mask_i                     (SourceD_req_mask_i      ),
  .req_param_i                    (SourceD_req_param_i     ),
  .req_valid_i                    (SourceD_req_valid_i     ),
  .req_ready_o                    (SourceD_req_ready_o     ),
  .d_address_o                    (SourceD_d_address_o     ),
  .d_opcode_o                     (SourceD_d_opcode_o      ),
  .d_size_o                       (SourceD_d_size_o        ),
  .d_source_o                     (SourceD_d_source_o      ),
  .d_data_o                       (SourceD_d_data_o        ),
  .d_param_o                      (SourceD_d_param_o       ),
  .d_valid_o                      (SourceD_d_valid_o       ),
  .d_ready_i                      (SourceD_d_ready_i       ),
  .pb_pop_index_o                 (SourceD_pb_pop_index_o  ),
  .pb_pop_valid_o                 (SourceD_pb_pop_valid_o  ),
  //.pb_pop_ready_i                 (SourceD_pb_pop_ready_i  ),
  .pb_beat_data_i                 (SourceD_pb_beat_data_i  ),
  .pb_beat_mask_i                 (SourceD_pb_beat_mask_i  ),
  .bs_radr_way_o                  (SourceD_bs_radr_way_o   ),
  .bs_radr_set_o                  (SourceD_bs_radr_set_o   ),
  .bs_radr_mask_o                 (SourceD_bs_radr_mask_o  ),
  .bs_radr_valid_o                (SourceD_bs_radr_valid_o ),
  .bs_radr_ready_i                (SourceD_bs_radr_ready_i ),
  .bs_rdat_data_i                 (SourceD_bs_rdat_data_i  ),
  .bs_wadr_way_o                  (SourceD_bs_wadr_way_o   ),
  .bs_wadr_set_o                  (SourceD_bs_wadr_set_o   ),
  .bs_wadr_mask_o                 (SourceD_bs_wadr_mask_o  ),
  .bs_wadr_valid_o                (SourceD_bs_wadr_valid_o ),
  .bs_wadr_ready_i                (SourceD_bs_wadr_ready_i ),
  .bs_wdat_data_o                 (SourceD_bs_wdat_data_o  ),
  .a_set_o                        (SourceD_a_set_o         ),
  //.a_l2cidx_o                     (SourceD_a_l2cidx_o      ),
  .a_opcode_o                     (SourceD_a_opcode_o      ),
  .a_size_o                       (SourceD_a_size_o        ),
  .a_source_o                     (SourceD_a_source_o      ),
  .a_tag_o                        (SourceD_a_tag_o         ),
  .a_offset_o                     (SourceD_a_offset_o      ),
  .a_put_o                        (SourceD_a_put_o         ),
  .a_data_o                       (SourceD_a_data_o        ),
  .a_mask_o                       (SourceD_a_mask_o        ),
  .a_param_o                      (SourceD_a_param_o       ),
  .a_valid_o                      (SourceD_a_valid_o       ),
  .a_ready_i                      (SourceD_a_ready_i       ),
  .mshr_wait_o                    (SourceD_mshr_wait_o     ),
  .finish_issue_o                 (SourceD_finish_issue_o  )
  //above is the SourceD part.
  );
  
  sinkA sinkA_dut(
  // Decoupled FullRequest
  .clk                            (clk                     ),
  .rst_n                          (rst_n                   ),
  .sinkA_req_ready_i              (sinkA_req_ready_i       ),
  .sinkA_req_valid_o              (sinkA_req_valid_o       ),
  .sinkA_req_set_o                (sinkA_req_set_o         ),
  //.sinkA_req_l2cidx_o             (sinkA_req_l2cidx_o    ),
  .sinkA_req_opcode_o             (sinkA_req_opcode_o      ),
  .sinkA_req_size_o               (sinkA_req_size_o        ),
  .sinkA_req_source_o             (sinkA_req_source_o      ),
  .sinkA_req_tag_o                (sinkA_req_tag_o         ),
  .sinkA_req_offset_o             (sinkA_req_offset_o      ),
  .sinkA_req_put_o                (sinkA_req_put_o         ),
  .sinkA_req_data_o               (sinkA_req_data_o        ),
  .sinkA_req_mask_o               (sinkA_req_mask_o        ),
  .sinkA_req_param_o              (sinkA_req_param_o       ),
  .sinkA_a_ready_o                (sinkA_a_ready_o         ),
  .sinkA_a_valid_i                (sinkA_a_valid_i         ),
  .sinkA_a_opcode_i               (sinkA_a_opcode_i        ),
  .sinkA_a_size_i                 (sinkA_a_size_i          ),
  .sinkA_a_source_i               (sinkA_a_source_i        ),
  .sinkA_a_address_i              (sinkA_a_address_i       ),
  .sinkA_a_mask_i                 (sinkA_a_mask_i          ),
  .sinkA_a_data_i                 (sinkA_a_data_i          ),
  .sinkA_a_param_i                (sinkA_a_param_i         ),
  .invalidate_ready_i             (invalidate_ready        ),
  .flush_ready_i                  (flush_ready             ),
  .sinkA_pb_pop_ready_o           (sinkA_pb_pop_ready_o    ),
  .sinkA_pb_pop_valid_i           (sinkA_pb_pop_valid_i    ),
  .sinkA_pb_pop_index_i           (sinkA_pb_pop_index_i    ),
  .sinkA_pb_beat_data_o           (sinkA_pb_beat_data_o    ),
  .sinkA_pb_beat_mask_o           (sinkA_pb_beat_mask_o    ),
  .sinkA_empty_o                  (sinkA_empty_o           )
  );
  
  sinkD sinkD_dut(
  .clk                            (clk                     ),
  .rst_n                          (rst_n                   ),
  .d_opcode_i                     (sinkD_d_opcode_i        ),
  .d_source_i                     (sinkD_d_source_i        ),
  .d_data_i                       (sinkD_d_data_i          ),
  .d_valid_i                      (sinkD_d_valid_i         ),
  .d_ready_o                      (sinkD_d_ready_o         ),
  //.put_i                          (sinkD_put_i             ),
  //.index_o                        (sinkD_index_o           ),
  .source_o                       (sinkD_source_o          ),
  .resp_opcode_o                  (sinkD_resp_opcode_o     ),
  .resp_source_o                  (sinkD_resp_source_o     ),
  .resp_data_o                    (sinkD_resp_data_o       ),
  .resp_valid_o                   (sinkD_resp_valid_o      )
  //above is the sinkA part
  );

  directory_test directory_test_dut(
  //write port
  .clk                            (clk                     ),
  .rst_n                          (rst_n                   ),
  .dir_write_valid_i              (dir_write_valid_i       ),
  .dir_write_ready_o              (dir_write_ready_o       ),
  .dir_write_way_i                (dir_write_way_i         ),
  .dir_write_tag_i                (dir_write_tag_i         ),
  .dir_write_set_i                (dir_write_set_i         ),
  .dir_read_valid_i               (dir_read_valid_i        ),
  .dir_read_ready_o               (dir_read_ready_o        ),
  .dir_read_set_i                 (dir_read_set_i          ),
  //.dir_read_l2cidx_i              (dir_read_l2cidx_i      ) ,
  .dir_read_opcode_i              (dir_read_opcode_i       ),
  .dir_read_size_i                (dir_read_size_i         ),
  .dir_read_source_i              (dir_read_source_i       ),
  .dir_read_tag_i                 (dir_read_tag_i          ),
  .dir_read_offset_i              (dir_read_offset_i       ),
  .dir_read_put_i                 (dir_read_put_i          ),
  .dir_read_data_i                (dir_read_data_i         ),
  .dir_read_mask_i                (dir_read_mask_i         ),
  .dir_read_param_i               (dir_read_param_i        ),
  .dir_result_valid_o             (dir_result_valid_o      ),
  .dir_result_ready_i             (dir_result_ready_i      ),
  .dir_result_victim_tag_o        (dir_result_victim_tag_o ),
  .dir_result_way_o               (dir_result_way_o        ) ,
  .dir_result_hit_o               (dir_result_hit_o        ) ,
  .dir_result_dirty_o             (dir_result_dirty_o      ) ,
  .dir_result_flush_o             (dir_result_flush_o      ) ,
  .dir_result_last_flush_o        (dir_result_last_flush_o ) ,
  .dir_result_set_o               (dir_result_set_o        ) ,
  //.dir_result_l2cidx_o            (dir_result_l2cidx_o     ) ,
  .dir_result_opcode_o            (dir_result_opcode_o     ) ,
  .dir_result_size_o              (dir_result_size_o       ) ,
  .dir_result_source_o            (dir_result_source_o     ) ,
  .dir_result_tag_o               (dir_result_tag_o        ) ,
  .dir_result_offset_o            (dir_result_offset_o     ) ,
  .dir_result_put_o               (dir_result_put_o        ) ,
  .dir_result_data_o              (dir_result_data_o       ) ,
  .dir_result_mask_o              (dir_result_mask_o       ) ,
  .dir_result_param_o             (dir_result_param_o      ) ,
  .dir_ready_o                    (dir_ready_o             ) ,
  .dir_flush_i                    (dir_flush_i             ) ,
  .dir_invalidate_i               (dir_invalidate_i        ) ,
  .dir_tag_match_i                (dir_tag_match_i         ) 
  );
  
  
   banked_store  banked_store_dut(
  .clk                            (clk                         ),
  .rst_n                          (rst_n                       ),
  .sinkD_adr_way_i                (bank_s_sinkD_adr_way_i      ),
  .sinkD_adr_set_i                (bank_s_sinkD_adr_set_i      ),
  .sinkD_adr_mask_i               (bank_s_sinkD_adr_mask_i     ),
  .sinkD_dat_data_i               (bank_s_sinkD_dat_data_i     ),
  .sinkD_adr_valid_i              (bank_s_sinkD_adr_valid_i    ),
  .sinkD_adr_ready_o              (bank_s_sinkD_adr_ready_o    ),
  .sourceD_radr_way_i             (bank_s_sourceD_radr_way_i   ),
  .sourceD_radr_set_i             (bank_s_sourceD_radr_set_i   ),
  .sourceD_radr_mask_i            (bank_s_sourceD_radr_mask_i  ),
  .sourceD_rdat_data_o            (bank_s_sourceD_rdat_data_o  ),
  .sourceD_radr_valid_i           (bank_s_sourceD_radr_valid_i ),
  .sourceD_radr_ready_o           (bank_s_sourceD_radr_ready_o ),
  .sourceD_wadr_way_i             (bank_s_sourceD_wadr_way_i   ),
  .sourceD_wadr_set_i             (bank_s_sourceD_wadr_set_i   ),
  .sourceD_wadr_mask_i            (bank_s_sourceD_wadr_mask_i  ),
  .sourceD_wdat_data_i            (bank_s_sourceD_wdat_data_i  ),
  .sourceD_wadr_valid_i           (bank_s_sourceD_wadr_valid_i ),
  .sourceD_wadr_ready_o           (bank_s_sourceD_wadr_ready_o )
  //above is the banked_store port
   );
  
  Listbuffer   Listbuffer_dut(
  // val putbuffer; in fact it is listbuffer class
  .clk                            (clk                          ),
  .rst_n                          (rst_n                        ),
  .List_buffer_push_ready_o       (requests_push_ready_o        ),
  .List_buffer_push_valid_i       (requests_push_valid_i        ),
  .List_buffer_push_index_i       (requests_push_index_i        ),
  .List_buffer_push_data_data_i   (requests_push_data_data_i    ),
  .List_buffer_push_data_mask_i   (requests_push_data_mask_i    ),
  .List_buffer_push_data_put_i    (requests_push_data_put_i     ),
  .List_buffer_push_data_opcode_i (requests_push_data_opcode_i  ),
  .List_buffer_push_data_source_i (requests_push_data_source_i  ),
  .List_buffer_valid_o            (requests_valid_o             ),
  .List_buffer_pop_valid_i        (requests_pop_valid_i         ),
  .List_buffer_pop_data_i         (requests_pop_data_i          ),
  .List_buffer_data_data_o        (requests_data_data_o         ),
  .List_buffer_data_mask_o        (requests_data_mask_o         ),
  .List_buffer_data_put_o         (requests_data_put_o          ),
  .List_buffer_data_opcode_o      (requests_data_opcode_o       ),
  .List_buffer_data_source_o      (requests_data_source_o       )
  //above is the listbuffer port
  );
  //below is the KIANA_MSHRS instance
  genvar p;
  generate
    for(p=0;p<`KIANA_MSHRS;p=p+1)
       begin:MSHR_Gen
          MSHR U_MSHR(
         .clk                            (clk                                                              ),
         .rst_n                          (rst_n                                                            ),
         .mshr_alloc_valid_i             (mshr_alloc_valid_i              [p]                              ),
         .mshr_alloc_hit_i               (mshr_alloc_hit_i                [p]                              ),
         .mshr_alloc_way_i               (mshr_alloc_way_i                [p*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ),
         .mshr_alloc_dirty_i             (mshr_alloc_dirty_i              [p]                              ),
         .mshr_alloc_flush_i             (mshr_alloc_flush_i              [p]                              ),
         .mshr_alloc_last_flush_i        (mshr_alloc_last_flush_i         [p]                              ),
         .mshr_alloc_set_i               (mshr_alloc_set_i                [p*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ),
         //.mshr_alloc_l2cidx_i          (mshr_alloc_l2cidx_i [p*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]                     ),
         .mshr_alloc_opcode_i            (mshr_alloc_opcode_i             [p*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ),
         .mshr_alloc_size_i              (mshr_alloc_size_i               [p*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ),
         .mshr_alloc_source_i            (mshr_alloc_source_i             [p*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ),
         .mshr_alloc_tag_i               (mshr_alloc_tag_i                [p*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ),
         .mshr_alloc_offset_i            (mshr_alloc_offset_i             [p*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ),
         .mshr_alloc_put_i               (mshr_alloc_put_i                [p*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ),
         .mshr_alloc_data_i              (mshr_alloc_data_i               [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ),
         .mshr_alloc_mask_i              (mshr_alloc_mask_i               [p*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ),
         .mshr_alloc_param_i             (mshr_alloc_param_i              [p*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ),
         .mshr_status_hit_o              (mshr_status_hit_o               [p]                              ),
         .mshr_status_way_o              (mshr_status_way_o               [p*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ),
         .mshr_status_dirty_o            (mshr_status_dirty_o             [p]                              ),
         .mshr_status_flush_o            (mshr_status_flush_o             [p]                              ),
         .mshr_status_last_flush_o       (mshr_status_last_flush_o        [p]                              ),
         .mshr_status_set_o              (mshr_status_set_o               [p*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ),
         //.mshr_status_l2cidx_o           (mshr_status_l2cidx_o[p*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]                 ),
         .mshr_status_opcode_o           (mshr_status_opcode_o            [p*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ),
         .mshr_status_size_o             (mshr_status_size_o              [p*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ),
         .mshr_status_source_o           (mshr_status_source_o            [p*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ),
         .mshr_status_tag_o              (mshr_status_tag_o               [p*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ),
         .mshr_status_offset_o           (mshr_status_offset_o            [p*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ),
         .mshr_status_put_o              (mshr_status_put_o               [p*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ),
         .mshr_status_data_o             (mshr_status_data_o              [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ),
         .mshr_status_mask_o             (mshr_status_mask_o              [p*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ),
         .mshr_status_param_o            (mshr_status_param_o             [p*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ),
         .mshr_valid_i                   (mshr_valid_i                    [p]                              ),
         .mshr_wait_i                    (mshr_wait_i                     [p]                              ),
         .mshr_mixed_i                   (mshr_mixed_i                    [p]                              ),
         .mshr_schedule_a_ready_i        (mshr_schedule_a_ready_i         [p]                              ),
         .mshr_schedule_a_valid_o        (mshr_schedule_a_valid_o         [p]                              ),
         .mshr_schedule_a_set_o          (mshr_schedule_a_set_o           [p*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ),
         //.mshr_schedule_a_l2cidx_o       (mshr_schedule_a_l2cidx_o   [p*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]            ),
         .mshr_schedule_a_opcode_o       (mshr_schedule_a_opcode_o        [p*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ),
         .mshr_schedule_a_size_o         (mshr_schedule_a_size_o          [p*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ),
         .mshr_schedule_a_source_o       (mshr_schedule_a_source_o        [p*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ),
         .mshr_schedule_a_tag_o          (mshr_schedule_a_tag_o           [p*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ),
         .mshr_schedule_a_offset_o       (mshr_schedule_a_offset_o        [p*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ),
         .mshr_schedule_a_put_o          (mshr_schedule_a_put_o           [p*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ),
         .mshr_schedule_a_data_o         (mshr_schedule_a_data_o          [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ),
         .mshr_schedule_a_mask_o         (mshr_schedule_a_mask_o          [p*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ),
         .mshr_schedule_a_param_o        (mshr_schedule_a_param_o         [p*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ),
         .mshr_schedule_d_ready_i        (mshr_schedule_d_ready_i         [p]                              ),
         .mshr_schedule_d_valid_o        (mshr_schedule_d_valid_o         [p]                              ),
         .mshr_schedule_d_hit_o          (mshr_schedule_d_hit_o           [p]                              ),
         .mshr_schedule_d_way_o          (mshr_schedule_d_way_o           [p*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ),
         .mshr_schedule_d_dirty_o        (mshr_schedule_d_dirty_o         [p]                              ),
         .mshr_schedule_d_flush_o        (mshr_schedule_d_flush_o         [p]                              ),
         .mshr_schedule_d_last_flush_o   (mshr_schedule_d_last_flush_o    [p]                              ),
         .mshr_schedule_d_set_o          (mshr_schedule_d_set_o           [p*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ),
         //.mshr_schedule_d_l2cidx_o       (mshr_schedule_d_l2cidx_o  [p*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]             ),
         .mshr_schedule_d_opcode_o       (mshr_schedule_d_opcode_o        [p*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ),
         .mshr_schedule_d_size_o         (mshr_schedule_d_size_o          [p*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ),
         .mshr_schedule_d_source_o       (mshr_schedule_d_source_o        [p*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ),
         .mshr_schedule_d_tag_o          (mshr_schedule_d_tag_o           [p*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ),
         .mshr_schedule_d_offset_o       (mshr_schedule_d_offset_o        [p*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ),
         .mshr_schedule_d_put_o          (mshr_schedule_d_put_o           [p*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ),
         .mshr_schedule_d_data_o         (mshr_schedule_d_data_o          [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ),
         .mshr_schedule_d_mask_o         (mshr_schedule_d_mask_o          [p*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ),
         .mshr_schedule_d_param_o        (mshr_schedule_d_param_o         [p*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ),
         .mshr_schedule_data_o           (mshr_schedule_data_o            [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ),
         .mshr_schedule_dir_ready_i      (mshr_schedule_dir_ready_i       [p]                              ),
         .mshr_schedule_dir_valid_o      (mshr_schedule_dir_valid_o       [p]                              ),
         .mshr_schedule_dir_way_o        (mshr_schedule_dir_way_o         [p*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ),
         .mshr_schedule_dir_data_tag_o   (mshr_schedule_dir_data_tag_o    [p*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ),
         .mshr_schedule_dir_set_o        (mshr_schedule_dir_set_o         [p*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ),
         .mshr_merge_valid_i             (mshr_merge_valid_i              [p]                              ),
         .mshr_merge_ready               (mshr_merge_ready                [p]                              ),
         .mshr_merge_mask_i              (mshr_merge_mask_i               [p*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ),
         .mshr_merge_data_i              (mshr_merge_data_i               [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ),
         .mshr_merge_opcode_i            (mshr_merge_opcode_i             [p*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ),
         .mshr_merge_put_i               (mshr_merge_put_i                [p*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ),
         .mshr_merge_source_i            (mshr_merge_source_i             [p*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ),
         .mshr_sinked_valid_i            (mshr_sinked_valid_i             [p]                              ),
         .mshr_sinked_opcode_i           (mshr_sinked_opcode_i            [p*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ),
         .mshr_sinked_source_i           (mshr_sinked_source_i            [p*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ),
         .mshr_sinked_data_i             (mshr_sinked_data_i              [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       )   
         );
        assign  mshr_request             [p]                            = {(sourceA_req_ready_o && mshr_schedule_a_valid_o[p]) || (SourceD_req_ready_o && mshr_schedule_d_valid_o[p]) || (mshr_schedule_dir_valid_o[p] && dir_write_ready_o)};
        assign  mshr_sinked_valid_i      [p]                            = sinkD_resp_valid_o && (sinkD_resp_source_o == p) && sinkD_resp_opcode_o == `ACCESSACKDATA;
        assign  mshr_sinked_opcode_i     [p*`KIANA_OP_BITS+:`KIANA_OP_BITS]         = sinkD_resp_opcode_o;
        assign  mshr_sinked_source_i     [p*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS] = sinkD_resp_source_o;
        assign  mshr_sinked_data_i       [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]     = sinkD_resp_data_o  ;
        assign  mshr_schedule_a_ready_i  [p]                            = sourceA_req_ready_o && (mshr_select == p) && !writebuffer_deq_valid;
        assign  mshr_schedule_d_ready_i  [p]                            = SourceD_req_ready_o && mshr_select == p && requests_valid_o[p];
        assign  mshr_schedule_dir_ready_i[p]                            = dir_write_ready_o && (mshr_select == p);
        assign  mshr_valid_i             [p]                            = requests_valid_o [p];
        assign  mshr_wait_i              [p]                            = SourceD_mshr_wait_o;
        assign  mshr_merge_valid_i       [p]                            = mshr_schedule_d_valid_o[p] && ((requests_data_opcode_o == `PUTFULLDATA) || (requests_data_opcode_o == `PUTPARTIALDATA)) && (mshr_select == p);
        assign  mshr_merge_mask_i        [p*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]     = requests_data_mask_o  ;
        assign  mshr_merge_data_i        [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]     = requests_data_data_o  ;
        assign  mshr_merge_opcode_i      [p*`KIANA_OP_BITS+:`KIANA_OP_BITS]         = requests_data_opcode_o;
        assign  mshr_merge_put_i         [p*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]       = requests_data_put_o   ;
        assign  mshr_merge_source_i      [p*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS] = requests_data_source_o;
        assign  tagMatches               [p]                            = requests_valid_o[p] && (mshr_status_tag_o[p*`KIANA_TAG_BITS+:`KIANA_TAG_BITS] == dir_result_tag_o) && (mshr_status_set_o[p*`KIANA_SET_BITS+:`KIANA_SET_BITS] == dir_result_set_o) && (! dir_result_hit_o);
        assign  mshr_insertOH_zip_mshrs  [p]                            = dir_result_valid_o && alloc && mshr_insertOH[p] && !dir_result_hit_o && !dir_result_flush_o;
        assign  mshr_alloc_valid_i       [p]                            = (mshr_insertOH_zip_mshrs[p])? 1'b1                    : 'b0;
        assign  mshr_alloc_hit_i         [p]                            = (mshr_insertOH_zip_mshrs[p])? dir_result_hit_o        : 'b0;
        assign  mshr_alloc_way_i         [p*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]       = (mshr_insertOH_zip_mshrs[p])? dir_result_way_o        : 'b0;
        assign  mshr_alloc_dirty_i       [p]                            = (mshr_insertOH_zip_mshrs[p])? dir_result_dirty_o      : 'b0;
        assign  mshr_alloc_flush_i       [p]                            = (mshr_insertOH_zip_mshrs[p])? dir_result_flush_o      : 'b0;
        assign  mshr_alloc_last_flush_i  [p]                            = (mshr_insertOH_zip_mshrs[p])? dir_result_last_flush_o : 'b0;
        assign  mshr_alloc_set_i         [p*`KIANA_SET_BITS+:`KIANA_SET_BITS]       = (mshr_insertOH_zip_mshrs[p])? dir_result_set_o        : 'b0;
      //assign  mshr_alloc_l2cidx_i     [p*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]         = (mshr_insertOH_zip_mshrs[p])? dir_result_l2cidx_o     : 'b0;
        assign  mshr_alloc_opcode_i      [p*`KIANA_OP_BITS+:`KIANA_OP_BITS]         = (mshr_insertOH_zip_mshrs[p])? dir_result_opcode_o     : 'b0;
        assign  mshr_alloc_size_i        [p*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]     = (mshr_insertOH_zip_mshrs[p])? dir_result_size_o       : 'b0;
        assign  mshr_alloc_source_i      [p*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS] = (mshr_insertOH_zip_mshrs[p])? dir_result_source_o     : 'b0;
        assign  mshr_alloc_tag_i         [p*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]       = (mshr_insertOH_zip_mshrs[p])? dir_result_tag_o        : 'b0;
        assign  mshr_alloc_offset_i      [p*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS] = (mshr_insertOH_zip_mshrs[p])? dir_result_offset_o     : 'b0;
        assign  mshr_alloc_put_i         [p*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]       = (mshr_insertOH_zip_mshrs[p])? dir_result_put_o        : 'b0;
        assign  mshr_alloc_data_i        [p*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]     = (mshr_insertOH_zip_mshrs[p])? dir_result_data_o       : 'b0;
        assign  mshr_alloc_mask_i        [p*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]     = (mshr_insertOH_zip_mshrs[p])? dir_result_mask_o       : 'b0;
        assign  mshr_alloc_param_i       [p*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]   = (mshr_insertOH_zip_mshrs[p])? dir_result_param_o      : 'b0;
        assign  mshr_mixed_i             [p]                            = dir_result_valid_o && tagMatches2uint == p  && (dir_result_opcode_o != mshr_status_opcode_o[p*`KIANA_OP_BITS+:`KIANA_OP_BITS]);
       end        
  endgenerate
  
  
  assign sche_out_a_valid_o           =  sourceA_a_valid_o         ;
  assign sche_out_a_opcode_o          =  sourceA_a_opcode_o        ;
  assign sche_out_a_size_o            =  sourceA_a_size_o          ;
  assign sche_out_a_source_o          =  sourceA_a_source_o        ;
  assign sche_out_a_addresss_o        =  sourceA_a_address_o       ;
  assign sche_out_a_mask_o            =  sourceA_a_mask_o          ;
  assign sche_out_a_data_o            =  sourceA_a_data_o          ;
  assign sche_out_a_param_o           =  sourceA_a_param_o         ;
  assign sourceA_a_ready_i            =  sche_out_a_ready_i        ;
  //  io.out_a.valid := sourceA.io.a.valid 
  //  io.out_a.bits:=sourceA.io.a.bits
  //  sourceA.io.a.ready:=io.out_a.ready
  
  assign sinkA_pb_pop_valid_i         =  SourceD_pb_pop_valid_o    ;
  assign sinkA_pb_pop_index_i         =  SourceD_pb_pop_index_o    ;
  assign SourceD_pb_pop_ready_i       =  sinkA_pb_pop_ready_o      ;
    //sourceD.io.pb_pop<>sinkA.io.pb_pop
  
  assign SourceD_pb_beat_data_i       =  sinkA_pb_beat_data_o      ;
  assign SourceD_pb_beat_mask_i       =  sinkA_pb_beat_mask_o      ;
    //sourceD.io.pb_beat<>sinkA.io.pb_beat
  assign sinkD_d_opcode_i             =  sche_out_d_opcode_i       ;
  assign sinkD_d_source_i             =  sche_out_d_source_i       ;
  assign sinkD_d_data_i               =  sche_out_d_data_i         ;
  assign sinkD_d_valid_i              =  sche_out_d_valid_i        ;
  //  sinkD.io.d.bits:=io.out_d.bits
  //  sinkD.io.d.valid:=io.out_d.valid
  
  assign sche_out_d_ready_o           =  sinkD_d_ready_o           ;

  assign finish_issue_o               =  SourceD_finish_issue_o    ;
  //  io.out_d.ready:=sinkD.io.d.ready
  always_ff @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          issue_flush_invalidate <= 1'b0;
        end
      else if(request_ready_i && request_valid_o && request_opcode_o==`HINT)
        begin
          issue_flush_invalidate <= 1'b1;
        end
      else if(SourceD_finish_issue_o)
        begin
          issue_flush_invalidate <= 1'b0;
        end
      else 
        begin
          issue_flush_invalidate <= issue_flush_invalidate;
        end
    end
  
  //sinkA a part handshake signals
  assign   sinkA_a_opcode_i      =      sche_in_a_opcode_i             ;
  assign   sinkA_a_size_i        =      sche_in_a_size_i               ;
  assign   sinkA_a_source_i      =      sche_in_a_source_i             ;
  assign   sinkA_a_address_i     =      sche_in_a_addresss_i           ;
  assign   sinkA_a_mask_i        =      sche_in_a_mask_i               ;
  assign   sinkA_a_data_i        =      sche_in_a_data_i               ;
  assign   sinkA_a_param_i       =      sche_in_a_param_i              ;
  assign   sinkA_a_valid_i       =      sche_in_a_valid_i              ;
  
  assign   sche_in_a_ready_o     =      sinkA_a_ready_o                ;
  assign   sche_in_d_valid_o     =      SourceD_d_valid_o              ;
  assign   sche_in_d_address_o   =      SourceD_d_address_o            ;
  assign   sche_in_d_opcode_o    =      SourceD_d_opcode_o             ;
  assign   sche_in_d_size_o      =      SourceD_d_size_o               ;
  assign   sche_in_d_source_o    =      SourceD_d_source_o             ;
  assign   sche_in_d_data_o      =      SourceD_d_data_o               ;
  assign   sche_in_d_param_o     =      SourceD_d_param_o              ;
  assign   SourceD_d_ready_i     =      sche_in_d_ready_i              ;
  
  assign robin_request  = {mshr_request, mshr_request & robin_filter};
  assign mshr_selectOH2 = (~((robin_request | robin_request << 1) | ((robin_request | robin_request << 1) << 2)) <<1 ) & robin_request; //only if robin_request width == 4bits
  //  val mshr_selectOH2 = (~(leftOR(robin_request) << 1)).asUInt() & robin_request
  assign mshr_selectOH  = mshr_selectOH2[2*`KIANA_MSHRS-1:`KIANA_MSHRS] | mshr_selectOH2[`KIANA_MSHRS-1:0];
  
   one2bin #(
   .ONE_WIDTH (`KIANA_MSHRS),
   .BIN_WIDTH ($clog2(`KIANA_MSHRS))
   )U0_one2bin
    (
    .oh ( mshr_selectOH ) ,
    .bin( mshr_select   )     
    );
  
  always_comb
    begin
      case(mshr_selectOH)
      4'b0001:
        begin
          schedule_a_ready_i       <=   mshr_schedule_a_ready_i         [0]                              ;
          schedule_a_valid_o       <=   mshr_schedule_a_valid_o         [0]                              ;
          schedule_a_set_o         <=   mshr_schedule_a_set_o           [0*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
  //        schedule_a_l2cidx_o    <=   mshr_schedule_a_l2cidx_o        [0*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]         ;
          schedule_a_opcode_o      <=   mshr_schedule_a_opcode_o        [0*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ;
          schedule_a_size_o        <=   mshr_schedule_a_size_o          [0*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ;
  //        schedule_a_source_o    <=   mshr_schedule_a_source_o        [0*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ;
          schedule_a_tag_o         <=   mshr_schedule_a_tag_o           [0*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_a_offset_o      <=   mshr_schedule_a_offset_o        [0*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ;
          schedule_a_put_o         <=   mshr_schedule_a_put_o           [0*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ;
          schedule_a_data_o        <=   mshr_schedule_a_data_o          [0*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_a_mask_o        <=   mshr_schedule_a_mask_o          [0*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ;
          schedule_a_param_o       <=   mshr_schedule_a_param_o         [0*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ;
          schedule_d_ready_i       <=   mshr_schedule_d_ready_i         [0]                              ;
          schedule_d_valid_o       <=   mshr_schedule_d_valid_o         [0]                              ;
          schedule_d_hit_o         <=   mshr_schedule_d_hit_o           [0]                              ;
          schedule_d_way_o         <=   mshr_schedule_d_way_o           [0*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ;
          schedule_d_dirty_o       <=   mshr_schedule_d_dirty_o         [0]                              ;
          schedule_d_flush_o       <=   mshr_schedule_d_flush_o         [0]                              ;
          schedule_d_last_flush_o  <=   mshr_schedule_d_last_flush_o    [0]                              ;
          schedule_d_set_o         <=   mshr_schedule_d_set_o           [0*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
  //        schedule_d_l2cidx_o    <=   mshr_schedule_d_l2cidx_o        [0*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]         ;
          schedule_d_opcode_o      <=   mshr_schedule_d_opcode_o        [0*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ;
          schedule_d_size_o        <=   mshr_schedule_d_size_o          [0*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ;
          schedule_d_source_o      <=   mshr_schedule_d_source_o        [0*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ;
          schedule_d_tag_o         <=   mshr_schedule_d_tag_o           [0*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_d_offset_o      <=   mshr_schedule_d_offset_o        [0*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ;
          schedule_d_put_o         <=   mshr_schedule_d_put_o           [0*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ;
          schedule_d_data_o        <=   mshr_schedule_d_data_o          [0*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_d_mask_o        <=   mshr_schedule_d_mask_o          [0*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ;
          schedule_d_param_o       <=   mshr_schedule_d_param_o         [0*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ;
          schedule_data_o          <=   mshr_schedule_data_o            [0*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_dir_ready_i     <=   mshr_schedule_dir_ready_i       [0]                              ;
          schedule_dir_valid_o     <=   mshr_schedule_dir_valid_o       [0]                              ;
          schedule_dir_way_o       <=   mshr_schedule_dir_way_o         [0*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ;
          schedule_dir_data_tag_o  <=   mshr_schedule_dir_data_tag_o    [0*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_dir_set_o       <=   mshr_schedule_dir_set_o         [0*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
        end
      4'b0010:
        begin
          schedule_a_ready_i       <=   mshr_schedule_a_ready_i         [1]                              ;
          schedule_a_valid_o       <=   mshr_schedule_a_valid_o         [1]                              ;
          schedule_a_set_o         <=   mshr_schedule_a_set_o           [1*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
  //        schedule_a_l2cidx_o    <=   mshr_schedule_a_l2cidx_o        [1*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]         ;
          schedule_a_opcode_o      <=   mshr_schedule_a_opcode_o        [1*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ;
          schedule_a_size_o        <=   mshr_schedule_a_size_o          [1*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ;
  //        schedule_a_source_o    <=   mshr_schedule_a_source_o        [1*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ;
          schedule_a_tag_o         <=   mshr_schedule_a_tag_o           [1*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_a_offset_o      <=   mshr_schedule_a_offset_o        [1*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ;
          schedule_a_put_o         <=   mshr_schedule_a_put_o           [1*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ;
          schedule_a_data_o        <=   mshr_schedule_a_data_o          [1*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_a_mask_o        <=   mshr_schedule_a_mask_o          [1*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ;
          schedule_a_param_o       <=   mshr_schedule_a_param_o         [1*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ;
          schedule_d_ready_i       <=   mshr_schedule_d_ready_i         [1]                              ;
          schedule_d_valid_o       <=   mshr_schedule_d_valid_o         [1]                              ;
          schedule_d_hit_o         <=   mshr_schedule_d_hit_o           [1]                              ;
          schedule_d_way_o         <=   mshr_schedule_d_way_o           [1*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ;
          schedule_d_dirty_o       <=   mshr_schedule_d_dirty_o         [1]                              ;
          schedule_d_flush_o       <=   mshr_schedule_d_flush_o         [1]                              ;
          schedule_d_last_flush_o  <=   mshr_schedule_d_last_flush_o    [1]                              ;
          schedule_d_set_o         <=   mshr_schedule_d_set_o           [1*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
  //        schedule_d_l2cidx_o    <=   mshr_schedule_d_l2cidx_o        [1*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]         ;
          schedule_d_opcode_o      <=   mshr_schedule_d_opcode_o        [1*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ;
          schedule_d_size_o        <=   mshr_schedule_d_size_o          [1*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ;
          schedule_d_source_o      <=   mshr_schedule_d_source_o        [1*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ;
          schedule_d_tag_o         <=   mshr_schedule_d_tag_o           [1*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_d_offset_o      <=   mshr_schedule_d_offset_o        [1*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ;
          schedule_d_put_o         <=   mshr_schedule_d_put_o           [1*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ;
          schedule_d_data_o        <=   mshr_schedule_d_data_o          [1*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_d_mask_o        <=   mshr_schedule_d_mask_o          [1*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ;
          schedule_d_param_o       <=   mshr_schedule_d_param_o         [1*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ;
          schedule_data_o          <=   mshr_schedule_data_o            [1*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_dir_ready_i     <=   mshr_schedule_dir_ready_i       [1]                              ;
          schedule_dir_valid_o     <=   mshr_schedule_dir_valid_o       [1]                              ;
          schedule_dir_way_o       <=   mshr_schedule_dir_way_o         [1*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ;
          schedule_dir_data_tag_o  <=   mshr_schedule_dir_data_tag_o    [1*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_dir_set_o       <=   mshr_schedule_dir_set_o         [1*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
        end
      4'b0100:    
        begin
          schedule_a_ready_i       <=   mshr_schedule_a_ready_i         [2]                              ;
          schedule_a_valid_o       <=   mshr_schedule_a_valid_o         [2]                              ;
          schedule_a_set_o         <=   mshr_schedule_a_set_o           [2*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
  //        schedule_a_l2cidx_o    <=   mshr_schedule_a_l2cidx_o        [2*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]              ;
          schedule_a_opcode_o      <=   mshr_schedule_a_opcode_o        [2*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ;
          schedule_a_size_o        <=   mshr_schedule_a_size_o          [2*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ;
  //        schedule_a_source_o    <=   mshr_schedule_a_source_o        [2*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]     ;
          schedule_a_tag_o         <=   mshr_schedule_a_tag_o           [2*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_a_offset_o      <=   mshr_schedule_a_offset_o        [2*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ;
          schedule_a_put_o         <=   mshr_schedule_a_put_o           [2*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ;
          schedule_a_data_o        <=   mshr_schedule_a_data_o          [2*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_a_mask_o        <=   mshr_schedule_a_mask_o          [2*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ;
          schedule_a_param_o       <=   mshr_schedule_a_param_o         [2*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ;
          schedule_d_ready_i       <=   mshr_schedule_d_ready_i         [2]                              ;
          schedule_d_valid_o       <=   mshr_schedule_d_valid_o         [2]                              ;
          schedule_d_hit_o         <=   mshr_schedule_d_hit_o           [2]                              ;
          schedule_d_way_o         <=   mshr_schedule_d_way_o           [2*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ;
          schedule_d_dirty_o       <=   mshr_schedule_d_dirty_o         [2]                              ;
          schedule_d_flush_o       <=   mshr_schedule_d_flush_o         [2]                              ;
          schedule_d_last_flush_o  <=   mshr_schedule_d_last_flush_o    [2]                              ;
          schedule_d_set_o         <=   mshr_schedule_d_set_o           [2*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
  //        schedule_d_l2cidx_o    <=   mshr_schedule_d_l2cidx_o        [2*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]               ;
          schedule_d_opcode_o      <=   mshr_schedule_d_opcode_o        [2*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ;
          schedule_d_size_o        <=   mshr_schedule_d_size_o          [2*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ;
          schedule_d_source_o      <=   mshr_schedule_d_source_o        [2*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ;
          schedule_d_tag_o         <=   mshr_schedule_d_tag_o           [2*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_d_offset_o      <=   mshr_schedule_d_offset_o        [2*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ;
          schedule_d_put_o         <=   mshr_schedule_d_put_o           [2*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ;
          schedule_d_data_o        <=   mshr_schedule_d_data_o          [2*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_d_mask_o        <=   mshr_schedule_d_mask_o          [2*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ;
          schedule_d_param_o       <=   mshr_schedule_d_param_o         [2*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ;
          schedule_data_o          <=   mshr_schedule_data_o            [2*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_dir_ready_i     <=   mshr_schedule_dir_ready_i       [2]                              ;
          schedule_dir_valid_o     <=   mshr_schedule_dir_valid_o       [2]                              ;
          schedule_dir_way_o       <=   mshr_schedule_dir_way_o         [2*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ;
          schedule_dir_data_tag_o  <=   mshr_schedule_dir_data_tag_o    [2*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_dir_set_o       <=   mshr_schedule_dir_set_o         [2*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
        end
      4'b1000:
        begin
          schedule_a_ready_i       <=   mshr_schedule_a_ready_i         [3]                              ;
          schedule_a_valid_o       <=   mshr_schedule_a_valid_o         [3]                              ;
          schedule_a_set_o         <=   mshr_schedule_a_set_o           [3*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
  //        schedule_a_l2cidx_o    <=   mshr_schedule_a_l2cidx_o        [3*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]         ;
          schedule_a_opcode_o      <=   mshr_schedule_a_opcode_o        [3*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ;
          schedule_a_size_o        <=   mshr_schedule_a_size_o          [3*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ;
  //        schedule_a_source_o    <=   mshr_schedule_a_source_o        [3*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ;
          schedule_a_tag_o         <=   mshr_schedule_a_tag_o           [3*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_a_offset_o      <=   mshr_schedule_a_offset_o        [3*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ;
          schedule_a_put_o         <=   mshr_schedule_a_put_o           [3*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ;
          schedule_a_data_o        <=   mshr_schedule_a_data_o          [3*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_a_mask_o        <=   mshr_schedule_a_mask_o          [3*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ;
          schedule_a_param_o       <=   mshr_schedule_a_param_o         [3*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ;
          schedule_d_ready_i       <=   mshr_schedule_d_ready_i         [3]                              ;
          schedule_d_valid_o       <=   mshr_schedule_d_valid_o         [3]                              ;
          schedule_d_hit_o         <=   mshr_schedule_d_hit_o           [3]                              ;
          schedule_d_way_o         <=   mshr_schedule_d_way_o           [3*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ;
          schedule_d_dirty_o       <=   mshr_schedule_d_dirty_o         [3]                              ;
          schedule_d_flush_o       <=   mshr_schedule_d_flush_o         [3]                              ;
          schedule_d_last_flush_o  <=   mshr_schedule_d_last_flush_o    [3]                              ;
          schedule_d_set_o         <=   mshr_schedule_d_set_o           [3*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
  //        schedule_d_l2cidx_o    <=   mshr_schedule_d_l2cidx_o        [3*`KIANA_L2C_BITS+:`KIANA_L2C_BITS]               ;
          schedule_d_opcode_o      <=   mshr_schedule_d_opcode_o        [3*`KIANA_OP_BITS+:`KIANA_OP_BITS]           ;
          schedule_d_size_o        <=   mshr_schedule_d_size_o          [3*`KIANA_SIZE_BITS+:`KIANA_SIZE_BITS]       ;
          schedule_d_source_o      <=   mshr_schedule_d_source_o        [3*`KIANA_SOURCE_BITS+:`KIANA_SOURCE_BITS]   ;
          schedule_d_tag_o         <=   mshr_schedule_d_tag_o           [3*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_d_offset_o      <=   mshr_schedule_d_offset_o        [3*`KIANA_OFFSET_BITS+:`KIANA_OFFSET_BITS]   ;
          schedule_d_put_o         <=   mshr_schedule_d_put_o           [3*`KIANA_PUT_BITS+:`KIANA_PUT_BITS]         ;
          schedule_d_data_o        <=   mshr_schedule_d_data_o          [3*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_d_mask_o        <=   mshr_schedule_d_mask_o          [3*`KIANA_MASK_BITS+:`KIANA_MASK_BITS]       ;
          schedule_d_param_o       <=   mshr_schedule_d_param_o         [3*`KIANA_PARAM_BITS+:`KIANA_PARAM_BITS]     ;
          schedule_data_o          <=   mshr_schedule_data_o            [3*`KIANA_DATA_BITS+:`KIANA_DATA_BITS]       ;
          schedule_dir_ready_i     <=   mshr_schedule_dir_ready_i       [3]                              ;
          schedule_dir_valid_o     <=   mshr_schedule_dir_valid_o       [3]                              ;
          schedule_dir_way_o       <=   mshr_schedule_dir_way_o         [3*`KIANA_WAY_BITS+:`KIANA_WAY_BITS]         ;
          schedule_dir_data_tag_o  <=   mshr_schedule_dir_data_tag_o    [3*`KIANA_TAG_BITS+:`KIANA_TAG_BITS]         ;
          schedule_dir_set_o       <=   mshr_schedule_dir_set_o         [3*`KIANA_SET_BITS+:`KIANA_SET_BITS]         ;
        end
      default:
        begin
          schedule_a_ready_i       <=   'b0 ;
          schedule_a_valid_o       <=   'b0 ;
          schedule_a_set_o         <=   'b0 ;
  //        schedule_a_l2cidx_o    <=   'b0 ;
          schedule_a_opcode_o      <=   'b0 ;
          schedule_a_size_o        <=   'b0 ;
  //        schedule_a_source_o    <=   'b0 ;
          schedule_a_tag_o         <=   'b0 ;
          schedule_a_offset_o      <=   'b0 ;
          schedule_a_put_o         <=   'b0 ;
          schedule_a_data_o        <=   'b0 ;
          schedule_a_mask_o        <=   'b0 ;
          schedule_a_param_o       <=   'b0 ;
          schedule_d_ready_i       <=   'b0 ;
          schedule_d_valid_o       <=   'b0 ;
          schedule_d_hit_o         <=   'b0 ;
          schedule_d_way_o         <=   'b0 ;
          schedule_d_dirty_o       <=   'b0 ;
          schedule_d_flush_o       <=   'b0 ;
          schedule_d_last_flush_o  <=   'b0 ;
          schedule_d_set_o         <=   'b0 ;
  //        schedule_d_l2cidx_o    <=   'b0 ;
          schedule_d_opcode_o      <=   'b0 ;
          schedule_d_size_o        <=   'b0 ;
          schedule_d_source_o      <=   'b0 ;
          schedule_d_tag_o         <=   'b0 ;
          schedule_d_offset_o      <=   'b0 ;
          schedule_d_put_o         <=   'b0 ;
          schedule_d_data_o        <=   'b0 ;
          schedule_d_mask_o        <=   'b0 ;
          schedule_d_param_o       <=   'b0 ;
          schedule_data_o          <=   'b0 ;
          schedule_dir_ready_i     <=   'b0 ;
          schedule_dir_valid_o     <=   'b0 ;
          schedule_dir_way_o       <=   'b0 ;
          schedule_dir_data_tag_o  <=   'b0 ;
          schedule_dir_set_o       <=   'b0 ;
        end
          endcase
    end
  // val schedule    = Mux1H (mshr_selectOH, mshrs.map(_.io.schedule))
  //  sinkD.io.way := VecInit(mshrs.map(_.io.status.way))(sinkD.io.source)
  //  sinkD.io.set := VecInit(mshrs.map(_.io.status.set))(sinkD.io.source)
  //  sinkD.io.opcode := VecInit(mshrs.map(_.io.status.opcode))(sinkD.io.source)
  //  sinkD.io.put := VecInit(mshrs.map(_.io.status.put))(sinkD.io.source)
  //  sinkD.io.sche_dir_fire.valid := schedule.dir.fire
  //  sinkD.io.sche_dir_fire.bits :=mshr_select
  //  no need above 
  
  always_ff @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        robin_filter <= 'b0;
      else if( |mshr_request )
        begin
          robin_filter <= ~((mshr_selectOH| (mshr_selectOH >> 1)) | ((mshr_selectOH| (mshr_selectOH >> 1)) >> 2));//only if mshr_selectOH width is 4.
        end
    end
  
  always_comb
    begin
      schedule_a_source_o = mshr_select;
    end
  
  assign   writebuffer_enq_set    =    SourceD_a_set_o                ;
  assign   writebuffer_enq_mask   =    SourceD_a_mask_o               ;
  assign   writebuffer_enq_param  =    SourceD_a_param_o              ;
  assign   writebuffer_enq_data   =    SourceD_a_data_o               ;
  assign   writebuffer_enq_put    =    SourceD_a_put_o                ;
  assign   writebuffer_enq_offset =    SourceD_a_offset_o             ;
  assign   writebuffer_enq_tag    =    SourceD_a_tag_o                ;
  assign   writebuffer_enq_source =    SourceD_a_source_o             ;
  assign   writebuffer_enq_size   =    SourceD_a_size_o               ;
  assign   writebuffer_enq_opcode =    SourceD_a_opcode_o             ;
  //assign   writebuffer_enq_l2cidx =    SourceD_a_l2cidx_o             ;
  
  assign  writebuffer_enq_fire  =  writebuffer_enq_valid & writebuffer_enq_ready     ;
  assign  writebuffer_deq_fire  =  writebuffer_deq_valid & writebuffer_deq_ready     ;
  assign  writebuffer_enq_valid =  SourceD_a_valid_o                                 ;
  assign  writebuffer_deq_ready = sourceA_req_ready_o                                ;
  
  assign writebuffer_data_in    = { // writebuffer_data_in_width = `KIANA_SET_BITS + `KIANA_L2C_BITS + `KIANA_OP_BITS + `KIANA_SIZE_BITS + `KIANA_SOURCE_BITS + `KIANA_TAG_BITS +  `KIANA_OFFSET_BITS + `KIANA_PUT_BITS + `KIANA_DATA_BITS + `KIANA_MASK_BITS + `KIANA_PARAM_BITS
  writebuffer_enq_set   ,        //writebuffer_data_in [writebuffer_data_in_width-1-:`KIANA_SET_BITS]
  //writebuffer_enq_l2cidx,        //writebuffer_data_in [writebuffer_data_in_width-1-`KIANA_SET_BITS-:`KIANA_L2C_BITS]
  writebuffer_enq_opcode,        //writebuffer_data_in [writebuffer_data_in_width-1-`KIANA_SET_BITS-`KIANA_L2C_BITS-:`KIANA_OP_BITS]
  writebuffer_enq_size  ,        //writebuffer_data_in [writebuffer_data_in_width-1-`KIANA_SET_BITS-`KIANA_L2C_BITS-`KIANA_OP_BITS-:`KIANA_SIZE_BITS]
  writebuffer_enq_source,        //writebuffer_data_in [`KIANA_PARAM_BITS-1+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+`KIANA_TAG_BITS+:`KIANA_SOURCE_BITS]
  writebuffer_enq_tag   ,        //writebuffer_data_in [`KIANA_PARAM_BITS-1+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+:`KIANA_TAG_BITS]
  writebuffer_enq_offset,        //writebuffer_data_in [`KIANA_PARAM_BITS-1+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+:`KIANA_OFFSET_BITS]
  writebuffer_enq_put   ,        //writebuffer_data_in [`KIANA_PARAM_BITS-1+`KIANA_MASK_BITS+`KIANA_DATA_BITS+:`KIANA_PUT_BITS]
  writebuffer_enq_data  ,        //writebuffer_data_in [`KIANA_PARAM_BITS-1+`KIANA_MASK_BITS+:`KIANA_DATA_BITS]
  writebuffer_enq_mask  ,        //writebuffer_data_in [`KIANA_PARAM_BITS-1+:`KIANA_MASK_BITS]
  writebuffer_enq_param          //writebuffer_data_in [0+:`KIANA_PARAM_BITS]
  };
  
  
  /*stream_fifo_flow_true*/stream_fifo_useSRAM #(
  .DATA_WIDTH (writebuffer_data_in_width),
  .FIFO_DEPTH (8)
  )
  U_stream_fifo_flow_true(
  .clk      (clk      ),
  .rst_n    (rst_n    ),
  .w_ready_o(writebuffer_enq_ready), // !full
  .w_valid_i(writebuffer_enq_fire) , 
  .w_data_i (writebuffer_data_in ) ,
  .r_valid_o(writebuffer_deq_valid), // non empty
  .r_ready_i(writebuffer_deq_fire) ,
  .r_data_o (writebuffer_data_out )
  );
  assign  writebuffer_deq_set    = writebuffer_data_out [writebuffer_data_in_width-1-:`KIANA_SET_BITS];
  //assign  writebuffer_deq_l2cidx = writebuffer_data_out [writebuffer_data_in_width-1-`KIANA_SET_BITS-:`KIANA_L2C_BITS];
  //assign  writebuffer_deq_l2cidx = 0;
  assign  writebuffer_deq_opcode = writebuffer_data_out [writebuffer_data_in_width-1-`KIANA_SET_BITS-`KIANA_L2C_BITS-:`KIANA_OP_BITS];
  assign  writebuffer_deq_size   = writebuffer_data_out [writebuffer_data_in_width-1-`KIANA_SET_BITS-`KIANA_L2C_BITS-`KIANA_OP_BITS-:`KIANA_SIZE_BITS];
  assign  writebuffer_deq_source = writebuffer_data_out [`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+`KIANA_TAG_BITS+:`KIANA_SOURCE_BITS];
  assign  writebuffer_deq_tag    = writebuffer_data_out [`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+:`KIANA_TAG_BITS];
  assign  writebuffer_deq_offset = writebuffer_data_out [`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+:`KIANA_OFFSET_BITS];
  assign  writebuffer_deq_put    = writebuffer_data_out [`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+:`KIANA_PUT_BITS];
  assign  writebuffer_deq_data   = writebuffer_data_out [`KIANA_PARAM_BITS+`KIANA_MASK_BITS+:`KIANA_DATA_BITS];
  assign  writebuffer_deq_mask   = writebuffer_data_out [`KIANA_PARAM_BITS+:`KIANA_MASK_BITS];
  assign  writebuffer_deq_param  = writebuffer_data_out [0+:`KIANA_PARAM_BITS];
  assign    sourceA_req_set_i        = writebuffer_deq_valid ? writebuffer_deq_set    :  schedule_a_set_o          ;
  //assign    sourceA_req_l2cidx_i     = writebuffer_deq_valid ? writebuffer_deq_l2cidx :  schedule_a_l2cidx_o       ;
  assign    sourceA_req_opcode_i     = writebuffer_deq_valid ? writebuffer_deq_opcode :  schedule_a_opcode_o       ;
  assign    sourceA_req_size_i       = writebuffer_deq_valid ? writebuffer_deq_size   :  schedule_a_size_o         ;
  assign    sourceA_req_source_i     = writebuffer_deq_valid ? writebuffer_deq_source :  schedule_a_source_o       ;
  assign    sourceA_req_tag_i        = writebuffer_deq_valid ? writebuffer_deq_tag    :  schedule_a_tag_o          ;
  assign    sourceA_req_offset_i     = writebuffer_deq_valid ? writebuffer_deq_offset :  schedule_a_offset_o       ;
  assign    sourceA_req_put_i        = writebuffer_deq_valid ? writebuffer_deq_put    :  schedule_a_put_o          ;
  assign    sourceA_req_data_i       = writebuffer_deq_valid ? writebuffer_deq_data   :  schedule_a_data_o         ;
  assign    sourceA_req_mask_i       = writebuffer_deq_valid ? writebuffer_deq_mask   :  schedule_a_mask_o         ;
  assign    sourceA_req_param_i      = writebuffer_deq_valid ? writebuffer_deq_param  :  schedule_a_param_o        ;
  assign    sourceA_req_valid_i      = writebuffer_deq_valid ? writebuffer_deq_valid  :  schedule_a_valid_o        ;
  assign    SourceD_a_ready_i        = writebuffer_enq_ready ;
  assign    mshr_validOH             = requests_valid_o ;
  assign    mshr_free                = | (~mshr_validOH) ;
  assign    mshr_empty               = & (~mshr_validOH);
  assign    putbuffer_empty          = sinkA_empty_o;
  assign    flush_ready              = !issue_flush_invalidate && putbuffer_empty;
  assign    invalidate_ready         = !issue_flush_invalidate && mshr_empty && putbuffer_empty ;
  assign    request_valid_o          =  sinkA_req_valid_o      ;
  assign    request_set_o            =  sinkA_req_set_o        ;
  //assign  request_l2cidx_o          =  sinkA_req_l2cidx_o     ;
  assign    request_opcode_o         =  sinkA_req_opcode_o     ;
  assign    request_size_o           =  sinkA_req_size_o       ;
  assign    request_source_o         =  sinkA_req_source_o     ;
  assign    request_tag_o            =  sinkA_req_tag_o        ;
  assign    request_offset_o         =  sinkA_req_offset_o     ;
  assign    request_put_o            =  sinkA_req_put_o        ;
  assign    request_data_o           =  sinkA_req_data_o       ;
  assign    request_mask_o           =  sinkA_req_mask_o       ;
  assign    request_param_o          =  sinkA_req_param_o      ;
  assign    sinkA_req_ready_i        =  request_ready_i        ;
  assign    alloc                    = !(|tagMatches);
  assign    is_pending               = (|tagMatches )&& alloc;
  assign    pending_index            = is_pending ? tagMatches2uint : 'b0;
   one2bin #(
   .ONE_WIDTH (`KIANA_MSHRS),
   .BIN_WIDTH ($clog2(`KIANA_MSHRS))
   )U1_one2bin
    (
    .oh ( tagMatches      ) ,
    .bin( tagMatches2uint )     
    );
  assign mshr_insertOH_init =  (~(((~mshr_validOH |((~mshr_validOH) <<1)) | ((~mshr_validOH |((~mshr_validOH) <<1)) <<2 )) <<1)) & (~mshr_validOH);
  // left(~mshr_validOH) =  (~mshr_validOH |(~mshr_validOH <<1)) | ((~mshr_validOH |(~mshr_validOH <<1)) <<2 );//only if `KIANA_PUTLISTS == 4
  assign  mshr_insertOH  = mshr_insertOH_init ;
   one2bin #(
   .ONE_WIDTH (`KIANA_PUTLISTS        ),
   .BIN_WIDTH ($clog2(`KIANA_PUTLISTS))
   )U2_one2bin
    (
    .oh ( mshr_insertOH      ) ,
    .bin( mshr_insertOH2uint )     
    );
  
  //logic [`KIANA_PUTLISTS-1:0] mshr_validOH;
  assign  requests_push_valid_i           = dir_result_valid_o && (!dir_result_hit_o);
  //assign  requests_push_valid_i           = dir_result_valid_o && dir_result_ready_i && (!dir_result_hit_o);
  assign  requests_push_data_data_i       = dir_result_data_o;
  //assign  requests_push_index_req         = alloc ? mshr_insertOH : tagMatches;
  assign  requests_push_data_mask_i       = dir_result_mask_o;
  assign  requests_push_data_put_i        = dir_result_put_o;
  assign  requests_push_data_opcode_i     = dir_result_opcode_o;
  assign  requests_push_data_source_i     = dir_result_source_o;
  assign  requests_push_index_i           = alloc ? mshr_insertOH2uint : tagMatches2uint;
  assign  dir_read_valid_i = request_valid_o && !(request_opcode_o == `HINT ) && mshr_free && requests_push_ready_o && dir_ready_o && !(issue_flush_invalidate);
  assign  dir_read_set_i                  = request_set_o                            ;
  //assign  dir_read_l2cidx_i               = request_l2cidx_o                         ;
  assign  dir_read_opcode_i               = request_opcode_o                         ;
  assign  dir_read_size_i                 = request_size_o                           ;
  assign  dir_read_source_i               = request_source_o                         ;
  assign  dir_read_tag_i                  = request_tag_o                            ;
  assign  dir_read_offset_i               = request_offset_o                         ;
  assign  dir_read_put_i                  = request_put_o                            ;
  assign  dir_read_data_i                 = request_data_o                           ;
  assign  dir_read_mask_i                 = request_mask_o                           ;
  assign  dir_read_param_i                = request_param_o                          ;
  
  assign  dir_write_valid_i               = schedule_dir_valid_o;
  assign  dir_tag_match_i                 = | tagMatches ;
  assign  dir_write_way_i                 = schedule_dir_way_o;
  assign  dir_write_set_i                 = schedule_dir_set_o;
  assign  dir_write_tag_i                 = schedule_dir_data_tag_o;
  assign  dir_invalidate_i                = request_valid_o && request_ready_i && (request_opcode_o == `HINT) && (request_param_o == 'b1);
  assign  dir_flush_i                     = request_valid_o && request_ready_i && (request_opcode_o == `HINT) && (request_param_o == 'b0);
  assign  requests_pop_valid_i            = requests_valid_o[mshr_select] && schedule_d_valid_o && SourceD_req_ready_o ;
  assign  requests_pop_data_i             = mshr_select;
  assign  request_ready_i                 = mshr_free && requests_push_ready_o && dir_read_ready_o && dir_ready_o && !(issue_flush_invalidate);
  logic [dir_result_buffer_data_in_width-1:0] dir_result_buffer_data_in;
  logic [dir_result_buffer_data_in_width-1:0] dir_result_buffer_data_out;
  assign dir_result_buffer_data_in = {
         dir_result_victim_tag_o ,  //dir_result_buffer_data_out[dir_result_buffer_data_in_width-1:dir_result_buffer_data_in_width-`KIANA_TAG_BITS]
         dir_result_way_o        ,  //dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-1:dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS]
         dir_result_hit_o        ,  //dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-1]
         dir_result_dirty_o      ,  //dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-2]
         dir_result_flush_o      ,  //dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-3]
         dir_result_last_flush_o ,  //dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-4]
         dir_result_set_o        ,  //dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-5:dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-`KIANA_SET_BITS-4]
         /*dir_result_l2cidx_o     ,*/  //dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-`KIANA_SET_BITS-5:dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-`KIANA_SET_BITS-4-`KIANA_L2C_BITS]
         dir_result_opcode_o     ,  //dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+`KIANA_TAG_BITS+`KIANA_SOURCE_BITS+`KIANA_SIZE_BITS+:`KIANA_OP_BITS]
         dir_result_size_o       ,  //dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+`KIANA_TAG_BITS+`KIANA_SOURCE_BITS+:`KIANA_SIZE_BITS]
         dir_result_source_o     ,  //dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+`KIANA_TAG_BITS+:`KIANA_SOURCE_BITS]
         dir_result_tag_o        ,  //dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+:`KIANA_TAG_BITS]
         dir_result_offset_o     ,  //dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+:`KIANA_OFFSET_BITS]
         dir_result_put_o        ,  //dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+:`KIANA_PUT_BITS]
         dir_result_data_o       ,  //dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+:`KIANA_DATA_BITS]
         dir_result_mask_o       ,  //dir_result_buffer_data_out[`KIANA_PARAM_BITS+:`KIANA_MASK_BITS]
         dir_result_param_o         //dir_result_buffer_data_out[0+:`KIANA_PARAM_BITS]
  };
  assign dir_result_buffer_enq_fire = dir_result_buffer_enq_valid && dir_result_buffer_enq_ready;
  assign dir_result_buffer_deq_fire = dir_result_buffer_deq_valid && dir_result_buffer_deq_ready;
  
  //TODO: 2024.0424
  assign dir_result_buffer_enq_valid = dir_result_valid_o /*&& dir_result_ready_i*/ && (dir_result_hit_o || dir_result_dirty_o);
  assign dir_result_buffer_deq_ready = !schedule_d_valid_o && SourceD_req_ready_o;
  assign dir_result_ready_i = dir_result_hit_o ? dir_result_buffer_enq_ready : requests_push_ready_o;
  /*stream_fifo*/stream_fifo_useSRAM #(
  .DATA_WIDTH  (dir_result_buffer_data_in_width),
  .FIFO_DEPTH  (8)
  )
  U_stream_fifo(
  .clk       (clk      ),
  .rst_n     (rst_n    ),
  .w_ready_o (dir_result_buffer_enq_ready), //!full
  .w_valid_i (dir_result_buffer_enq_fire ),
  .w_data_i  (dir_result_buffer_data_in  ),
  .r_valid_o (dir_result_buffer_deq_valid), //!empty
  .r_ready_i (dir_result_buffer_deq_fire),
  .r_data_o  (dir_result_buffer_data_out ) 
  );
  genvar o;
  generate 
  for (o=0 ; o< `KIANA_MASK_BITS; o = o+1)
    begin:full_mask_bytes
      assign full_mask[(o+1)*(`KIANA_DATA_BITS/`KIANA_MASK_BITS)-1-:(`KIANA_DATA_BITS/`KIANA_MASK_BITS)] = {`KIANA_DATA_BITS/`KIANA_MASK_BITS {requests_data_mask_o[o]} };
    end
  endgenerate
  
  assign merge_data = (requests_data_data_o & full_mask) | ( schedule_d_data_o & (~full_mask)  );
  
  assign SourceD_req_way_i        = (!schedule_d_valid_o) ? dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-1:dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS] : schedule_d_way_o;
  assign SourceD_req_data_i       = (!schedule_d_valid_o) ? dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+:`KIANA_DATA_BITS] : ( (requests_data_opcode_o == `PUTPARTIALDATA  || requests_data_opcode_o == `PUTFULLDATA )   ? merge_data  : schedule_d_data_o )   ;
  assign SourceD_req_from_mem_i   = (!schedule_d_valid_o) ? 1'b0                          :1'b1;
  assign SourceD_req_hit_i        = (!schedule_d_valid_o) ? dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-1] : schedule_d_hit_o;
  assign SourceD_req_set_i        = (!schedule_d_valid_o) ? dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-5:dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-`KIANA_SET_BITS-4] : schedule_d_set_o;
  assign SourceD_req_tag_i        = (!schedule_d_valid_o) ? ( (!dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-1]) ? dir_result_buffer_data_out[dir_result_buffer_data_in_width-1:dir_result_buffer_data_in_width-`KIANA_TAG_BITS] : dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+:`KIANA_TAG_BITS]) :  schedule_d_tag_o;
  assign SourceD_req_mask_i       = (!schedule_d_valid_o) ? dir_result_buffer_data_out[`KIANA_PARAM_BITS+:`KIANA_MASK_BITS] : requests_data_mask_o;
  assign SourceD_req_offset_i     = (!schedule_d_valid_o) ?  ( (!dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-1]) ? 'b0  : dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+:`KIANA_OFFSET_BITS]   ) : schedule_d_offset_o;
  assign SourceD_req_opcode_i     = (!schedule_d_valid_o) ? dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+`KIANA_TAG_BITS+`KIANA_SOURCE_BITS+`KIANA_SIZE_BITS+:`KIANA_OP_BITS] : requests_data_opcode_o;
  assign SourceD_req_put_i        = (!schedule_d_valid_o) ? dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+:`KIANA_PUT_BITS] : requests_data_put_o;
  assign SourceD_req_size_i       = (!schedule_d_valid_o) ? dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+`KIANA_TAG_BITS+`KIANA_SOURCE_BITS+:`KIANA_SIZE_BITS] : schedule_d_size_o;
  assign SourceD_req_valid_i      = (!schedule_d_valid_o) ? dir_result_buffer_deq_valid   : schedule_d_valid_o  ;
  assign SourceD_req_source_i     = (!schedule_d_valid_o) ? dir_result_buffer_data_out[`KIANA_PARAM_BITS+`KIANA_MASK_BITS+`KIANA_DATA_BITS+`KIANA_PUT_BITS+`KIANA_OFFSET_BITS+`KIANA_TAG_BITS+:`KIANA_SOURCE_BITS] : requests_data_source_o ;
  assign SourceD_req_last_flush_i = (!schedule_d_valid_o) ? dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-4] : schedule_d_last_flush_o ;
  assign SourceD_req_flush_i      = (!schedule_d_valid_o) ? dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-3] : schedule_d_flush_o;
  assign SourceD_req_dirty_i      = (!schedule_d_valid_o) ? dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-2] : schedule_d_dirty_o;
  assign SourceD_req_param_i      = (!schedule_d_valid_o) ? dir_result_buffer_data_out[0+:`KIANA_PARAM_BITS] : schedule_d_param_o ;
  //assign SourceD_req_l2cidx_i     = (!schedule_d_valid_o) ? dir_result_buffer_data_out[dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-`KIANA_SET_BITS-5:dir_result_buffer_data_in_width-`KIANA_TAG_BITS-`KIANA_WAY_BITS-`KIANA_SET_BITS-4-`KIANA_L2C_BITS] :  schedule_d_l2cidx_o ;
  //assign SourceD_req_l2cidx_i     = (!schedule_d_valid_o) ? 'b0 :  schedule_d_l2cidx_o ;
  assign bank_s_sinkD_adr_valid_i = schedule_dir_valid_o;
  assign bank_s_sinkD_adr_set_i   = schedule_dir_set_o;
  assign bank_s_sinkD_adr_way_i   = schedule_dir_way_o;
  assign bank_s_sinkD_adr_mask_i  = ~{`KIANA_MASK_BITS{1'b0}};
  assign bank_s_sinkD_dat_data_i  = schedule_data_o;
  
  assign  bank_s_sourceD_radr_way_i   =           SourceD_bs_radr_way_o            ;
  assign  bank_s_sourceD_radr_set_i   =           SourceD_bs_radr_set_o            ;
  assign  bank_s_sourceD_radr_mask_i  =           SourceD_bs_radr_mask_o           ;
  assign  bank_s_sourceD_radr_valid_i =           SourceD_bs_radr_valid_o          ;
  assign  SourceD_bs_radr_ready_i     =           bank_s_sourceD_radr_ready_o      ;
  //  bankedStore.io.sourceD_radr <> sourceD.io.bs_radr   
  assign  bank_s_sourceD_wadr_way_i   =           SourceD_bs_wadr_way_o          ;
  assign  bank_s_sourceD_wadr_set_i   =           SourceD_bs_wadr_set_o          ;
  assign  bank_s_sourceD_wadr_mask_i  =           SourceD_bs_wadr_mask_o         ;
  assign  bank_s_sourceD_wadr_valid_i =           SourceD_bs_wadr_valid_o        ;
  assign  SourceD_bs_wadr_ready_i     =           bank_s_sourceD_wadr_ready_o    ;
  //  bankedStore.io.sourceD_wadr <> sourceD.io.bs_wadr
  assign  bank_s_sourceD_wdat_data_i  =           SourceD_bs_wdat_data_o         ;
  assign  SourceD_bs_rdat_data_i      =           bank_s_sourceD_rdat_data_o     ;


endmodule
