`include "../l1_cache.svh"
import shared_mem::*;

`timescale 1ns/1ps
module gen_data_map_same_word(
  input  logic  [1*`KIANA_DCACHE_NLANES-1:0]                          perLaneAddr_activeMask_i              ,
  input  logic  [`KIANA_DCACHE_BLOCKOFFSETBITS*`KIANA_DCACHE_NLANES-1:0]    perLaneAddr_blockOffset_i             ,
  input  logic  [`KIANA_BYTESOFWORD*`KIANA_DCACHE_NLANES-1:0]               perLaneAddr_wordOffset1H_i            ,
  input  logic  [`KIANA_WORDLENGTH*`KIANA_DCACHE_NLANES-1:0]                data_i                                ,
  output logic  [1*`KIANA_DCACHE_NLANES-1:0]                          perLaneAddrRemap_activeMask_o         , // no use
  output logic  [`KIANA_DCACHE_BLOCKOFFSETBITS*`KIANA_DCACHE_NLANES-1:0]    perLaneAddrRemap_blockOffset_o        , // no use
  output logic  [`KIANA_BYTESOFWORD*`KIANA_DCACHE_NLANES-1:0]               perLaneAddrRemap_wordOffset1H_o       ,
  output logic  [`KIANA_WORDLENGTH*`KIANA_DCACHE_NLANES-1:0]                data_o                                 
);

  logic [`KIANA_DCACHE_NLANES*`KIANA_DCACHE_NLANES-1:0]                    blockOffsetMatch          ;
  logic [`KIANA_DCACHE_NLANES*`KIANA_DCACHE_NLANES*`KIANA_BYTESOFWORD-1:0]       wordOffsetRemap           ;
  logic [`KIANA_DCACHE_NLANES*`KIANA_DCACHE_NLANES*`KIANA_WORDLENGTH-1:0]        dataRemap                 ;

  logic [`KIANA_DCACHE_NLANES*(`KIANA_DCACHE_NLANES-1)*`KIANA_BYTESOFWORD-1:0]   wordOffsetRemap_tmp       ;
  logic [`KIANA_DCACHE_NLANES*(`KIANA_DCACHE_NLANES-1)*`KIANA_WORDLENGTH-1:0]    dataRemap_tmp             ;

  genvar i,j;
  generate
    for (i=0; i<`KIANA_DCACHE_NLANES; i=i+1) begin:row_loop_1
      for (j=0; j<`KIANA_DCACHE_NLANES; j=j+1) begin:column_loop_1
        always_comb begin
          if(perLaneAddr_activeMask_i[i] && perLaneAddr_activeMask_i[j]) begin
            blockOffsetMatch[`KIANA_DCACHE_NLANES*i+j]  = perLaneAddr_blockOffset_i[`KIANA_DCACHE_BLOCKOFFSETBITS*(i+1)-1-:`KIANA_DCACHE_BLOCKOFFSETBITS]==perLaneAddr_blockOffset_i[`KIANA_DCACHE_BLOCKOFFSETBITS*(j+1)-1-:`KIANA_DCACHE_BLOCKOFFSETBITS];
          end else begin
            blockOffsetMatch[`KIANA_DCACHE_NLANES*i+j]  = 1'b0;
          end
        end
      end
    end
  endgenerate

  genvar n,m;
  generate
    for (n=0; n<`KIANA_DCACHE_NLANES; n=n+1) begin:row_loop_2
      assign  perLaneAddrRemap_activeMask_o   [n]                                                        = perLaneAddr_activeMask_i   [n]                                                                             ;
      assign  perLaneAddrRemap_blockOffset_o  [`KIANA_DCACHE_BLOCKOFFSETBITS*(n+1)-1-:`KIANA_DCACHE_BLOCKOFFSETBITS] = perLaneAddr_blockOffset_i  [`KIANA_DCACHE_BLOCKOFFSETBITS*(n+1)-1-:`KIANA_DCACHE_BLOCKOFFSETBITS]                      ;
      assign  perLaneAddrRemap_wordOffset1H_o [`KIANA_BYTESOFWORD*(n+1)-1-:`KIANA_BYTESOFWORD]                       = wordOffsetRemap_tmp     [(`KIANA_DCACHE_NLANES-1)*`KIANA_BYTESOFWORD*n+(`KIANA_DCACHE_NLANES-1)*`KIANA_BYTESOFWORD-1-:`KIANA_BYTESOFWORD];
      assign  data_o                          [`KIANA_WORDLENGTH*(n+1)-1-:`KIANA_WORDLENGTH]                         = dataRemap_tmp           [(`KIANA_DCACHE_NLANES-1)*`KIANA_WORDLENGTH*n+(`KIANA_DCACHE_NLANES-1)*`KIANA_WORDLENGTH-1-:`KIANA_WORDLENGTH]   ;
      for (m=0; m<`KIANA_DCACHE_NLANES; m=m+1) begin:column_loop_2
        assign  wordOffsetRemap[`KIANA_DCACHE_NLANES*`KIANA_BYTESOFWORD*n+`KIANA_BYTESOFWORD*(m+1)-1-:`KIANA_BYTESOFWORD] = blockOffsetMatch[`KIANA_DCACHE_NLANES*n+m] ? perLaneAddr_wordOffset1H_i[`KIANA_BYTESOFWORD*(m+1)-1-:`KIANA_BYTESOFWORD] : 'b0       ;
        assign  dataRemap[`KIANA_DCACHE_NLANES*`KIANA_WORDLENGTH*n+`KIANA_WORDLENGTH*(m+1)-1-:`KIANA_WORDLENGTH]          = blockOffsetMatch[`KIANA_DCACHE_NLANES*n+m] ? data_i[`KIANA_WORDLENGTH*(m+1)-1-:`KIANA_WORDLENGTH] : 'b0                             ;
      end
    end
  endgenerate

  genvar k,l;
  generate
    for (k=0; k<`KIANA_DCACHE_NLANES; k=k+1) begin:row_loop_3
      assign  wordOffsetRemap_tmp [(`KIANA_DCACHE_NLANES-1)*`KIANA_BYTESOFWORD*k+`KIANA_BYTESOFWORD*(0+1)-1-:`KIANA_BYTESOFWORD]  = wordOffsetRemap [`KIANA_DCACHE_NLANES*`KIANA_BYTESOFWORD*k+`KIANA_BYTESOFWORD*(1+1)-1-:`KIANA_BYTESOFWORD]  | wordOffsetRemap [`KIANA_DCACHE_NLANES*`KIANA_BYTESOFWORD*k+`KIANA_BYTESOFWORD*(0+1)-1-:`KIANA_BYTESOFWORD]  ;
      assign  dataRemap_tmp       [(`KIANA_DCACHE_NLANES-1)*`KIANA_WORDLENGTH*k+`KIANA_WORDLENGTH*(0+1)-1-:`KIANA_WORDLENGTH]     = dataRemap       [`KIANA_DCACHE_NLANES*`KIANA_WORDLENGTH*k+`KIANA_WORDLENGTH*(1+1)-1-:`KIANA_WORDLENGTH]     | dataRemap       [`KIANA_DCACHE_NLANES*`KIANA_WORDLENGTH*k+`KIANA_WORDLENGTH*(0+1)-1-:`KIANA_WORDLENGTH]     ;
      for (l=0; l<`KIANA_DCACHE_NLANES-2; l=l+1) begin:column_loop_3
        assign  wordOffsetRemap_tmp[(`KIANA_DCACHE_NLANES-1)*`KIANA_BYTESOFWORD*k+`KIANA_BYTESOFWORD*(l+1+1)-1-:`KIANA_BYTESOFWORD] = wordOffsetRemap[`KIANA_DCACHE_NLANES*`KIANA_BYTESOFWORD*k+`KIANA_BYTESOFWORD*(l+2+1)-1-:`KIANA_BYTESOFWORD] | wordOffsetRemap_tmp [(`KIANA_DCACHE_NLANES-1)*`KIANA_BYTESOFWORD*k+`KIANA_BYTESOFWORD*(l+1)-1-:`KIANA_BYTESOFWORD]  ;
        assign  dataRemap_tmp      [(`KIANA_DCACHE_NLANES-1)*`KIANA_WORDLENGTH*k+`KIANA_WORDLENGTH*(l+1+1)-1-:`KIANA_WORDLENGTH]    = dataRemap      [`KIANA_DCACHE_NLANES*`KIANA_WORDLENGTH*k+`KIANA_WORDLENGTH*(l+2+1)-1-:`KIANA_WORDLENGTH]    | dataRemap_tmp       [(`KIANA_DCACHE_NLANES-1)*`KIANA_WORDLENGTH*k+`KIANA_WORDLENGTH*(l+1)-1-:`KIANA_WORDLENGTH]     ;
      end
    end
  endgenerate
endmodule
