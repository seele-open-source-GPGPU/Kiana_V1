`timescale 1ns/1ns

`include "../../../define.svh"
import shared_mem::*;

module l1_mshr (
  input logic                                  clk                     ,
  input logic                                  rst_n                   ,
  input logic                                  probe_valid_i           ,
  input logic  [`KIANA_BABITS-1:0]                   probe_blockaddr_i       ,
  input logic                                  missreq_valid_i         ,
  output logic                                 missreq_ready_o         ,
  input logic  [`KIANA_BABITS-1:0]                   missreq_blockaddr_i     ,
  input logic  [`KIANA_TIWIDTH-1:0]                  missreq_targetinfo_i    ,
  input logic                                  missrsp_in_valid_i      ,
  output logic                                 missrsp_in_ready_o      ,
  input logic  [$clog2(`KIANA_DCACHE_MSHRENTRY)-1:0] missrsp_in_instrid_i    ,
  output logic                                 missrsp_out_valid_o     ,
  output logic [`KIANA_BABITS-1:0]                   missrsp_out_blockaddr_o ,
  output logic [`KIANA_TIWIDTH-1:0]                  missrsp_out_targetinfo_o,
  output logic                                 empty_o                 ,
  output logic                                 probe_status_o          ,
  output logic [2:0]                           mshr_status_st0_o       ,
  output logic [2:0]                           probe_out_mshr_status_o ,
  output logic [$clog2(`KIANA_DCACHE_MSHRENTRY)-1:0] probe_out_a_source_o    ,
  input logic                                  stage1_ready_i          ,
  input logic                                  stage2_ready_i          
);

  logic [`KIANA_BABITS*`KIANA_DCACHE_MSHRENTRY-1:0]                         blockaddr_access ;
  //target info can be replaced with SRAM
  logic [`KIANA_TIWIDTH*(`KIANA_DCACHE_MSHRENTRY*`KIANA_DCACHE_MSHRSUBENTRY)-1:0] targetinfo_access;  
  logic [`KIANA_DCACHE_MSHRENTRY*`KIANA_DCACHE_MSHRSUBENTRY-1:0]            subentry_valid   ;

  logic [`KIANA_DCACHE_MSHRENTRY-1:0]         entry_valid              ; 
  logic [$clog2(`KIANA_DCACHE_MSHRENTRY)-1:0] entry_matchmiss_rsp      ;
  logic [`KIANA_DCACHE_MSHRENTRY-1:0]         entry_match_probe        ;
  logic [`KIANA_DCACHE_MSHRENTRY-1:0]         entry_match_probe_reg    ;
  logic [`KIANA_DCACHE_MSHRSUBENTRY-1:0]      subentry_selected        ;
  logic [$clog2(`KIANA_DCACHE_MSHRENTRY)-1:0] entry_match_probe_bin    ;
  logic [$clog2(`KIANA_DCACHE_MSHRENTRY)-1:0] entry_match_probe_bin_reg;

  genvar i;
  generate for(i=0;i<`KIANA_DCACHE_MSHRENTRY;i=i+1) begin: ENTRY_VALID
    assign entry_valid[i]           = |subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*(i+1)-1:`KIANA_DCACHE_MSHRSUBENTRY*i]                ;
    assign entry_match_probe[i]     = (blockaddr_access[`KIANA_BABITS*(i+1)-1:`KIANA_BABITS*i]==probe_blockaddr_i) && entry_valid[i]  ;
    assign entry_match_probe_reg[i] = (blockaddr_access[`KIANA_BABITS*(i+1)-1:`KIANA_BABITS*i]==missreq_blockaddr_i) && entry_valid[i];
  end
  endgenerate

  one2bin #(
    .ONE_WIDTH (`KIANA_DCACHE_MSHRENTRY        ),
    .BIN_WIDTH ($clog2(`KIANA_DCACHE_MSHRENTRY))
  )
  entry_match_probe_one2bin (
    .oh  (entry_match_probe    ),
    .bin (entry_match_probe_bin)
  );

  one2bin #(
    .ONE_WIDTH (`KIANA_DCACHE_MSHRENTRY        ),
    .BIN_WIDTH ($clog2(`KIANA_DCACHE_MSHRENTRY))
  )
  entry_match_probe_reg_one2bin (
    .oh  (entry_match_probe_reg    ),
    .bin (entry_match_probe_bin_reg)
  );
  
  assign entry_matchmiss_rsp = missrsp_in_instrid_i;
  assign subentry_selected   = (entry_match_probe=='d0) ? 'd0 : subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*(entry_match_probe_bin+1)-1 -:`KIANA_DCACHE_MSHRSUBENTRY];

  //subentry status
  logic                                    subentry_status_almfull;
  logic                                    subentry_status_full   ;
  logic [$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:0] subentry_status_next   ;

  get_entry_status_req #(
    .NUM_ENTRY (`KIANA_DCACHE_MSHRSUBENTRY)
  )
  subentry_status (
    .valid_list_i (subentry_selected      ),
    .alm_full_o   (subentry_status_almfull),
    .full_o       (subentry_status_full   ),
    .next_o       (subentry_status_next   )
  );

  //entry status
  logic                                 entry_status_almfull;
  logic                                 entry_status_full   ;
  logic [$clog2(`KIANA_DCACHE_MSHRENTRY)-1:0] entry_status_next   ;

  get_entry_status_req #(
    .NUM_ENTRY (`KIANA_DCACHE_MSHRENTRY)
  )
  entry_status (
    .valid_list_i (entry_valid         ),
    .alm_full_o   (entry_status_almfull),
    .full_o       (entry_status_full   ),
    .next_o       (entry_status_next   )
  );

  //subentry status for rsp
  logic [`KIANA_DCACHE_MSHRSUBENTRY-1:0]         subentry_status_rsp_valid_list ;
  logic [$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:0] subentry_status_rsp_next2cancel;
  logic [$clog2(`KIANA_DCACHE_MSHRSUBENTRY):0]   subentry_status_rsp_used       ;

  assign subentry_status_rsp_valid_list = subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*(entry_matchmiss_rsp+1)-1 -:`KIANA_DCACHE_MSHRSUBENTRY];

  get_entry_status_rsp #(
    .NUM_ENTRY (`KIANA_DCACHE_MSHRSUBENTRY)
  )
  subentry_status_rsp (
    .valid_list_i  (subentry_status_rsp_valid_list ),
    .next2cancel_o (subentry_status_rsp_next2cancel),
    .used_o        (subentry_status_rsp_used       )
  );

  // pipeline logic: mshr_st1
  logic                                                      mshr_st1_enq_ready        ;
  logic                                                      mshr_st1_enq_valid        ;
  logic [`KIANA_DCACHE_MSHRENTRY+$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:0] mshr_st1_enq_bits         ;
  logic                                                      mshr_st1_deq_valid        ;
  logic                                                      mshr_st1_deq_ready        ;
  logic [`KIANA_DCACHE_MSHRENTRY+$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:0] mshr_st1_deq_bits         ;
  logic [`KIANA_DCACHE_MSHRENTRY-1:0]                              mshr_st1_entry_match_probe;
  logic [$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:0]                   mshr_st1_subentry_idx     ;

  assign mshr_st1_enq_valid = probe_valid_i                           ;
  assign mshr_st1_deq_ready = stage1_ready_i                          ;
  assign mshr_st1_enq_bits  = {entry_match_probe,subentry_status_next};

  stream_fifo_pipe_true #(
    .DATA_WIDTH (`KIANA_DCACHE_MSHRENTRY+$clog2(`KIANA_DCACHE_MSHRSUBENTRY)),
    .FIFO_DEPTH (1                                             )
  )
  mshr_st1 (
    .clk       (clk               ),
    .rst_n     (rst_n             ),
    .w_ready_o (mshr_st1_enq_ready),
    .w_valid_i (mshr_st1_enq_valid),
    .w_data_i  (mshr_st1_enq_bits ),
    .r_valid_o (mshr_st1_deq_valid),
    .r_ready_i (mshr_st1_deq_ready),
    .r_data_o  (mshr_st1_deq_bits )
  );

  assign mshr_st1_entry_match_probe = mshr_st1_deq_bits[`KIANA_DCACHE_MSHRENTRY+$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:$clog2(`KIANA_DCACHE_MSHRSUBENTRY)];
  assign mshr_st1_subentry_idx      = mshr_st1_deq_bits[$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:0];

  //TODO: check these status

  // mshr status st0
  // PRIMARY_AVAIL        : 000
  // PRIMARY_FULL         : 001
  // SECONDARY_AVAIL      : 010
  // SECONDARY_FULL       : 011
  // SECONDARY_FULL_RETURN: 100
  logic [2:0] mshr_status_r  ;
  logic [2:0] mshr_status_st1;
  logic [2:0] mshr_status_st0;

  logic secondary_miss_st1;
  logic secondary_miss_st0;
  logic primary_miss_st1  ;
  logic primary_miss_st0  ;

  assign secondary_miss_st1 = |mshr_st1_entry_match_probe;
  assign secondary_miss_st0 = |entry_match_probe         ;
  assign primary_miss_st1   = !secondary_miss_st1        ;
  assign primary_miss_st0   = !secondary_miss_st0        ;

  always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mshr_status_r <= 'd0;
    end
    else begin
      if(missreq_valid_i && missreq_ready_o && !probe_valid_i && stage2_ready_i) begin
        if(primary_miss_st1 && entry_status_full) begin
          mshr_status_r <= 3'b001; // pri full
        end
        else if(secondary_miss_st1 && subentry_status_almfull) begin
          mshr_status_r <= 3'b011; // sec full
        end
        else begin
          mshr_status_r <= mshr_status_r;
        end
      end
      else if(probe_valid_i) begin
        if(primary_miss_st0) begin
          if(entry_status_full || (entry_status_almfull&&missreq_valid_i&&missreq_ready_o)) begin
            mshr_status_r <= 3'b001; // pri full
          end
          else begin
            mshr_status_r <= 3'b000; // pri avail
          end
        end
        else begin
          if(subentry_status_full) begin
            mshr_status_r <= 3'b011; // sec full
          end
          else begin
            mshr_status_r <= 3'b010; // sec avail
          end
        end
      end
      else if(missrsp_in_valid_i) begin
        if((mshr_status_r==3'b001) || (mshr_status_r==3'b010)) begin
          mshr_status_r <= 3'b000; // pri avail
        end
        else if((mshr_status_r==3'b011) && (subentry_status_rsp_used=='d1)) begin
          mshr_status_r <= 3'b100; // sec full return
        end
        else if((mshr_status_r==3'b100) && (subentry_status_rsp_used=='d0)) begin
          mshr_status_r <= 3'b000; // sec avail
        end
      end
      else begin
        mshr_status_r <= mshr_status_r;
      end
    end
  end

  always_comb begin
    if(primary_miss_st0) begin
      if(entry_status_full || (missreq_valid_i&&entry_status_almfull)) begin
        mshr_status_st0 = 3'b001;
      end
      else begin
        mshr_status_st0 = 3'b000;
      end
    end
    else begin
      if(subentry_status_full || (missreq_valid_i&&subentry_status_almfull)) begin
        mshr_status_st0 = 3'b011;
      end
      else begin
        mshr_status_st0 = 3'b010;
      end
    end
  end
  
  //mshr_status need extra operations?
  always_comb begin
    if(secondary_miss_st1 && ((mshr_status_r==3'b000)||(mshr_status_r==3'b001)) && stage2_ready_i) begin
      if(subentry_status_full) begin
        mshr_status_st1 = 3'b011;
      end
      else begin
        mshr_status_st1 = 3'b010;
      end
    end
    else begin
      mshr_status_st1 = mshr_status_r;
    end
  end

  // probe status
  logic probe_status;

  always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      probe_status <= 'd0;
    end
    else begin
      if(probe_valid_i && !probe_status) begin
        probe_status <= 1'b1;
      end
      else if(probe_status) begin
        if((probe_blockaddr_i!=missreq_blockaddr_i) && missrsp_in_valid_i && missrsp_in_ready_o) begin
          probe_status <= probe_valid_i;
        end
        else if(missrsp_in_valid_i && missrsp_in_ready_o) begin
          probe_status <= 1'b0;
        end
        else begin
          probe_status <= probe_status;
        end
      end
      else begin
        probe_status <= probe_status;
      end
    end
  end

  logic [$clog2(`KIANA_DCACHE_MSHRENTRY)-1:0]    real_sram_addr_up    ;
  logic [$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:0] real_sram_addr_down  ;
  logic [$clog2(`KIANA_DCACHE_MSHRENTRY)-1:0]    entry_match_probe_st1;

  one2bin #(
    .ONE_WIDTH (`KIANA_DCACHE_MSHRENTRY        ),
    .BIN_WIDTH ($clog2(`KIANA_DCACHE_MSHRENTRY))
  )
  entry_match_probe_st1_one2bin (
    .oh  (mshr_st1_entry_match_probe),
    .bin (entry_match_probe_st1     )
  );
  
  assign real_sram_addr_up   = secondary_miss_st1 ? entry_match_probe_st1 : entry_status_next;
  assign real_sram_addr_down = secondary_miss_st1 ? mshr_st1_subentry_idx : 'd0              ;

  //targetinfo_access
  genvar n,m;
  generate for(n=0;n<`KIANA_DCACHE_MSHRENTRY;n=n+1) begin: INFO_UP
    for(m=0;m<`KIANA_DCACHE_MSHRSUBENTRY;m=m+1) begin: INFO_DOWN
      always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          targetinfo_access[`KIANA_TIWIDTH*(`KIANA_DCACHE_MSHRSUBENTRY*n+m+1)-1 -:`KIANA_TIWIDTH] <= 'd0;// targetinfo_access[n][m]
        end
        else begin
          if(missreq_valid_i && missreq_ready_o && mshr_st1_deq_ready) begin
            targetinfo_access[`KIANA_TIWIDTH*(`KIANA_DCACHE_MSHRSUBENTRY*n+m+1)-1 -:`KIANA_TIWIDTH] <= ((n==real_sram_addr_up)&&(m==real_sram_addr_down)) ? missreq_targetinfo_i : targetinfo_access[`KIANA_TIWIDTH*(`KIANA_DCACHE_MSHRSUBENTRY*n+m+1)-1 -:`KIANA_TIWIDTH];
          end
          else begin
            targetinfo_access[`KIANA_TIWIDTH*(`KIANA_DCACHE_MSHRSUBENTRY*n+m+1)-1 -:`KIANA_TIWIDTH] <= targetinfo_access[`KIANA_TIWIDTH*(`KIANA_DCACHE_MSHRSUBENTRY*n+m+1)-1 -:`KIANA_TIWIDTH];
          end
        end
      end
    end
  end
  endgenerate

  //blockaddr_access
  genvar j;
  generate for(j=0;j<`KIANA_DCACHE_MSHRENTRY;j=j+1) begin: BLOCKADDR
    always_ff@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        blockaddr_access[`KIANA_BABITS*(j+1)-1:`KIANA_BABITS*j] <= 'd0;
      end
      else begin
        if(missreq_valid_i && missreq_ready_o && mshr_st1_deq_ready && (mshr_status_st1==3'b000)) begin
          blockaddr_access[`KIANA_BABITS*(j+1)-1:`KIANA_BABITS*j] <= (j==entry_status_next) ? missreq_blockaddr_i : blockaddr_access[`KIANA_BABITS*(j+1)-1:`KIANA_BABITS*j];
        end
        else begin
          blockaddr_access[`KIANA_BABITS*(j+1)-1:`KIANA_BABITS*j] <= blockaddr_access[`KIANA_BABITS*(j+1)-1:`KIANA_BABITS*j];
        end
      end
    end
  end
  endgenerate

  //output target_info and blockaddr

  logic [`KIANA_TIWIDTH*`KIANA_DCACHE_MSHRSUBENTRY-1:0] missrsp_targetinfo_entry_st1;
  logic [`KIANA_TIWIDTH-1:0]                      missrsp_targetinfo_st1      ;
  logic [`KIANA_BABITS-1:0]                       missrsp_blockaddr_st1       ;

  //to make sure the last mshr main entry has cleaned up 
  logic                                  missrsp_in_valid_st1        ;
  logic [$clog2(`KIANA_DCACHE_MSHRENTRY)-1:0]  entry_matchmiss_rsp_st1     ;
  
  logic                                  missrsp_in_valid_st1_clean  ;

  logic [`KIANA_DCACHE_MSHRSUBENTRY-1:0]         subentry_status_rsp_valid_list_st1        ;
  logic [$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:0] subentry_status_rsp_next2cancel_st1       ;
  logic [$clog2(`KIANA_DCACHE_MSHRSUBENTRY):0]   subentry_status_rsp_used_st1              ;
  logic [`KIANA_DCACHE_MSHRSUBENTRY-1:0]         subentry_status_rsp_valid_list_reverse_st1;
  logic [$clog2(`KIANA_DCACHE_MSHRSUBENTRY)-1:0] subentry_status_rsp_now2cancel_st1        ;

  assign subentry_status_rsp_valid_list_st1 = subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*(entry_matchmiss_rsp_st1+1)-1 -:`KIANA_DCACHE_MSHRSUBENTRY];

  
  get_entry_status_rsp #(
    .NUM_ENTRY (`KIANA_DCACHE_MSHRSUBENTRY)
  )
  subentry_status_rsp_st1 (
    .valid_list_i  (subentry_status_rsp_valid_list_st1 ),
    .next2cancel_o (subentry_status_rsp_next2cancel_st1),
    .used_o        (subentry_status_rsp_used_st1       )
  );

  input_reverse #(
    .DATA_WIDTH (`KIANA_DCACHE_MSHRSUBENTRY)
  )
  reverse_list_st1 (
    .data_i (subentry_status_rsp_valid_list_st1        ),
    .data_o (subentry_status_rsp_valid_list_reverse_st1)
  );

  find_first #(
    .DATA_WIDTH (`KIANA_DCACHE_MSHRSUBENTRY        ),
    .DATA_DEPTH ($clog2(`KIANA_DCACHE_MSHRSUBENTRY))
  )
  find_now_to_cancel (
    .data_i (subentry_status_rsp_valid_list_reverse_st1),
    .target (1'b1                                      ),
    .data_o (subentry_status_rsp_now2cancel_st1        )
  );


  always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      missrsp_in_valid_st1         <= 'd0;
      entry_matchmiss_rsp_st1      <= 'd0;
      missrsp_in_valid_st1_clean   <= 'd0;
    end
    else begin
      missrsp_in_valid_st1         <= missrsp_in_valid_i && missrsp_in_ready_o;
      missrsp_in_valid_st1_clean   <= missrsp_in_valid_i || (missrsp_in_valid_st1_clean && subentry_status_rsp_used_st1!='d0)   ;
      entry_matchmiss_rsp_st1      <= (missrsp_in_valid_i && missrsp_in_ready_o) ? entry_matchmiss_rsp : entry_matchmiss_rsp_st1;
    end
  end

  assign missrsp_targetinfo_entry_st1 = targetinfo_access[`KIANA_TIWIDTH*`KIANA_DCACHE_MSHRSUBENTRY*(entry_matchmiss_rsp_st1+1)-1 -:`KIANA_TIWIDTH*`KIANA_DCACHE_MSHRSUBENTRY];
  assign missrsp_targetinfo_st1       = missrsp_targetinfo_entry_st1[`KIANA_TIWIDTH*(subentry_status_rsp_next2cancel_st1+1)-1 -: `KIANA_TIWIDTH]                  ;
  assign missrsp_blockaddr_st1        = blockaddr_access[`KIANA_BABITS*(entry_matchmiss_rsp_st1+1)-1 -:`KIANA_BABITS]                                             ;

  //update valid_list
  genvar x,y;
  generate for(x=0;x<`KIANA_DCACHE_MSHRENTRY;x=x+1) begin: VALID_UP
    for(y=0;y<`KIANA_DCACHE_MSHRSUBENTRY;y=y+1) begin: VALID_DOWN
      always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y] <= 'd0;
        end
        else begin
          if(missreq_valid_i && missreq_ready_o && primary_miss_st1) begin
            subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y] <= ((x==entry_status_next)&&(y=='d0)) ? 1'b1 : subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y];
          end
          else if(missrsp_in_valid_i && missrsp_in_ready_o) begin
            subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y] <= ((x==entry_matchmiss_rsp)&&(y==subentry_status_rsp_next2cancel)) ? 1'b0 : subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y];
          end
          else if(missrsp_in_valid_st1 && subentry_status_rsp_used_st1>=1) begin
            subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y] <= ((x==entry_matchmiss_rsp_st1)&&(y==subentry_status_rsp_now2cancel_st1)) ? 1'b0 : subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y];
          end
          else if(missreq_valid_i && missreq_ready_o && secondary_miss_st1 && mshr_st1_deq_valid && mshr_st1_deq_ready) begin
            subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y] <= ((x==entry_match_probe_bin_reg)&&(y==mshr_st1_subentry_idx)) ? 1'b1 : subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y];
          end
          else begin
            subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y] <= subentry_valid[`KIANA_DCACHE_MSHRSUBENTRY*x+y];
          end
        end
      end
    end
  end
  endgenerate

  //outputs
  assign missreq_ready_o          = !((mshr_status_st1==3'b001) || (mshr_status_st1==3'b011));
  //assign missrsp_in_ready_o       = !((subentry_status_rsp_used>'d1) || ((mshr_status_st1==3'b100)||(mshr_status_st1==3'b011)) && (subentry_status_rsp_used==3'b001) || missreq_valid_i);
  //assign missrsp_in_ready_o       = !(((mshr_status_st1==3'b100)||(mshr_status_st1==3'b011)) && (subentry_status_rsp_used==3'b001) || missreq_valid_i);
  assign missrsp_in_ready_o       = !(missrsp_out_valid_o || missreq_valid_i);
  assign missrsp_out_valid_o      = missrsp_in_valid_st1_clean;
  assign missrsp_out_blockaddr_o  = missrsp_blockaddr_st1     ;
  assign missrsp_out_targetinfo_o = missrsp_targetinfo_st1    ;
  assign empty_o                  = !(|entry_valid)           ;
  assign probe_status_o           = mshr_st1_deq_valid        ;
  assign mshr_status_st0_o        = mshr_status_st0           ;
  assign probe_out_mshr_status_o  = mshr_status_st1           ;
  assign probe_out_a_source_o     = missreq_valid_i ? real_sram_addr_up : entry_match_probe_bin_reg;

endmodule

