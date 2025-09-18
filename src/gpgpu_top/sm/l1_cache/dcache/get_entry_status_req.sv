`timescale 1ns/1ns

module get_entry_status_req #(
  parameter NUM_ENTRY = 4
)(
  input  logic [NUM_ENTRY-1:0]         valid_list_i,
  output logic                         alm_full_o  ,
  output logic                         full_o      ,
  output logic [$clog2(NUM_ENTRY)-1:0] next_o      
);

  localparam ENTRY_WIDTH = $clog2(NUM_ENTRY) + 1;

  logic [ENTRY_WIDTH-1:0] used;
  logic [NUM_ENTRY-1:0]   valid_list_reverse;
  
  pop_cnt #(
    .DATA_LEN (NUM_ENTRY  ),
    .DATA_WID (ENTRY_WIDTH)
  )
  used_count (
    .data_i (valid_list_i),
    .data_o (used        )
  );

  assign alm_full_o = used == (NUM_ENTRY - 1);
  assign full_o     = &valid_list_i          ;

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
    .target (1'b0              ),
    .data_o (next_o            )
  );

endmodule

