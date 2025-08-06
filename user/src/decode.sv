`include "common.svh"
import common::*;
module decode(
    input clk,
    input rst_n,
    input s_tvalid,
    input [31:0] instruction,
    input [4:0]  warp_id_in,
    input s_tlast,

    output logic [4:0] warp_id_out,
    output logic m_tvalid,
    output logic [4:0] rd,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [7:0] opcode,
    output logic [31:0] imm,
    output logic m_tlast,
    output logic [7:0] feature_flags, // [0]:alu [1]:lsu [2]:write_pc [3]:depends on pc [4]:write_pred [5]:depends on pred
    output logic [31:0] err
);
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            m_tvalid<=0;
            rd<=0;
            rs1<=0;
            rs2<=0;
            opcode<=8'hff;
            imm<=0;
            feature_flags<=0;
            warp_id_out<=0; 
            err<=0;
            m_tlast<=0;
        end
        else begin
            m_tlast<=s_tlast;
            warp_id_out<=warp_id_in;
            if(s_tvalid) begin
                case (instruction[6:0])
                    7'b1100011: begin // B-type
                        m_tvalid<=1;
                        rs1<=instruction[19:15];
                        rs2<=instruction[24:20];
                        imm<={8'b0,instruction[31:26],2'b0,8'b0,instruction[25],instruction[11:7],2'b0};
                        rd<='1;
                        case (instruction[14:12])
                            3'b000: opcode<=0;  
                            3'b001: opcode<=1;  
                            3'b100: opcode<=2;  
                            3'b101: opcode<=3;  
                            3'b110: opcode<=4;  
                            3'b111: opcode<=5;  
                            default: opcode<='1;
                        endcase
                        feature_flags<=8'b0011_1101;
                    end 
                    7'b0000011:begin // L-type
                        m_tvalid<=1;
                        rs1<=instruction[19:15];
                        rs2<='1;
                        imm<='1;
                        rd<=instruction[11:7];
                        case (instruction[14:12])
                            3'b000: opcode<=6;  
                            3'b001: opcode<=7;  
                            3'b010: opcode<=8;  
                            3'b100: opcode<=9;  
                            3'b101: opcode<=10;  
                            default: opcode<='1;
                        endcase
                        feature_flags<=8'b0010_1010;
                    end
                    7'b0100011:begin // S-type
                        m_tvalid<=1;
                        rs1<=instruction[19:15];
                        rs2<=instruction[24:20];
                        imm<='1;
                        rd<='1;
                        case (instruction[14:12])
                            3'b000: opcode<=11;  
                            3'b001: opcode<=12;  
                            3'b010: opcode<=13;  
                            default: opcode<='1;
                        endcase
                        feature_flags<=8'b0010_1010;
                    end
                    7'b0010011:begin // I-type
                        m_tvalid<=1;
                        rs1<=instruction[19:15];
                        rs2<='1;
                        case ({instruction[31:25],instruction[14:12]})
                            10'b0000000_000: imm<={{20{instruction[31]}},instruction[31:20]};  
                            10'b0000000_010: imm<={{20{instruction[31]}},instruction[31:20]};  
                            10'b0000000_011: imm<={20'b0,instruction[31:20]};  
                            10'b0000000_100: imm<={{20{instruction[31]}},instruction[31:20]};  
                            10'b0000000_110: imm<={{20{instruction[31]}},instruction[31:20]};  
                            10'b0000000_111: imm<={{20{instruction[31]}},instruction[31:20]};  
                            10'b0000000_001: imm<={27'b0,instruction[24:20]};  
                            10'b0000000_101: imm<={27'b0,instruction[24:20]};  
                            10'b0100000_101: imm<={{27{instruction[24]}},instruction[24:20]};  
                            default: imm<='1;
                        endcase
                        rd<=instruction[11:7];
                        case ({instruction[31:25],instruction[14:12]})
                            10'b0000000_000: opcode<=14;
                            10'b0000000_010: opcode<=15;
                            10'b0000000_011: opcode<=16;
                            10'b0000000_100: opcode<=17;
                            10'b0000000_110: opcode<=18;
                            10'b0000000_111: opcode<=19;
                            10'b0000000_001: opcode<=20;
                            10'b0000000_101: opcode<=21;
                            10'b0100000_101: opcode<=22;
                            default: opcode<='1;
                        endcase
                        feature_flags<=8'b0010_1001;
                    end
                    7'b0110011:begin // R-type
                        m_tvalid<=1;
                        rs1<=instruction[19:15];
                        rs2<=instruction[24:20];
                        imm<='1;
                        rd<=instruction[11:7];
                        case ({instruction[31:25],instruction[14:12]})
                            10'b0000000_000: opcode<=23;
                            10'b0100000_000: opcode<=24;
                            10'b0000000_001: opcode<=25;
                            10'b0000000_010: opcode<=26;
                            10'b0000000_011: opcode<=27;
                            10'b0000000_100: opcode<=28;
                            10'b0000000_101: opcode<=29;
                            10'b0100000_101: opcode<=30;
                            10'b0000000_110: opcode<=31;
                            10'b0000000_111: opcode<=32;
                            default: opcode<='1;
                        endcase
                        feature_flags<=8'b0010_1001;
                    end
                    7'b0001111:begin // I-type
                        m_tvalid<=1;
                        rs1<='1;
                        rs2<='1;
                        rd<='1;
                        imm<='1;
                        case (instruction[14:12])
                            3'b000: opcode<=33;  
                            3'b001: opcode<=34;  
                            3'b010: opcode<=35;  
                            default: opcode<='1;
                        endcase
                        case (instruction[14:12])
                            3'b000: feature_flags<=8'b0000_1000;
                            3'b001: feature_flags<=8'b0000_1010;  
                            3'b010: feature_flags<=8'b0000_1000;
                            default: feature_flags<=8'b0000_0000;
                        endcase
                    end
                    7'b1101111:begin // J-type jal
                        m_tvalid<=1;
                        rs1<='1;
                        rs2<='1;
                        rd<=instruction[11:7];
                        imm<={10'b0,instruction[31:12],2'b0};
                        opcode<=36;
                        feature_flags<=8'b0000_1101;
                    end
                    7'b1100111:begin // J-type jalr
                        m_tvalid<=1;
                        rs1<=instruction[19:15];
                        rs2<='1;
                        rd<=instruction[11:7];
                        imm<={18'b0,instruction[31:20],2'b0};
                        opcode<=37;
                        feature_flags<=8'b0000_1101;
                    end
                    7'b0110111:begin // U-type lui
                        m_tvalid<=1;
                        rs1<='1;
                        rs2<='1;
                        rd<=instruction[11:7];
                        imm<={instruction[31:12],12'b0};
                        opcode<=38;
                        feature_flags<=8'b0010_1000;
                    end
                    7'b0010111:begin // U-type auipc
                        m_tvalid<=1;
                        rs1<='1;
                        rs2<='1;
                        rd<=instruction[11:7];
                        imm<={instruction[31:12],12'b0};
                        opcode<=39;
                        feature_flags<=8'b0010_1000;
                    end
                    7'b1110011:begin // P-type
                        m_tvalid<=1;
                        rs1<='1;
                        rs2<='1;
                        rd<='1;
                        if(instruction[14:12]==3'b101) imm<={3'b0,instruction[31:21],2'b0,3'b0,instruction[20:15],instruction[11:7],2'b0};
                        else imm<='1;
                        case (instruction[14:12])
                            3'b101: opcode<=40;  
                            3'b110: opcode<=41;  
                            3'b111: opcode<=42;
                            default: opcode<='1;
                        endcase
                        case (instruction[14:12])
                            3'b101: feature_flags<=8'b0011_1100;
                            3'b110: feature_flags<=8'b0011_1100; 
                            3'b111: feature_flags<=8'b0011_1100; 
                            default: feature_flags<=8'b0000_0000;
                        endcase
                    end
                    default: begin
                        m_tvalid<=0;
                        err<=`KIANA_SP_ERR_DECODER_WRONG_INSTRUCTION_FORMAT;
                    end
                endcase
            end
        end
    end
endmodule 
