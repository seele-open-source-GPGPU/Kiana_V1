
`timescale  1ns/1ns
`include "../define.svh"
//`include "L2cache_define.v"

module Listbuffer(
  input logic                                         clk                           ,
  input logic                                         rst_n                         ,
  // val putbuffer, in fact it is listbuffer class
  output logic                                        List_buffer_push_ready_o      ,//data out
  input logic                                         List_buffer_push_valid_i      ,//data in
  input logic [`PUT_BITS-1:0]                         List_buffer_push_index_i      ,//data in
  input logic [`DATA_BITS-1:0]                        List_buffer_push_data_data_i  ,//data in;
  input logic [`MASK_BITS-1:0]                        List_buffer_push_data_mask_i  ,//data in;
  input logic [`PUT_BITS-1:0]                         List_buffer_push_data_put_i   ,
  input logic [`OP_BITS-1:0]                          List_buffer_push_data_opcode_i,
  input logic [`SOURCE_BITS-1:0]                      List_buffer_push_data_source_i,
  output logic [`PUTLISTS-1:0]                        List_buffer_valid_o           ,//data out
  input logic                                         List_buffer_pop_valid_i       ,//data in
  input logic [`PUT_BITS-1:0]                         List_buffer_pop_data_i        ,//data in
  output logic [`DATA_BITS-1:0]                       List_buffer_data_data_o       ,//data out
  output logic [`MASK_BITS-1:0]                       List_buffer_data_mask_o       ,//data out
  output logic [`PUT_BITS-1:0]                        List_buffer_data_put_o        ,
  output logic [`OP_BITS-1:0]                         List_buffer_data_opcode_o     ,
  output logic [`SOURCE_BITS-1:0]                     List_buffer_data_source_o         
  );
  //above is the putbuffe IO ports, and there is no other index, pop2 and data2 port is because singleport is true.
  //and below is the putbuffer inner logic
  logic [`PUTLISTS-1:0]                           valid                         ;
  logic [$clog2(`PUTBEATS)*`PUTLISTS-1:0]         head                          ;         
  logic [$clog2(`PUTBEATS)*`PUTLISTS-1:0]         tail                          ;         
  logic [`PUTBEATS-1:0]                           used                          ; //init 0
  logic [$clog2(`PUTBEATS)*`PUTBEATS-1:0]         next                          ;  
  logic [`DATA_BITS*`PUTBEATS-1:0]                data_data                     ;        
  logic [`MASK_BITS*`PUTBEATS-1:0]                data_mask                     ;        
  logic [`SOURCE_BITS*`PUTBEATS-1:0]              data_source                   ;
  logic [`PUT_BITS*`PUTBEATS-1:0]                 data_put                      ;        
  logic [`OP_BITS*`PUTBEATS-1:0]                  data_opcode                   ;
  
  logic [`PUTBEATS-1:0]                          freeOH                        ;
  logic [$clog2(`PUTBEATS)-1:0]                  freeIdx                       ;
  
  assign freeOH = (~((((~used)|((~used)<<1)) | (((~used)|((~used)<<1))<<2))<<1)) & (~used);//only if `PUTBEATS == 4
  //freeOH = ~(leftOR(~used) <<1)  & (~used);
  //leftOR(~used) = (~used) | ((~used <<2)[width -1:0]), width(~used)
  one2bin #(
  .ONE_WIDTH(`PUTBEATS),
  .BIN_WIDTH($clog2(`PUTBEATS))
  )
  U_one2bin(
  .oh (freeOH),
  .bin(freeIdx)
  );
  logic [`PUTLISTS-1:0]                          valid_set                     ;
  logic [`PUTLISTS-1:0]                          valid_clr                     ;
  logic [`PUTBEATS-1:0]                          used_set                      ;
  logic [`PUTBEATS-1:0]                          used_clr                      ;
  logic [`PUTLISTS-1:0]                          valid_clr_2                   ;
  logic [`PUTBEATS-1:0]                          used_clr_2                    ;
  logic [$clog2(`PUTBEATS)-1:0]                  push_tail                     ;
  logic                                          push_valid                    ;
  logic [$clog2(`PUTBEATS)-1:0]                  pop_head                      ;
  assign pop_head = head [List_buffer_pop_data_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)];
  logic [$clog2 (`PUTBEATS)-1:0]                 head_write_pop_data;
  assign head_write_pop_data = (List_buffer_push_valid_i && List_buffer_push_ready_o && push_valid && (push_tail == pop_head)) ? freeIdx : next[pop_head*$clog2 (`PUTBEATS)+:$clog2 (`PUTBEATS)];
  assign push_tail  = tail[List_buffer_push_index_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)];
  assign push_valid = valid[List_buffer_push_index_i];
  assign List_buffer_push_ready_o = !(&used);
  assign valid_set = (List_buffer_push_ready_o & List_buffer_push_valid_i) ?  ( (List_buffer_push_index_i == 'b0) ? 'b1 : (1'b1<< List_buffer_push_index_i)  ): 'b0;
  assign used_set  = (List_buffer_push_ready_o & List_buffer_push_valid_i) ? (freeOH) :'b0;
  //   mem     valid- head- tail - used -next - data_data - data_mask
  always_ff @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          head        <= 0;
          tail        <= 0;
          data_data   <= 0;
          data_mask   <= 0;
          data_source <= 0;
          data_put    <= 0;
          data_opcode <= 0;
          next        <= 0;
        end
      else if(List_buffer_push_ready_o & List_buffer_push_valid_i)
        begin
          data_data[freeIdx*`DATA_BITS+:`DATA_BITS] <= List_buffer_push_data_data_i;
          data_mask[freeIdx*`MASK_BITS+:`MASK_BITS] <= List_buffer_push_data_mask_i;
          data_source[freeIdx*`SOURCE_BITS+:`SOURCE_BITS] <= List_buffer_push_data_source_i;
          data_put   [freeIdx*`PUT_BITS+:`PUT_BITS] <= List_buffer_push_data_put_i;
          data_opcode[freeIdx*`OP_BITS+:`OP_BITS] <= List_buffer_push_data_opcode_i;
          tail[List_buffer_push_index_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)] <= freeIdx;
          if(push_valid)
            begin
              next[push_tail*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)] <= freeIdx;
            end
          else if(!push_valid)
            begin
              head[List_buffer_push_index_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)] <= freeIdx;
            end
        end
      else if(List_buffer_pop_valid_i )
        begin
          head[List_buffer_pop_data_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)] <= head_write_pop_data;
        end
      else
        begin
          next        <= next       ;
          head        <= head       ;
          tail        <= tail       ;
          data_data   <= data_data  ;
          data_mask   <= data_mask  ;
          data_source <= data_source;
          data_put    <= data_put   ;
          data_opcode <= data_opcode;
        end
    end
  logic   pop_valid;
  assign pop_valid = valid[List_buffer_pop_data_i];
  
  assign List_buffer_data_data_o   = data_data [pop_head*`DATA_BITS+:`DATA_BITS]     ;//only if bypass is false
  assign List_buffer_data_mask_o   = data_mask [pop_head*`MASK_BITS+:`MASK_BITS]     ;//only if bypass is false
  assign List_buffer_data_opcode_o = data_opcode[pop_head*`OP_BITS+:`OP_BITS]        ;
  assign List_buffer_data_put_o    = data_put [pop_head*`PUT_BITS+:`PUT_BITS]        ;
  assign List_buffer_data_source_o = data_source[pop_head*`SOURCE_BITS+:`SOURCE_BITS];
  
  assign List_buffer_valid_o = valid;
  assign used_clr  = (List_buffer_pop_valid_i) ?  ( (pop_head == 'b0) ? 'b1 : (1'b1<< pop_head)  ): 'b0;
  assign valid_clr = (List_buffer_pop_valid_i && (pop_head == tail[List_buffer_pop_data_i*$clog2(`PUTBEATS)+:$clog2(`PUTBEATS)])) ?  ( (List_buffer_pop_data_i == 'b0) ? 'b1 : (1'b1<< List_buffer_pop_data_i)  ): 'b0;
  
  always_ff @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          used <= 0;
          valid <= 0;
        end
      else if( ! List_buffer_pop_valid_i || pop_valid ) // bypass is false now ,and no pop_valid2 bacause singleport is true
        begin
          used <= used & (~used_clr)   | used_set;
          valid <= valid & (~valid_clr)|valid_set;
        end
    end

endmodule
