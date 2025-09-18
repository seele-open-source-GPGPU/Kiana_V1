`timescale 1ns/1ns

module input_reverse #(
  parameter DATA_WIDTH = 8
  )
  (
  input  logic [DATA_WIDTH-1:0] data_i,
  output logic [DATA_WIDTH-1:0] data_o
  );

  genvar i;
  generate for(i=0;i<DATA_WIDTH;i=i+1) begin:B1
    assign data_o[DATA_WIDTH-1-i] = data_i[i];
  end 
  endgenerate

endmodule
