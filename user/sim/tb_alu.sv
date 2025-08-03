`timescale 1ns/1ps
`include "../src/common.svh"
import common::*;

module tb_alu;

    // DUT I/O
    logic [31:0] OperandA, OperandB;
    alu_op_t ALUOp;
    logic [31:0] Result;

    // Reference value
    logic signed [31:0] A_signed, B_signed;
    logic [31:0] Expected;
    int num_tests = 10000;

    // DUT instance
    alu dut (
        .operand_a(OperandA),
        .operand_b(OperandB),
        .alu_op(ALUOp),
        .result(Result)
    );

    task automatic check(input string opname);
        if (Result !== Expected) begin
            $display("[FAIL] %-6s A=%0d B=%0d => Result=%0d Expected=%0d", opname, OperandA, OperandB, Result, Expected);
        end else begin
            // $display("[PASS] %-6s A=%0d B=%0d => Result=%0d", opname, OperandA, OperandB, Result);
        end
    endtask

    initial begin
        $dumpfile("../dump.vcd");
        $dumpvars(0);
        $display("==== Start ALU Tests ====");
        for (int i = 0; i < num_tests; i++) begin
            OperandA = $urandom;
            OperandB = $urandom;
            A_signed = OperandA;
            B_signed = OperandB;

            // Test ADD
            ALUOp = ALU_ADD;
            #1 Expected = OperandA + OperandB;
            #1 check("ADD");

            // Test SUB
            ALUOp = ALU_SUB;
            #1 Expected = OperandA - OperandB;
            #1 check("SUB");

            // Test AND
            ALUOp = ALU_AND;
            #1 Expected = OperandA & OperandB;
            #1 check("AND");

            // Test OR
            ALUOp = ALU_OR;
            #1 Expected = OperandA | OperandB;
            #1 check("OR");

            // Test XOR
            ALUOp = ALU_XOR;
            #1 Expected = OperandA ^ OperandB;
            #1 check("XOR");

            // Test SLL
            ALUOp = ALU_SLL;
            #1 Expected = OperandA << OperandB[4:0];
            #1 check("SLL");

            // Test SRL
            ALUOp = ALU_SRL;
            #1 Expected = OperandA >> OperandB[4:0];
            #1 check("SRL");

            // Test SRA
            ALUOp = ALU_SRA;
            #1 Expected = A_signed >>> OperandB[4:0];
            #1 check("SRA");

            // Test SLT
            ALUOp = ALU_SLT;
            #1 Expected = (A_signed < B_signed) ? 32'd1 : 32'd0;
            #1 check("SLT");

            // Test SLTU
            ALUOp = ALU_SLTU;
            #1 Expected = (OperandA < OperandB) ? 32'd1 : 32'd0;
            #1 check("SLTU");

            // Test NOP (default)
            ALUOp = ALU_NOP;
            #1 Expected = 32'hE2202;
            #1 check("NOP");
        end
        
        $display("==== ALU Tests Complete ====");
        $dumpflush;
        #1 $finish;
    end

endmodule
