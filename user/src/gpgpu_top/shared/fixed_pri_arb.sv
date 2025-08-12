`timescale 1ns/1ns

module fixed_pri_arb #(
  parameter int ARB_WIDTH = 4
  ) 
  (
  input  logic [ARB_WIDTH-1:0] req  ,
  output logic [ARB_WIDTH-1:0] grant
  );

  logic [ARB_WIDTH-1:0] pre_req;

  assign pre_req = {(req[ARB_WIDTH-2:0] | pre_req[ARB_WIDTH-2:0]),1'h0};
  assign grant = req & (~pre_req);

endmodule
