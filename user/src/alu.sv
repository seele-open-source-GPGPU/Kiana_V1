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

module _alu (
    input [31:0] rs1,
    input [31:0] rs2,
    input [31:0] imm,
    input [7:0] opcode,
    output [31:0] result
);
    logic [31:0] op_a,op_b;
    alu_op_t alu_op;
    alu (
        .operand_a(op_a),
        .operand_b(op_b),
        .alu_op(alu_op),
        .result(result)
    );
    always_comb begin
        case(opcode)
            14: begin
                op_a=rs1;
                op_b=imm;
                alu_op=ALU_ADD;
            end
            15: begin
                op_a=rs1;
                op_b=imm;
                alu_op=ALU_SLT;
            end
            16: begin
                op_a=rs1;
                op_b=imm;
                alu_op=ALU_SLTU;
            end
            17: begin
                op_a=rs1;
                op_b=imm;
                alu_op=ALU_XOR;
            end
            18: begin
                op_a=rs1;
                op_b=imm;
                alu_op=ALU_OR;
            end
            19: begin
                op_a=rs1;
                op_b=imm;
                alu_op=ALU_AND;
            end
            20: begin
                op_a=rs1;
                op_b=imm;
                alu_op=ALU_SLL;
            end
            21: begin
                op_a=rs1;
                op_b=imm;
                alu_op=ALU_SRL;
            end
            22: begin
                op_a=rs1;
                op_b=imm;
                alu_op=ALU_SRA;
            end
////////////////////
            23: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_ADD;
            end
            24: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_SUB;
            end
            25: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_SLL;
            end
            26: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_SLT;
            end
            27: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_SLTU;
            end
            28: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_XOR;
            end
            29: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_SRL;
            end
            30: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_SRA;
            end
            31: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_OR;
            end
            32: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_AND;
            end
            default: begin
                op_a=rs1;
                op_b=rs2;
                alu_op=ALU_NOP;
            end
        endcase
    end
endmodule