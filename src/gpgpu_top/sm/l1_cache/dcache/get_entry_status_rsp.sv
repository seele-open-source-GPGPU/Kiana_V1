`timescale 1ns/1ns

module get_entry_status_rsp #(
  parameter NUM_ENTRY = 4
)(
  input  logic [NUM_ENTRY-1:0]         valid_list_i ,
  output logic [$clog2(NUM_ENTRY)-1:0] next2cancel_o,
  output logic [$clog2(NUM_ENTRY):0]   used_o       
);

  logic [NUM_ENTRY-1:0] valid_list_reverse;

  input_reverse #(
    .DATA_WIDTH (NUM_ENTRY)
  )
  reverse_list (
    .data_i (valid_list_i      ),
    .data_o (valid_list_reverse)
  );

  find_first #(
    .DATA_WIDTH (NUM_ENTRY        ),
    .DATA_DEPTH ($clog2(NUM_ENTRY))
  )
  find_next (
    .data_i (valid_list_reverse),
    .target (1'b1              ),
    .data_o (next2cancel_o     )
  );

  pop_cnt #(
    .DATA_LEN (NUM_ENTRY          ),
    .DATA_WID ($clog2(NUM_ENTRY)+1)
  )
  used_count (
    .data_i (valid_list_i),
    .data_o (used_o      )
  );

endmodule

