`timescale 1ns/1ns

module pop_cnt #(
  parameter DATA_LEN = 4,
  parameter DATA_WID = 3
  )
  (
  input  logic [DATA_LEN-1:0] data_i,
  output logic [DATA_WID-1:0] data_o 
  );
  
  logic [(DATA_LEN-1)*DATA_WID-1:0] count;

  genvar i;
  generate for(i=0;i<DATA_LEN-1;i=i+1) begin:B1
    always_comb begin
      if(i == 0) begin
        count[DATA_WID*(i+1)-1 -: DATA_WID] = data_i[i] + data_i[i+1];
      end 
      else begin
        count[DATA_WID*(i+1)-1 -: DATA_WID] = count[DATA_WID*i-1 -: DATA_WID] + data_i[i+1];
      end 
    end 
  end 
  endgenerate

  assign data_o = count[(DATA_LEN-1)*DATA_WID-1 -: DATA_WID];

endmodule
