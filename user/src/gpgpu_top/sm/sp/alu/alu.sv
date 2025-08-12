`include "common.svh"
import common::*;
module alu (
    input [31:0] operand_a,
    input [31:0] operand_b,
    input  alu_op_t      alu_op,
    output logic [31:0] result
);

    logic signed [31:0] a_signed, b_signed;

    assign a_signed = operand_a;
    assign b_signed = operand_b;

    always_comb begin
        if (alu_op == ALU_ADD || alu_op == ALU_SUB) begin
            result = operand_a + ((alu_op == ALU_SUB) ? (~operand_b+1) : operand_b);
        end else if (alu_op == ALU_AND) begin
            result = operand_a & operand_b;
        end else if (alu_op == ALU_OR) begin
            result = operand_a | operand_b;
        end else if (alu_op == ALU_XOR) begin
            result = operand_a ^ operand_b;
        end else if (alu_op == ALU_SLL) begin
            result = operand_a << operand_b[4:0];
        end else if (alu_op == ALU_SRL) begin
            result = operand_a >> operand_b[4:0];
        end else if (alu_op == ALU_SRA) begin
            result = a_signed >>> operand_b[4:0];
        end else if (alu_op == ALU_SLT) begin
            result = (a_signed < b_signed) ? 32'd1 : 32'd0;
        end else if (alu_op == ALU_SLTU) begin
            result = (operand_a < operand_b) ? 32'd1 : 32'd0;
        end else begin
            result = 32'hE2202;
        end
    end

endmodule