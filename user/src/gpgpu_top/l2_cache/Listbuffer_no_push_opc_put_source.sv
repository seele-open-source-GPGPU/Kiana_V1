
`timescale  1ns/1ns
`include "../define.svh"
  module Listbuffer_no_push_opc_put_source(
  input logic                                         clk                         ,
  input logic                                         rst_n                       ,
  // val putbuffer, in fact it is listbuffer class
  output logic                                        List_buffer_push_ready_o    ,//data out
  input logic                                         List_buffer_push_valid_i    ,//data in
  input logic [`KIANA_PUT_BITS-1:0]                         List_buffer_push_index_i    ,//data in
  input logic [`KIANA_DATA_BITS-1:0]                        List_buffer_push_data_data_i,//data in;
  input logic [`KIANA_MASK_BITS-1:0]                        List_buffer_push_data_mask_i,//data in;
  output logic [`KIANA_PUTLISTS-1:0]                        List_buffer_valid_o         ,//data out
  input logic                                         List_buffer_pop_valid_i     ,//data in
  input logic [`KIANA_PUT_BITS-1:0]                         List_buffer_pop_data_i      ,//data in
  output logic [`KIANA_DATA_BITS-1:0]                       List_buffer_data_data_o     ,//data out
  output logic [`KIANA_MASK_BITS-1:0]                       List_buffer_data_mask_o             //data out
  );
//above is the putbuffe IO ports, and there is no other index, pop2 and data2 port is because singleport is true.
//and below is the putbuffer inner logic
  logic [`KIANA_PUTLISTS-1:0]                           valid                       ;
  logic [$clog2(`KIANA_PUTBEATS)*`KIANA_PUTLISTS-1:0]         head                        ;         
  logic [$clog2(`KIANA_PUTBEATS)*`KIANA_PUTLISTS-1:0]         tail                        ;         
  logic [`KIANA_PUTBEATS-1:0]                           used                        ; //init 0
  logic [$clog2(`KIANA_PUTBEATS)*`KIANA_PUTBEATS-1:0]         next                        ;  
  logic [`KIANA_DATA_BITS*`KIANA_PUTBEATS-1:0]                data_data                   ;        
  logic [`KIANA_MASK_BITS*`KIANA_PUTBEATS-1:0]                data_mask                   ;        
  logic [`KIANA_SOURCE_BITS*`KIANA_PUTBEATS-1:0]              data_source                 ;
  logic [`KIANA_PUT_BITS*`KIANA_PUTBEATS-1:0]                 data_put                    ;        
  logic [`KIANA_OP_BITS*`KIANA_PUTBEATS-1:0]                  data_opcode                 ;
  logic [`KIANA_PUTBEATS-1:0]                          freeOH                      ;
  logic [$clog2(`KIANA_PUTBEATS)-1:0]                  freeIdx                     ;
  assign freeOH = (~((((~used)|((~used)<<1)) | (((~used)|((~used)<<1))<<2))<<1)) & (~used);//only if `KIANA_PUTBEATS == 4
  one2bin #(
  .ONE_WIDTH(`KIANA_PUTBEATS),
  .BIN_WIDTH($clog2(`KIANA_PUTBEATS))
  )
  U_one2bin(
  .oh (freeOH),
  .bin(freeIdx)
  );
  logic [`KIANA_PUTLISTS-1:0]                          valid_set                   ;
  logic [`KIANA_PUTLISTS-1:0]                          valid_clr                   ;
  logic [`KIANA_PUTBEATS-1:0]                          used_set                    ;
  logic [`KIANA_PUTBEATS-1:0]                          used_clr                    ;
  logic [`KIANA_PUTLISTS-1:0]                          valid_clr_2                 ;
  logic [`KIANA_PUTBEATS-1:0]                          used_clr_2                  ;
  logic [$clog2(`KIANA_PUTBEATS)-1:0]                  push_tail                   ;
  logic                                          push_valid                  ;
  logic [$clog2(`KIANA_PUTBEATS)-1:0]                  pop_head                    ;
  assign pop_head = head [List_buffer_pop_data_i*$clog2(`KIANA_PUTBEATS)+:$clog2(`KIANA_PUTBEATS)];
  logic [$clog2 (`KIANA_PUTBEATS)-1:0] head_write_pop_data;
  assign head_write_pop_data = (List_buffer_push_valid_i && List_buffer_push_ready_o && push_valid && (push_tail == pop_head)) ? freeIdx : next[pop_head*$clog2 (`KIANA_PUTBEATS)+:$clog2 (`KIANA_PUTBEATS)];
  assign push_tail  = tail[List_buffer_push_index_i*$clog2(`KIANA_PUTBEATS)+:$clog2(`KIANA_PUTBEATS)];
  assign push_valid = valid[List_buffer_push_index_i]                                    ;
  assign List_buffer_push_ready_o  = !(&used);
  assign valid_set = (List_buffer_push_ready_o & List_buffer_push_valid_i) ?  ( (List_buffer_push_index_i == 'b0) ? 'b1 : (1'b1<< List_buffer_push_index_i)  ): 'b0;
  assign used_set  = (List_buffer_push_ready_o & List_buffer_push_valid_i) ? (freeOH) :'b0;
  //是mem的  valid- head- tail - used -next - data_data - data_mask
  always_ff @(posedge clk or negedge rst_n)
    begin
      if(!rst_n)
        begin
          head <= 0;
          tail <= 0;
          data_data <= 0;
          data_mask <= 0;
          next <= 0;
        end
      else if(List_buffer_push_ready_o & List_buffer_push_valid_i)
        begin
          data_data[freeIdx*`KIANA_DATA_BITS+:`KIANA_DATA_BITS] <= List_buffer_push_data_data_i;
          data_mask[freeIdx*`KIANA_MASK_BITS+:`KIANA_MASK_BITS] <= List_buffer_push_data_mask_i;
          tail[List_buffer_push_index_i*$clog2(`KIANA_PUTBEATS)+:$clog2(`KIANA_PUTBEATS)] <= freeIdx;
         if(push_valid)
          begin
            next[push_tail*$clog2(`KIANA_PUTBEATS)+:$clog2(`KIANA_PUTBEATS)] <= freeIdx;
          end
          else if(!push_valid)
            begin
              head[List_buffer_push_index_i*$clog2(`KIANA_PUTBEATS)+:$clog2(`KIANA_PUTBEATS)] <= freeIdx;
            end
        end
        else if(List_buffer_pop_valid_i )
          begin
            head[List_buffer_pop_data_i*$clog2(`KIANA_PUTBEATS)+:$clog2(`KIANA_PUTBEATS)] <= head_write_pop_data;
          end
          else
            begin
              next       <= next     ;
              head       <= head     ;
              tail       <= tail     ;
              data_data  <= data_data;
              data_mask  <= data_mask;
            end
    end
  
  logic pop_valid;
  assign pop_valid = valid[List_buffer_pop_data_i];
  
  assign List_buffer_data_data_o  = data_data [pop_head*`KIANA_DATA_BITS+:`KIANA_DATA_BITS];//only if bypass is false
  assign List_buffer_data_mask_o  = data_mask [pop_head*`KIANA_MASK_BITS+:`KIANA_MASK_BITS];//only if bypass is false
  assign List_buffer_valid_o = valid;
  
  assign used_clr  = (List_buffer_pop_valid_i) ?  ( (pop_head == 'b0) ? 'b1 : (1'b1<< pop_head)  ): 'b0;
  assign valid_clr = (List_buffer_pop_valid_i && (pop_head == tail[List_buffer_pop_data_i*$clog2(`KIANA_PUTBEATS)+:$clog2(`KIANA_PUTBEATS)])) ?  ( (List_buffer_pop_data_i == 'b0) ? 'b1 : (1'b1<< List_buffer_pop_data_i)  ): 'b0;
  always_ff @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        used  <= 0;
        valid <= 0;
      end
      else if( ! List_buffer_pop_valid_i || pop_valid ) // bypass is false now ,and no pop_valid2 bacause singleport is true
  begin
      used  <= used  & (~used_clr)   | used_set  ;
      valid <= valid & (~valid_clr)  | valid_set ;
  end
  end
  
  endmodule
