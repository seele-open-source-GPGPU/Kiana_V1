`timescale 1ns/1ps

module tag_checker #(
  parameter NUM_WAY   = 24   ,
  parameter TAG_BITS  = 2     
)
(
  input  logic [TAG_BITS*NUM_WAY-1:0]  tag_of_set_i        ,
  input  logic [TAG_BITS-1:0]          tag_from_pipe_i     ,
  input  logic [NUM_WAY-1:0]           valid_of_way_i      ,
  output logic [NUM_WAY-1:0]           waymask_o           , //  onehot
  output logic                         cache_hit_o          

);

  genvar i;
  generate
    for(i=0; i<NUM_WAY; i=i+1) begin:way_loop
      assign waymask_o[i] = tag_of_set_i[TAG_BITS*(i+1)-1-:TAG_BITS]==tag_from_pipe_i && valid_of_way_i[i];
    end
  endgenerate

  assign  cache_hit_o = |waymask_o;


endmodule
