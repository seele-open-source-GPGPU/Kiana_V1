`timescale 1ns/1ns

module one2bin #(
  parameter int ONE_WIDTH = 4,
  parameter int BIN_WIDTH = 2
)(
  input  logic [ONE_WIDTH-1:0] oh ,
  output logic [BIN_WIDTH-1:0] bin
);

  logic [BIN_WIDTH-1:0] bin_temp1 [0:ONE_WIDTH-1];
  logic [ONE_WIDTH-1:0] bin_temp2 [0:BIN_WIDTH-1];

  genvar i, j, k;

  generate
    for (i = 0; i < ONE_WIDTH; i = i + 1) begin : B1
      assign bin_temp1[i] = oh[i] ? i : '0;
    end
  endgenerate

  generate
    for (i = 0; i < ONE_WIDTH; i = i + 1) begin : B2
      for (j = 0; j < BIN_WIDTH; j = j + 1) begin : B3
        assign bin_temp2[j][i] = bin_temp1[i][j];
      end
    end
  endgenerate

  generate
    for (k = 0; k < BIN_WIDTH; k = k + 1) begin : B4
      assign bin[k] = |bin_temp2[k];
    end
  endgenerate

endmodule
