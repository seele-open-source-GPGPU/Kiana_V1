`timescale 1ns/1ns

module find_first #(
  parameter DATA_WIDTH = 8,
  parameter DATA_DEPTH = 3
  )
  (
  input logic [DATA_WIDTH-1:0] data_i,
  input logic                  target,//fine one or zero
  output logic [DATA_DEPTH-1:0] data_o    
  );

  logic [DATA_DEPTH-1:0] data_range [0:DATA_WIDTH];

  assign data_range[0] = 'h0;

  genvar i;
  generate for(i=0;i<DATA_WIDTH;i=i+1) begin:B1
    assign data_range[i+1] = (data_i[i] == target) ? DATA_WIDTH-1-i : data_range[i];
  end 
  endgenerate

  assign data_o = data_range[DATA_WIDTH];

endmodule
