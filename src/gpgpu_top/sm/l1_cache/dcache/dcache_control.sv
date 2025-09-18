`timescale 1ns/1ns

module dcache_control (
  input  logic [2:0] opcode       ,
  input  logic [3:0] param        ,
  output logic       is_read      ,
  output logic       is_write     ,
  output logic       is_lr        ,
  output logic       is_sc        ,
  output logic       is_amo       ,
  output logic       is_flush     ,
  output logic       is_invalidate,
  output logic       is_wait_mshr 
);

  assign is_read       = ((opcode==3'b000) && (param==4'b0000)) ? 'd1 : 'd0;
  assign is_write      = ((opcode==3'b001) && (param==4'b0000)) ? 'd1 : 'd0;
  assign is_lr         = ((opcode==3'b000) && (param==4'b0001)) ? 'd1 : 'd0;
  assign is_sc         = ((opcode==3'b001) && (param==4'b0001)) ? 'd1 : 'd0;
  assign is_amo        = (opcode==3'b010)                                  ;
  assign is_flush      = ((opcode==3'b011) && (param==4'b0001)) ? 'd1 : 'd0;
  assign is_invalidate = ((opcode==3'b011) && (param==4'b0000)) ? 'd1 : 'd0;
  assign is_wait_mshr  = ((opcode==3'b011) && (param==4'b0010)) ? 'd1 : 'd0;

endmodule

