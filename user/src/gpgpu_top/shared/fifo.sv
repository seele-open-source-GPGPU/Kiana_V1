`timescale 1ns/1ns

module fifo #(
  parameter int DATA_WIDTH = 32,
  parameter int FIFO_DEPTH = 4  // 不能为 0
)(
  input  logic                  clk     ,
  input  logic                  rst_n   ,
  input  logic                  w_en_i  ,
  input  logic                  r_en_i  ,
  input  logic [DATA_WIDTH-1:0] w_data_i,
  output logic [DATA_WIDTH-1:0] r_data_o,
  output logic                  full_o  ,
  output logic                  empty_o
);

  localparam int ADDR_WIDTH = (FIFO_DEPTH == 1) ? 1 : $clog2(FIFO_DEPTH);

  // 存储器
  logic [FIFO_DEPTH*DATA_WIDTH-1:0] dual_port_ram;

  logic [ADDR_WIDTH:0] w_ptr, r_ptr;
  logic [ADDR_WIDTH-1:0] w_addr, r_addr;

  // 写指针
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w_ptr <= '0;
    end
    else if (w_en_i) begin
      w_ptr <= (FIFO_DEPTH == 1) ? w_ptr + 2 : w_ptr + 1;
    end
    else begin
      w_ptr <= w_ptr;
    end
  end

  // 读指针
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r_ptr <= '0;
    end
    else if (r_en_i) begin
      r_ptr <= (FIFO_DEPTH == 1) ? r_ptr + 2 : r_ptr + 1;
    end
    else begin
      r_ptr <= r_ptr;
    end
  end

  assign w_addr = w_ptr[ADDR_WIDTH-1:0];
  assign r_addr = r_ptr[ADDR_WIDTH-1:0];

  // 写数据
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dual_port_ram <= '0;
    end
    else if (w_en_i /*&& !full_o*/) begin
      dual_port_ram[(DATA_WIDTH*(w_addr+1)-1)-:DATA_WIDTH] <= w_data_i;
    end
    else begin
      dual_port_ram <= dual_port_ram;
    end
  end

  // 读数据
  assign r_data_o = dual_port_ram[(DATA_WIDTH*(r_addr+1)-1)-:DATA_WIDTH];

  // 满/空标志
  assign full_o  = (r_ptr == {~w_ptr[ADDR_WIDTH], w_ptr[ADDR_WIDTH-1:0]});
  assign empty_o = (r_ptr == w_ptr);

endmodule
