`timescale 1ns/1ns

module stream_fifo_pipe_true #(
  parameter int DATA_WIDTH = 32,
  parameter int FIFO_DEPTH = 4  //can't be zero
  )(
  input  logic                  clk      ,
  input  logic                  rst_n    ,

  output logic                  w_ready_o,
  input  logic                  w_valid_i,
  input  logic [DATA_WIDTH-1:0] w_data_i ,
  
  output logic                  r_valid_o,
  input  logic                  r_ready_i,
  output logic [DATA_WIDTH-1:0] r_data_o 
  );

  logic push,pop;
  logic empty,full;
  logic [DATA_WIDTH-1:0] r_data_fifo;

  assign pop  = (r_ready_i && !empty);
  assign push = w_valid_i && (!full | r_ready_i);

  assign w_ready_o = !full | r_ready_i;
  assign r_valid_o = !empty;

  assign r_data_o = r_data_fifo;

  fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
    )
   fifo_pipe(
    .clk     (clk        ),
    .rst_n   (rst_n      ),
    .w_en_i  (push       ),
    .r_en_i  (pop        ),
    .w_data_i(w_data_i   ),
    .r_data_o(r_data_fifo),
    .full_o  (full       ),
    .empty_o (empty      )
    );

endmodule

