`timescale 1ns/1ns

module dualportSRAM #(
  parameter int BITWIDTH = 32,
  parameter int DEPTH    = 8
)(
  input  logic                  CLK ,
  input  logic                  RSTN,
  input  logic [BITWIDTH-1:0]   D   ,
  output logic [BITWIDTH-1:0]   Q   ,
  input  logic                  REB ,
  input  logic                  WEB ,
  input  logic [BITWIDTH-1:0]   BWEB,
  input  logic [DEPTH-1:0]      AA  ,
  input  logic [DEPTH-1:0]      AB
);

  logic [BITWIDTH-1:0] mem_core [0:(2**DEPTH)-1];

  // 写端口
  always_ff @(posedge CLK or negedge RSTN) begin : WRITE_PROC
    integer ii, jj;
    if (!RSTN) begin
      for (jj = 0; jj < 2**DEPTH; jj = jj + 1) begin
        mem_core[jj] <= '0;
      end
    end
    else if (WEB) begin
      for (ii = 0; ii < BITWIDTH; ii = ii + 1) begin
        if (BWEB[ii]) begin
          mem_core[AA][ii] <= D[ii];
        end
      end
    end
  end

  logic [BITWIDTH-1:0] QN;

  // 读端口
  always_ff @(posedge CLK or negedge RSTN) begin
    if (!RSTN) begin
      QN <= '0;
    end
    else if (REB) begin
      QN <= mem_core[AB];
    end
  end

  assign Q = QN;

endmodule
