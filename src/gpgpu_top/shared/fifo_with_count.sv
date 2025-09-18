`timescale 1ns/1ns

module fifo_with_count #(
  parameter DATA_WIDTH = 32,
  parameter FIFO_DEPTH = 4 ,//can't be zero
  parameter CNT_WIDTH  = 2
  )
  (
  input  logic                  clk     ,
  input  logic                  rst_n   ,
  input  logic                  w_en_i  ,
  input  logic                  r_en_i  ,
  input  logic [DATA_WIDTH-1:0] w_data_i,
  output logic [DATA_WIDTH-1:0] r_data_o,
  output logic                  full_o  ,
  output logic                  empty_o ,
  output logic [CNT_WIDTH-1:0]  count_o 
  );

  localparam ADDR_WIDTH = (FIFO_DEPTH == 1) ? 1 : $clog2(FIFO_DEPTH);
  
  //reg [DATA_WIDTH-1:0] dual_port_ram [0:FIFO_DEPTH-1];
  logic [FIFO_DEPTH*DATA_WIDTH-1:0] dual_port_ram;
  logic [ADDR_WIDTH:0]   w_ptr,r_ptr;
  logic [ADDR_WIDTH-1:0] w_addr,r_addr;

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      w_ptr <= 'd0;
    end
    else if(w_en_i) begin
      w_ptr <= (FIFO_DEPTH == 1) ? (w_ptr + 2) : (w_ptr + 1);
    end
    else begin
      w_ptr <= w_ptr;
    end
  end
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      r_ptr <= 'd0;
    end
    else if(r_en_i) begin
      r_ptr <= (FIFO_DEPTH == 1) ? (r_ptr + 2) : (r_ptr + 1);
    end
    else begin
      r_ptr <= r_ptr;
    end
  end
  
  assign w_addr = w_ptr[ADDR_WIDTH-1:0];
  assign r_addr = r_ptr[ADDR_WIDTH-1:0];
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      dual_port_ram <= 'h0;
    end 
    else if(w_en_i && !full_o) begin
      dual_port_ram[(DATA_WIDTH*(w_addr+1)-1)-:DATA_WIDTH] <= w_data_i;
    end 
    else begin
      dual_port_ram <= dual_port_ram;
    end 
  end
  
  assign r_data_o = dual_port_ram[(DATA_WIDTH*(r_addr+1)-1)-:DATA_WIDTH];

  assign full_o = (r_ptr == {~w_ptr[ADDR_WIDTH],w_ptr[ADDR_WIDTH-1:0]});
  assign empty_o = (r_ptr == w_ptr);

  assign count_o = (FIFO_DEPTH == 1) ? (w_ptr[ADDR_WIDTH] ^ r_ptr[ADDR_WIDTH]) : (w_ptr - r_ptr);

endmodule

