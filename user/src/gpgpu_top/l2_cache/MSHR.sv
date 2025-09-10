
`timescale  1ns/1ns
`include "../define.svh"
import l2_cache::*;

module MSHR(
  input logic                               clk                          ,
  input logic                               rst_n                        ,
  
  //input logic allocted signals
  input logic                               mshr_alloc_valid_i           ,
  //input logic alloc handshake signals
  input logic                               mshr_alloc_hit_i             ,
  input logic [`KIANA_WAY_BITS-1:0]               mshr_alloc_way_i             ,
  input logic                               mshr_alloc_dirty_i           ,
  input logic                               mshr_alloc_flush_i           ,
  input logic                               mshr_alloc_last_flush_i      ,
  input logic  [`KIANA_SET_BITS-1:0]              mshr_alloc_set_i             ,
  //input logic  [`L2C_BITS-1:0]              mshr_alloc_l2cidx_i          ,
  input logic  [`KIANA_OP_BITS-1:0]               mshr_alloc_opcode_i          ,
  input logic  [`KIANA_SIZE_BITS-1:0]             mshr_alloc_size_i            ,
  input logic  [`KIANA_SOURCE_BITS-1:0]           mshr_alloc_source_i          ,
  input logic  [`KIANA_TAG_BITS-1:0]              mshr_alloc_tag_i             ,
  input logic  [`KIANA_OFFSET_BITS-1:0]           mshr_alloc_offset_i          ,
  input logic  [`KIANA_PUT_BITS-1:0]              mshr_alloc_put_i             ,
  input logic  [`KIANA_DATA_BITS-1:0]             mshr_alloc_data_i            ,
  input logic  [`KIANA_MASK_BITS-1:0]             mshr_alloc_mask_i            ,
  input logic  [`KIANA_PARAM_BITS-1:0]            mshr_alloc_param_i           ,
  
  //output logic status signals
  output logic                              mshr_status_hit_o            ,
  output logic  [`KIANA_WAY_BITS-1:0]             mshr_status_way_o            ,
  output logic                              mshr_status_dirty_o          ,
  output logic                              mshr_status_flush_o          ,
  output logic                              mshr_status_last_flush_o     ,
  output logic  [`KIANA_SET_BITS-1:0]             mshr_status_set_o            ,
  //output logic  [`L2C_BITS-1:0]             mshr_status_l2cidx_o         ,
  output logic  [`KIANA_OP_BITS-1:0]              mshr_status_opcode_o         ,
  output logic  [`KIANA_SIZE_BITS-1:0]            mshr_status_size_o           ,
  output logic  [`KIANA_SOURCE_BITS-1:0]          mshr_status_source_o         ,
  output logic  [`KIANA_TAG_BITS-1:0]             mshr_status_tag_o            ,
  output logic  [`KIANA_OFFSET_BITS-1:0]          mshr_status_offset_o         ,
  output logic  [`KIANA_PUT_BITS-1:0]             mshr_status_put_o            ,
  output logic  [`KIANA_DATA_BITS-1:0]            mshr_status_data_o           ,
  output logic  [`KIANA_MASK_BITS-1:0]            mshr_status_mask_o           ,
  output logic  [`KIANA_PARAM_BITS-1:0]           mshr_status_param_o          ,
  
  //input logic valid bool
  input logic                               mshr_valid_i                 ,
  
  //input logic mshr_wait bool
  input logic                               mshr_wait_i                  ,
  
  //input logic  mixed part
  input logic                               mshr_mixed_i                 ,
  
  //output logic  schedule  part
  //schedule part a : Decoupled FullRequest
  input logic                               mshr_schedule_a_ready_i      ,
  output logic                              mshr_schedule_a_valid_o      ,
  //input logic  schedule part handshake signals
  output logic  [`KIANA_SET_BITS-1:0]             mshr_schedule_a_set_o        ,
  //output logic  [`L2C_BITS-1:0]             mshr_schedule_a_l2cidx_o     ,
  output logic  [`KIANA_OP_BITS-1:0]              mshr_schedule_a_opcode_o     ,
  output logic  [`KIANA_SIZE_BITS-1:0]            mshr_schedule_a_size_o       ,
  output logic  [`KIANA_SOURCE_BITS-1:0]          mshr_schedule_a_source_o     ,
  output logic  [`KIANA_TAG_BITS-1:0]             mshr_schedule_a_tag_o        ,
  output logic  [`KIANA_OFFSET_BITS-1:0]          mshr_schedule_a_offset_o     ,
  output logic  [`KIANA_PUT_BITS-1:0]             mshr_schedule_a_put_o        ,
  output logic  [`KIANA_DATA_BITS-1:0]            mshr_schedule_a_data_o       ,
  output logic  [`KIANA_MASK_BITS-1:0]            mshr_schedule_a_mask_o       ,
  output logic  [`KIANA_PARAM_BITS-1:0]           mshr_schedule_a_param_o      ,
  
  //schedule part d  : Decoupled DirectoryResult_lite
  input logic                               mshr_schedule_d_ready_i      ,
  output logic                              mshr_schedule_d_valid_o      ,
  //schedule part d handshake signals
  output logic                              mshr_schedule_d_hit_o        ,
  output logic  [`KIANA_WAY_BITS-1:0]             mshr_schedule_d_way_o        ,
  output logic                              mshr_schedule_d_dirty_o      ,
  output logic                              mshr_schedule_d_flush_o      ,
  output logic                              mshr_schedule_d_last_flush_o ,
  output logic  [`KIANA_SET_BITS-1:0]             mshr_schedule_d_set_o        ,
  //output logic  [`L2C_BITS-1:0]             mshr_schedule_d_l2cidx_o     ,
  output logic  [`KIANA_OP_BITS-1:0]              mshr_schedule_d_opcode_o     ,
  output logic  [`KIANA_SIZE_BITS-1:0]            mshr_schedule_d_size_o       ,
  output logic  [`KIANA_SOURCE_BITS-1:0]          mshr_schedule_d_source_o     ,
  output logic  [`KIANA_TAG_BITS-1:0]             mshr_schedule_d_tag_o        ,
  output logic  [`KIANA_OFFSET_BITS-1:0]          mshr_schedule_d_offset_o     ,
  output logic  [`KIANA_PUT_BITS-1:0]             mshr_schedule_d_put_o        ,
  output logic  [`KIANA_DATA_BITS-1:0]            mshr_schedule_d_data_o       ,
  output logic  [`KIANA_MASK_BITS-1:0]            mshr_schedule_d_mask_o       ,
  output logic  [`KIANA_PARAM_BITS-1:0]           mshr_schedule_d_param_o      ,
  
  //schedule  data part   
  output logic  [`KIANA_DATA_BITS-1:0]            mshr_schedule_data_o         ,
  
  //output logic  schedule dir part
  input logic                               mshr_schedule_dir_ready_i    ,
  output logic                              mshr_schedule_dir_valid_o    ,
  //schedule part dir handshake signals
  output logic  [`KIANA_WAY_BITS-1:0]             mshr_schedule_dir_way_o      ,
  output logic  [`KIANA_TAG_BITS-1:0]             mshr_schedule_dir_data_tag_o ,
  output logic  [`KIANA_SET_BITS-1:0]             mshr_schedule_dir_set_o      ,
  
  //merge part
  input logic                               mshr_merge_valid_i           ,
  output logic                              mshr_merge_ready             ,
  //merge part handshake signals
  input logic  [`KIANA_MASK_BITS-1:0]             mshr_merge_mask_i            ,
  input logic  [`KIANA_DATA_BITS-1:0]             mshr_merge_data_i            ,    
  input logic  [`KIANA_OP_BITS-1:0]               mshr_merge_opcode_i          ,
  input logic  [`KIANA_PUT_BITS-1:0]              mshr_merge_put_i             ,
  input logic  [`KIANA_SOURCE_BITS-1:0]           mshr_merge_source_i          ,
  
  //sinked part
  input logic                               mshr_sinked_valid_i          ,
  //sinked part handshake signals
  input logic  [`KIANA_OP_BITS-1:0]               mshr_sinked_opcode_i         ,
  input logic  [`KIANA_SOURCE_BITS-1:0]           mshr_sinked_source_i         ,
  input logic  [`KIANA_DATA_BITS-1:0]             mshr_sinked_data_i            
  );
  parameter writeBytes       = 4             ;
  parameter full_mask_bytes  = 8 * writeBytes;
  
  logic                               mixed_reg                      ;
  logic   [`KIANA_DATA_BITS-1:0]            data_reg                       ;
  //output logic status signals
  logic                               request_hit_reg                ;
  logic   [`KIANA_WAY_BITS-1:0]             request_way_reg                ;
  logic                               request_dirty_reg              ;
  logic                               request_flush_reg              ;
  logic                               request_last_flush_reg         ;
  logic   [`KIANA_SET_BITS-1:0]             request_set_reg                ;
  //logic   [`L2C_BITS-1:0]             request_l2cidx_reg             ;
  logic   [`KIANA_OP_BITS-1:0]              request_opcode_reg             ;
  logic   [`KIANA_SIZE_BITS-1:0]            request_size_reg               ;
  logic   [`KIANA_SOURCE_BITS-1:0]          request_source_reg             ;
  logic   [`KIANA_TAG_BITS-1:0]             request_tag_reg                ;
  logic   [`KIANA_OFFSET_BITS-1:0]          request_offset_reg             ;
  logic   [`KIANA_PUT_BITS-1:0]             request_put_reg                ;
  logic   [`KIANA_DATA_BITS-1:0]            request_data_reg               ;
  logic   [`KIANA_MASK_BITS-1:0]            request_mask_reg               ;
  logic   [`KIANA_PARAM_BITS-1:0]           request_param_reg              ;
  
  logic [`KIANA_DATA_BITS-1:0] full_mask;
  
  assign full_mask = {{full_mask_bytes{mshr_merge_mask_i[0]}}, {full_mask_bytes{mshr_merge_mask_i[1]}}, {full_mask_bytes{mshr_merge_mask_i[2]}}, {full_mask_bytes{mshr_merge_mask_i[3]}}};
  
  logic [`KIANA_DATA_BITS-1:0] merge_data;
  assign merge_data = ( mshr_merge_data_i & full_mask ) | (data_reg & (~full_mask));
  
  logic sche_a_valid  ;//init to 0
  logic sche_dir_valid;//init to 0
  logic sink_d_reg    ;//init to 0
  
  
  //output logic status signals
  assign   mshr_status_hit_o         =      request_hit_reg        ;
  assign   mshr_status_way_o         =      request_way_reg        ;
  assign   mshr_status_dirty_o       =      request_dirty_reg      ;
  assign   mshr_status_flush_o       =      request_flush_reg      ;
  assign   mshr_status_last_flush_o  =      request_last_flush_reg ;
  assign   mshr_status_set_o         =      request_set_reg        ;
  //assign   mshr_status_l2cidx_o      =      request_l2cidx_reg     ;
  assign   mshr_status_opcode_o      =      request_opcode_reg     ;
  assign   mshr_status_size_o        =      request_size_reg       ;
  assign   mshr_status_source_o      =      request_source_reg     ;
  assign   mshr_status_tag_o         =      request_tag_reg        ;
  assign   mshr_status_offset_o      =      request_offset_reg     ;
  assign   mshr_status_put_o         =      request_put_reg        ;
  assign   mshr_status_data_o        =      request_data_reg       ;
  assign   mshr_status_mask_o        =      request_mask_reg       ;
  assign   mshr_status_param_o       =      request_param_reg      ;
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
      begin
        request_hit_reg        <= 0;
        request_way_reg        <= 0;
        request_dirty_reg      <= 0;
        request_flush_reg      <= 0;
        request_last_flush_reg <= 0;
        request_set_reg        <= 0;
  //      request_l2cidx_reg     <= 0;
        request_opcode_reg     <= 0;
        request_size_reg       <= 0;
        request_source_reg     <= 0;
        request_tag_reg        <= 0;
        request_offset_reg     <= 0;
        request_put_reg        <= 0;
        request_data_reg       <= 0;
        request_mask_reg       <= 0;
        request_param_reg      <= 0;
        sink_d_reg             <= 0;
      end
    else if(mshr_alloc_valid_i)
      begin
        request_hit_reg        <= mshr_alloc_hit_i            ;
        request_way_reg        <= mshr_alloc_way_i            ;
        request_dirty_reg      <= mshr_alloc_dirty_i          ;
        request_flush_reg      <= mshr_alloc_flush_i          ;
        request_last_flush_reg <= mshr_alloc_last_flush_i     ;
        request_set_reg        <= mshr_alloc_set_i            ;
  //      request_l2cidx_reg     <= mshr_alloc_l2cidx_i         ;
        request_opcode_reg     <= mshr_alloc_opcode_i         ;
        request_size_reg       <= mshr_alloc_size_i           ;
        request_source_reg     <= mshr_alloc_source_i         ;
        request_tag_reg        <= mshr_alloc_tag_i            ;
        request_offset_reg     <= mshr_alloc_offset_i         ;
        request_put_reg        <= mshr_alloc_put_i            ;
        request_data_reg       <= mshr_alloc_data_i           ;
        request_mask_reg       <= mshr_alloc_mask_i           ;
        request_param_reg      <= mshr_alloc_param_i          ;
        sink_d_reg             <= 0;
      end
    else if(mshr_sinked_valid_i)
      sink_d_reg             <= 1'b1;
    else
      begin
        request_hit_reg        <=         request_hit_reg        ;
        request_way_reg        <=         request_way_reg        ;
        request_dirty_reg      <=         request_dirty_reg      ;
        request_flush_reg      <=         request_flush_reg      ;
        request_last_flush_reg <=         request_last_flush_reg ;
        request_set_reg        <=         request_set_reg        ;
  //      request_l2cidx_reg     <=         request_l2cidx_reg     ;
        request_opcode_reg     <=         request_opcode_reg     ;
        request_size_reg       <=         request_size_reg       ;
        request_source_reg     <=         request_source_reg     ;
        request_tag_reg        <=         request_tag_reg        ;
        request_offset_reg     <=         request_offset_reg     ;
        request_put_reg        <=         request_put_reg        ;
        request_data_reg       <=         request_data_reg       ;
        request_mask_reg       <=         request_mask_reg       ;
        request_param_reg      <=         request_param_reg      ;
      end
  end
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
      begin
        data_reg <= 0;
      end
    else if(mshr_alloc_valid_i)
      begin
        data_reg <= mshr_alloc_data_i;
      end
    else if(mshr_merge_valid_i)
      begin
        data_reg <= merge_data;
      end 
    else if(mshr_sinked_valid_i)
      begin
        data_reg <= mshr_sinked_data_i;
      end
    else data_reg<= data_reg;
  end
  
  assign mshr_schedule_d_valid_o      = mshr_valid_i && sink_d_reg     ; //为了使得最后全弹出来才拉低，需要知道这个MSHR是否还有效
  assign mshr_schedule_d_hit_o        = 1'b0                           ;//  io.schedule.d.bits.hit := false.B
  assign mshr_schedule_d_way_o        = request_way_reg                ;
  assign mshr_schedule_d_dirty_o      = 1'b0                           ;//  io.schedule.d.bits.dirty := false.B
  assign mshr_schedule_d_flush_o      = request_flush_reg              ;
  assign mshr_schedule_d_last_flush_o = request_last_flush_reg         ;
  assign mshr_schedule_d_set_o        = request_set_reg                ;
  //assign mshr_schedule_d_l2cidx_o     = request_l2cidx_reg             ;
  assign mshr_schedule_d_opcode_o     = request_opcode_reg             ;
  assign mshr_schedule_d_size_o       = request_size_reg               ;
  assign mshr_schedule_d_source_o     = request_source_reg             ;
  assign mshr_schedule_d_tag_o        = request_tag_reg                ;
  assign mshr_schedule_d_offset_o     = request_offset_reg             ;
  assign mshr_schedule_d_put_o        = request_put_reg                ;
  assign mshr_schedule_d_data_o       = data_reg                       ;//io.schedule.d.bits.data := data_reg
  assign mshr_schedule_d_mask_o       = request_mask_reg               ;
  assign mshr_schedule_d_param_o      = request_param_reg              ;
  
  assign mshr_schedule_data_o         = data_reg                       ;//io.schedule.data := data_reg
  
  //process for schedule a part
  assign mshr_schedule_a_valid_o = sche_a_valid && !mshr_wait_i;
  assign mshr_schedule_a_set_o   = request_set_reg             ;
  assign mshr_schedule_a_opcode_o= `GET                        ;
  assign mshr_schedule_a_tag_o   = request_tag_reg             ;
  //assign mshr_schedule_a_l2cidx_o= request_l2cidx_reg        ;
  assign mshr_schedule_a_param_o = request_param_reg           ;
  assign mshr_schedule_a_put_o   = request_put_reg             ;
  assign mshr_schedule_a_offset_o= request_offset_reg          ;
  assign mshr_schedule_a_source_o= request_source_reg          ;
  assign mshr_schedule_a_data_o  = request_data_reg            ;
  assign mshr_schedule_a_size_o  = request_size_reg            ;
  assign mshr_schedule_a_mask_o  = {`KIANA_MASK_BITS{1'b1}}          ;
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      sche_a_valid <= 0; 
    end 
    else if(mshr_schedule_a_valid_o && mshr_schedule_a_ready_i) begin
      sche_a_valid <= 1'b0;
    end
    else if (mshr_alloc_valid_i) begin
      sche_a_valid <= 1'b1;
    end
    else sche_a_valid <= sche_a_valid;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      sche_dir_valid <= 0;  
    end
    else if(mshr_alloc_valid_i) begin
      sche_dir_valid <= 1'b0;
    end
    else if(mshr_schedule_dir_ready_i && mshr_schedule_dir_valid_o) begin
      sche_dir_valid <= 1'b0;
    end
    else if(mshr_mixed_i) begin
      sche_dir_valid <= 1'b0;
    end
    else if(mshr_sinked_valid_i && !(mshr_mixed_i ||mixed_reg )) begin
      sche_dir_valid <= 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      mixed_reg <= 0;  
    end
    else if(mshr_alloc_valid_i) begin
      mixed_reg <= 1'b0;
    end
    else if(mshr_mixed_i) begin
      mixed_reg <= 1'b1;
    end
    else mixed_reg <= mixed_reg;
  end
  
  assign mshr_schedule_dir_valid_o    = sche_dir_valid && (request_opcode_reg == `GET );
  assign mshr_schedule_dir_set_o      = request_set_reg                                ;
  assign mshr_schedule_dir_data_tag_o = request_tag_reg                                ;
  assign mshr_schedule_dir_way_o      = request_way_reg                                ;

endmodule
