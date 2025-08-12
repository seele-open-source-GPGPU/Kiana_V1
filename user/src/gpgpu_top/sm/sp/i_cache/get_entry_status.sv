`timescale 1ns/1ns

module get_entry_status #(
  parameter int NUM_ENTRY   = 4,
  parameter int ENTRY_DEPTH = 2,
  parameter int FIND_SEL    = 0
)(
  input  logic [NUM_ENTRY-1:0]   valid_list_i,
  output logic                   full_o,
  output logic [ENTRY_DEPTH-1:0] next_o
);

  logic [NUM_ENTRY-1:0]     valid_list_reverse;
  logic [ENTRY_DEPTH-1:0]   valid_data_range [0:NUM_ENTRY];

  assign full_o = &valid_list_i;

  // 反转输入
  genvar i;
  generate
    for (i = 0; i < NUM_ENTRY; i = i + 1) begin : B1
      assign valid_list_reverse[NUM_ENTRY-1-i] = valid_list_i[i];
    end
  endgenerate

  // 查找第一个满足条件的 entry
  assign valid_data_range[0] = '0;

  genvar j;
  generate
    for (j = 0; j < NUM_ENTRY; j = j + 1) begin : B2
      assign valid_data_range[j+1] =
        (valid_list_reverse[j] == FIND_SEL) ? NUM_ENTRY-1-j : valid_data_range[j];
    end
  endgenerate

  assign next_o = valid_data_range[NUM_ENTRY];

endmodule
