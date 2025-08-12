`timescale 1ns/1ns

module tag_checker_icache #(
  parameter int TAG_WIDTH = 7,
  parameter int NUM_WAY   = 2, 
  parameter int WAY_DEPTH = 1 
  )
  (
  input  logic                         r_req_valid_i  ,
  input  logic [NUM_WAY*TAG_WIDTH-1:0] tag_of_set_i   ,
  input  logic [TAG_WIDTH-1:0]         tag_from_pipe_i,
  input  logic [NUM_WAY-1:0]           way_valid_i    ,//whether there is valid data
  output logic [WAY_DEPTH-1:0]         wayid_o        ,//bin
  output logic                         cache_hit_o     
  );
  
  logic [NUM_WAY-1:0] wayid_oh; //wayid_one_hot
  
  genvar i;
  generate for(i=0;i<NUM_WAY;i=i+1) begin:B1
    assign wayid_oh[i] = (r_req_valid_i && (tag_of_set_i[TAG_WIDTH*(i+1)-1 -: TAG_WIDTH] == tag_from_pipe_i) && way_valid_i[i]) ? '1 : '0;
  end 
  endgenerate

  assign cache_hit_o = |wayid_oh;
  
  one2bin #(
    .ONE_WIDTH(NUM_WAY  ),
    .BIN_WIDTH(WAY_DEPTH)
    ) o2b(
    .oh (wayid_oh),
    .bin(wayid_o )
    );

endmodule
