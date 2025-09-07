`include "../../../define.svh"
import shared_mem::*;

`timescale 1ns/1ps

module dcache_wshr #(
  parameter DEPTH = `KIANA_DCACHE_WSHR_ENTRY          ,
  parameter WIDTH = $clog2(`KIANA_DCACHE_WSHR_ENTRY)    
)(
  input  logic                                           clk                     ,
  input  logic                                           rst_n                   ,

  // push
  input  logic                                           pushReq_valid_i         ,
  output logic                                           pushReq_ready_o         ,
  input  logic [`KIANA_DCACHE_SETIDXBITS+`KIANA_DCACHE_TAGBITS-1:0]  pushReq_blockAddr_i     ,
  output logic                                           conflict_o              ,
  output logic [WIDTH-1:0]                               pushedIdx_o             ,

  // for invOrFlu
  output logic                                           empty_o                 ,
  
  // pop
  input  logic                                           popReq_valid_i          ,
  input  logic [WIDTH-1:0]                               popReq_bits_i             
);

  logic  [(`KIANA_DCACHE_SETIDXBITS+`KIANA_DCACHE_TAGBITS)*DEPTH-1:0]    blockAddrEntries        ;
  logic  [DEPTH-1:0]                                         validEntries            ;
  logic  [DEPTH-1:0]                                         pushMatchMask           ;
  logic  [WIDTH-1:0]                                         nextEntryIdx            ;
  logic                                                      pop_push_in_same_cycle  ;
  logic  [DEPTH-1:0]                                         available_entries_oh    ;
  //wire  [WIDTH-1:0]                                         available_entries_bin   ;


  assign  empty_o = !(|validEntries);
  
  genvar i;
  generate
    for (i=0; i<DEPTH; i=i+1) begin:mask_loop
      assign  pushMatchMask[i] = (blockAddrEntries[(`KIANA_DCACHE_SETIDXBITS+`KIANA_DCACHE_TAGBITS)*(i+1)-1-:(`KIANA_DCACHE_SETIDXBITS+`KIANA_DCACHE_TAGBITS)]==pushReq_blockAddr_i) && validEntries[i];
    end
  endgenerate

  assign  conflict_o      = |pushMatchMask    ;
  assign  pushReq_ready_o = !(&validEntries)  ; // pushReq_ready = !full

  assign  pop_push_in_same_cycle = (pushReq_valid_i && pushReq_ready_o) && popReq_valid_i;
  assign  pushedIdx_o = pop_push_in_same_cycle ? popReq_bits_i : nextEntryIdx;

  always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      blockAddrEntries  <= 'b0;
      validEntries      <= 'b0;
    end else if(pop_push_in_same_cycle) begin
      blockAddrEntries[(`KIANA_DCACHE_SETIDXBITS+`KIANA_DCACHE_TAGBITS)*(popReq_bits_i+1)-1-:(`KIANA_DCACHE_SETIDXBITS+`KIANA_DCACHE_TAGBITS)]  <= pushReq_blockAddr_i;
      validEntries[popReq_bits_i]         <= 1'b1;
    end else if(pushReq_valid_i && pushReq_ready_o) begin
      blockAddrEntries[(`KIANA_DCACHE_SETIDXBITS+`KIANA_DCACHE_TAGBITS)*(nextEntryIdx+1)-1-:(`KIANA_DCACHE_SETIDXBITS+`KIANA_DCACHE_TAGBITS)]  <= pushReq_blockAddr_i;
      validEntries[nextEntryIdx]          <= 1'b1;
    end else if(popReq_valid_i) begin
      validEntries[popReq_bits_i]         <= 1'b0;
    end else begin
      blockAddrEntries  <= blockAddrEntries ;
      validEntries      <= validEntries     ;
    end
  end

  fixed_pri_arb #(
    .ARB_WIDTH(DEPTH)
  )
  U_fixed_pri_arb
  (
    .req  (~validEntries            ),
    .grant(available_entries_oh     )
  );

  one2bin #(
    .ONE_WIDTH(DEPTH),
    .BIN_WIDTH(WIDTH)
  )
  U_one2bin
  (
    .oh (available_entries_oh      ),
    .bin(nextEntryIdx              )    
  );

endmodule
