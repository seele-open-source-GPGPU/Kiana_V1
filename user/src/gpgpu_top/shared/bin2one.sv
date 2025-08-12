`timescale 1ns/1ns

module bin2one #(
  parameter int ONE_WIDTH = 4,
  parameter int BIN_WIDTH = 2
  )
  (
  input  logic [BIN_WIDTH-1:0] bin ,
  output logic [ONE_WIDTH-1:0] oh
  );

  assign oh = ({{(ONE_WIDTH-1){1'b0}},1'b1}<<bin);

endmodule
