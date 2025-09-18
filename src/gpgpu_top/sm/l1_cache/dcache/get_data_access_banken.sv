`include "../../../define.svh"
import d_cache::*;

`timescale 1ns/1ps

module get_data_access_banken #(
  parameter NBANK = `KIANA_DCACHE_BLOCKWORDS ,
  parameter NLANE = `KIANA_DCACHE_NLANES      
)(
  input    logic   [$clog2(NBANK)*NLANE-1:0]     perLaneBlockIdx_i       ,
  input    logic   [NLANE-1:0]                   perLaneVaild_i          ,
  output   logic   [$clog2(NLANE)*NBANK-1:0]     perBankBlockIdx_o       ,  
  output   logic   [NBANK-1:0]                   perBankValid_o           
);

  parameter DEPTGH_NBANK = $clog2(NBANK);
  parameter DEPTGH_NLANE = $clog2(NLANE);

  logic  [NBANK*NLANE-1:0] perLaneBlockIdx_oh      ;
  logic  [NBANK*NLANE-1:0] blockIdxMasked          ;
  logic  [NLANE*NBANK-1:0] perBankReq_bin          ;
  logic  [NLANE*NBANK-1:0] perBankReq_oh           ;
  logic  [NLANE*NBANK-1:0] perBankReq_tmp          ;

  genvar i;
  generate
    for(i=0; i<NLANE; i=i+1) begin:lane_loop_1
      bin2one #(
        .ONE_WIDTH(NBANK        ),
        .BIN_WIDTH($clog2(NBANK))
      )
      U_bin2one
      (
        .bin  (perLaneBlockIdx_i[$clog2(NBANK)*(i+1)-1-:$clog2(NBANK)]   ),
        .oh   (perLaneBlockIdx_oh[NBANK*(i+1)-1-:NBANK]                   )    
      );
      
      assign  blockIdxMasked[NBANK*(i+1)-1-:NBANK]  = perLaneBlockIdx_oh[NBANK*(i+1)-1-:NBANK] & {NBANK{perLaneVaild_i[i]}};
    end
  endgenerate

  genvar j;
  generate
    for(j=0; j<NBANK; j=j+1) begin:bank_loop_1
      assign  perBankReq_bin[NLANE*(j+1)-1-:NLANE]  = perBankReq_tmp[NLANE*(j+1)-1-:NLANE];
      
      fixed_pri_arb #(
        .ARB_WIDTH(NLANE)
      )
      U_fixed_pri_arb
      (
        .req  (perBankReq_bin[NLANE*(j+1)-1-:NLANE]         ),
        .grant(perBankReq_oh[NLANE*(j+1)-1-:NLANE]          )
      );

      one2bin #(
        .ONE_WIDTH(NLANE        ),
        .BIN_WIDTH($clog2(NLANE))
      )
      U_one2bin
      (
        .oh (perBankReq_oh[NLANE*(j+1)-1-:NLANE]                        ),
        .bin(perBankBlockIdx_o[$clog2(NLANE)*(j+1)-1-:$clog2(NLANE)]    )    
      );

      //assign  perBankBlockIdx_o = perBankReq_bin[NLANE*(i+1)-1-:NLANE];
      assign  perBankValid_o[j]    = |perBankReq_bin[NLANE*(j+1)-1-:NLANE];
    end
  endgenerate

  genvar n,m;
  generate
    for(n=0; n<NBANK; n=n+1) begin:bank_loop_2
      for(m=0; m<NLANE; m=m+1) begin:lane_loop_2
        assign  perBankReq_tmp[NLANE*n+m]  = blockIdxMasked[NBANK*m+n];
      end
    end
  endgenerate

endmodule
