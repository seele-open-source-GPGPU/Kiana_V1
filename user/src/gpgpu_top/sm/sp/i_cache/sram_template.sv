`timescale 1ns/1ns

module sram_template #(
  parameter int GEN_WIDTH = 32 ,   
  parameter int NUM_SET   = 32 ,
  parameter int NUM_WAY   = 2  , //way should >= 1
  parameter int SET_DEPTH = 5  ,
  parameter int WAY_DEPTH = 1  
  )
  (
  input  logic                          clk            ,
  input  logic                          rst_n          ,
  input  logic                          r_req_valid_i  ,
  input  logic  [SET_DEPTH-1:0]         r_req_setid_i  , 
  output logic [NUM_WAY*GEN_WIDTH-1:0]  r_resp_data_o  , //[GEN_WIDTH-1:0] [0:NUM_WAY-1
  input  logic                          w_req_valid_i  ,
  input  logic  [SET_DEPTH-1:0]         w_req_setid_i  ,
  input  logic  [NUM_WAY-1:0]           w_req_waymask_i,
  input  logic  [NUM_WAY*GEN_WIDTH-1:0] w_req_data_i       
  );
  logic bypass_mask;
  logic [NUM_WAY*GEN_WIDTH-1:0] Q;
  logic [NUM_WAY*GEN_WIDTH-1:0] w_req_data_i_1; 
  logic [NUM_WAY*GEN_WIDTH-1:0] w_way_mask ;
  logic read_sram_en;

  genvar k;
  generate for (k=0;k<NUM_WAY;k=k+1) begin:gen_w_mask
    assign w_way_mask [GEN_WIDTH*k+:GEN_WIDTH] = (w_req_waymask_i[k]) ? {GEN_WIDTH{1'b1}} : {GEN_WIDTH{1'b0}}; 
  end
  endgenerate
  
  assign read_sram_en = r_req_valid_i && !(w_req_valid_i && r_req_valid_i && (w_req_setid_i == r_req_setid_i)); 
  
  dualportSRAM #(
  .BITWIDTH     (NUM_WAY*GEN_WIDTH    ),        
  .DEPTH        (SET_DEPTH            ))
  dualportSRAM  (
  .CLK          (clk          ),
  .RSTN         (rst_n        ),
  .D            (w_req_data_i ),
  .Q            (Q            ),
  .REB          (read_sram_en ),
  .WEB          (w_req_valid_i),
  .BWEB         (w_way_mask   ),
  .AA           (w_req_setid_i),
  .AB           (r_req_setid_i));

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      bypass_mask <= 1'b0;
    end
    else if(w_req_valid_i && r_req_valid_i && (w_req_setid_i == r_req_setid_i)) 
    begin
      bypass_mask <= 1'b1;      
    end 
    else 
      bypass_mask <= 1'b0;
  end    
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      w_req_data_i_1 <= 'h0;
    end
    else w_req_data_i_1 <= w_req_data_i;
  end

  assign r_resp_data_o = bypass_mask ? w_req_data_i_1 : Q; 

endmodule
