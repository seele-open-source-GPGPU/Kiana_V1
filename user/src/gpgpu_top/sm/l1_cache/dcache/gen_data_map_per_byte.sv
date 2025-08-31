`timescale 1ns/1ps

module gen_data_map_per_byte #(
  parameter DATA_NUM    = 4   ,
  parameter DATA_WIDTH  = 32
)
(
  input   logic  [DATA_WIDTH*DATA_NUM-1:0]   data_i        ,
  input   logic  [4*DATA_NUM-1:0]            mask_i        ,
  output  logic  [DATA_WIDTH*DATA_NUM-1:0]   data_o         
);

  genvar i;
  generate
    for(i=0; i<DATA_NUM; i=i+1) begin:output_loop
      always@(*) begin
        if(&mask_i[4*(i+1)-1-:4]) begin //  1111
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = data_i[DATA_WIDTH*(i+1)-1-:DATA_WIDTH];
        end else if(mask_i[4*(i+1)-1-:4]==4'b0001) begin  //  0001
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {24'b0,data_i[DATA_WIDTH*i+DATA_WIDTH/4-1-:DATA_WIDTH/4]};
        end else if(mask_i[4*(i+1)-1-:4]==4'b0010) begin  //  0010
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {16'b0,data_i[DATA_WIDTH*i+DATA_WIDTH/4-1-:DATA_WIDTH/4],8'b0};
        end else if(mask_i[4*(i+1)-1-:4]==4'b0100) begin  //  0100
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {8'b0,data_i[DATA_WIDTH*i+DATA_WIDTH/4-1-:DATA_WIDTH/4],16'b0};
        end else if(mask_i[4*(i+1)-1-:4]==4'b1000) begin  //  1000
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {data_i[DATA_WIDTH*i+DATA_WIDTH/4-1-:DATA_WIDTH/4],24'b0};
        end else if(mask_i[4*(i+1)-1-:4]==4'b1100) begin  //  1100
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {data_i[DATA_WIDTH*i+DATA_WIDTH/2-1-:DATA_WIDTH/2],{DATA_WIDTH/2{1'b0}}};
        end else if(mask_i[4*(i+1)-1-:4]==4'b0011) begin  //  0011
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {{DATA_WIDTH/2{1'b0}},data_i[DATA_WIDTH*i+DATA_WIDTH/2-1-:DATA_WIDTH/2]};
        end else begin
          data_o[DATA_WIDTH*(i+1)-1-:DATA_WIDTH] = {DATA_WIDTH{1'b0}};
        end
      end
    end
  endgenerate

endmodule
