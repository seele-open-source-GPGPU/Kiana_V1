`include "sp_defines.svh"

// typedef struct {
//     logic [6:0] Opcode;
//     logic [4:0] SrcReg1;
//     logic [4:0] SrcReg2;
//     logic [4:0] DstReg;
//     logic [31:0] Imm;
//     logic [2:0] Funct3;
//     logic [6:0] Funct7;
// } Instruction_t;
module decoder(
    input                   clk,
    input                   rst_n,
    // 输入
    input                   tvalid_i,
    input                   tlast_i,
    input [`NUM_WARP-1:0]   warp_id_mask_i,
    input [31:0]            instruction_i,
    // 输出
    output logic            tvalid_o,
    output logic            tlast_o,
    output Instruction_t    instruction_o,
    output [`NUM_WARP-1:0]  warp_id_mask_o,
    output [$clog2(`NUM_WARP)-1:0]   warp_id_o
);
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            tvalid_o<=0;
            tlast_o<=0;
            warp_id_mask_o<=0;
            warp_id_o<=0;
            instruction_o.Opcode   <= 0;
            instruction_o.SrcReg1  <= 0;
            instruction_o.SrcReg2  <= 0;
            instruction_o.DstReg   <= 0;
            instruction_o.Imm      <= 0;
            instruction_o.Csr      <= 0;
            instruction_o.Funct3   <= 0;
            instruction_o.AluOp    <= ALU_NOP;
            instruction_o.LsuOp    <= LSU_NON;
            instruction_o.BranchOp <= NOP;
            instruction_o.ControlOp<= Ctrl_Non;
            instruction_o.UnpredictablePC   <= 0;
            instruction_o.UseALU   <= 0;
            instruction_o.UseLSU   <= 0;
            instruction_o.UseCtrl   <= 0;
            instruction_o.UseBranch<=0;
        end
        else begin
            tvalid_o<=tvalid_i;
            tlast_o<=tlast_i;
            warp_id_mask_o<=warp_id_mask_i;
            warp_id_o<=onehot_to_bin_num_warp(warp_id_mask_i);
            instruction_o.Opcode   <= 0;
            instruction_o.SrcReg1  <= 0;
            instruction_o.SrcReg2  <= 0;
            instruction_o.DstReg   <= 0;
            instruction_o.Imm      <= 0;
            instruction_o.Csr      <= 0;
            instruction_o.Funct3   <= 0;
            instruction_o.AluOp    <= ALU_NOP;
            instruction_o.LsuOp    <= LSU_NON;
            instruction_o.BranchOp <= NOP;
            instruction_o.ControlOp<= Ctrl_Non;
            instruction_o.UnpredictablePC   <= 0;
            instruction_o.UseALU   <= 0;
            instruction_o.UseLSU   <= 0;
            instruction_o.UseCtrl   <= 0;
            instruction_o.UseBranch<=0;
            case(instruction_i[6:0])
                7'b0110111: begin // lui
                    instruction_o.Opcode<=instruction_i[6:0];
                    instruction_o.DstReg<=instruction_i[11:7];
                    instruction_o.Imm<={instruction_i[31:12],12'b0};
                    instruction_o.ControlOp<=Lui;
                    instruction_o.UseCtrl   <= 1;
                end
                7'b0010111: begin // auipc
                    instruction_o.Opcode<=instruction_i[6:0];
                    instruction_o.DstReg<=instruction_i[11:7];
                    instruction_o.Imm<={instruction_i[31:12],12'b0};
                    instruction_o.ControlOp<=Auipc;
                    instruction_o.UseCtrl   <= 1;
                end
                7'b1101111: begin // jal
                    instruction_o.Opcode  <= instruction_i[6:0];
                    instruction_o.DstReg  <= instruction_i[11:7];

                    instruction_o.Imm <= {{11{instruction_i[31]}},
                        instruction_i[31], instruction_i[19:12],
                        instruction_i[20], instruction_i[30:21], 1'b0};
                    instruction_o.BranchOp<=JUMP;
                    instruction_o.UseBranch<=1;
                    instruction_o.UnpredictablePC<=1;
                end
                7'b1100111: begin // jalr
                    instruction_o.Opcode  <= instruction_i[6:0];
                    instruction_o.SrcReg1 <= instruction_i[19:15];
                    instruction_o.DstReg  <= instruction_i[11:7];
                    instruction_o.Imm     <= {{20{instruction_i[31]}}, instruction_i[31:20]};
                    instruction_o.Funct3  <= instruction_i[14:12];
                    instruction_o.BranchOp<=JUMP;
                    instruction_o.UseBranch<=1;
                    instruction_o.UnpredictablePC<=1;
                end
                7'b1100011: begin // b-type
                    instruction_o.Opcode  <= instruction_i[6:0];
                    instruction_o.SrcReg1 <= instruction_i[19:15];
                    instruction_o.SrcReg2 <= instruction_i[24:20];
                    instruction_o.Funct3  <= instruction_i[14:12];
                    instruction_o.Imm <= {{19{instruction_i[31]}},
                        instruction_i[31], instruction_i[7],
                        instruction_i[30:25], instruction_i[11:8], 1'b0};
                    instruction_o.BranchOp<=BRANCH;
                    instruction_o.UseBranch<=1;
                    instruction_o.UnpredictablePC<=1;
                end
                7'b0000011: begin // LB/LH/LW/LBU/LHU
                    instruction_o.Opcode  <= instruction_i[6:0];
                    instruction_o.SrcReg1 <= instruction_i[19:15];
                    instruction_o.DstReg  <= instruction_i[11:7];
                    instruction_o.Imm     <= {{20{instruction_i[31]}}, instruction_i[31:20]};
                    instruction_o.Funct3  <= instruction_i[14:12];
                    case(instruction_i[14:12])
                        3'b000: instruction_o.LsuOp<=LSU_LOAD_BYTE;
                        3'b001: instruction_o.LsuOp<=LSU_LOAD_HALF_WORD;
                        3'b010: instruction_o.LsuOp<=LSU_LOAD_WORD;
                        3'b100: instruction_o.LsuOp<=LSU_LOAD_BYTE;
                        3'b101: instruction_o.LsuOp<=LSU_LOAD_HALF_WORD;
                        default: instruction_o.LsuOp<=LSU_NON;
                    endcase
                    instruction_o.UseLSU<=1;
                end
                7'b0100011: begin // SB/SH/SW
                    instruction_o.Opcode  <= instruction_i[6:0];
                    instruction_o.SrcReg1 <= instruction_i[19:15];
                    instruction_o.SrcReg2 <= instruction_i[24:20];

                    instruction_o.Imm <= {{20{instruction_i[31]}},
                        instruction_i[31:25], instruction_i[11:7]};

                    instruction_o.Funct3  <= instruction_i[14:12];
                    case(instruction_i[14:12])
                        3'b000: instruction_o.LsuOp<=LSU_STORE_BYTE;
                        3'b001: instruction_o.LsuOp<=LSU_STORE_HALF_WORD;
                        3'b010: instruction_o.LsuOp<=LSU_STORE_WORD;
                        default: instruction_o.LsuOp<=LSU_NON;
                    endcase
                    instruction_o.UseLSU<=1;
                end
                7'b0010011: begin // 立即数运算
                    instruction_o.Opcode  <= instruction_i[6:0];
                    instruction_o.SrcReg1 <= instruction_i[19:15];
                    instruction_o.DstReg  <= instruction_i[11:7];
                    instruction_o.Funct3  <= instruction_i[14:12];
                    instruction_o.UseALU<=1;
                    case (instruction_i[14:12])
                        3'b001, 3'b101: begin // SLLI / SRLI / SRAI
                            instruction_o.Imm    <= {27'b0, instruction_i[24:20]};
                        end
                        default: begin
                            instruction_o.Imm    <= {{20{instruction_i[31]}}, instruction_i[31:20]};
                        end
                    endcase
                    case (instruction_i[14:12])
                        3'b000: instruction_o.AluOp<=ALU_ADD;
                        3'b010: instruction_o.AluOp<=ALU_SLT;
                        3'b011: instruction_o.AluOp<=ALU_SLTU;
                        3'b100: instruction_o.AluOp<=ALU_XOR;
                        3'b110: instruction_o.AluOp<=ALU_OR;
                        3'b111: instruction_o.AluOp<=ALU_AND;
                        3'b001: instruction_o.AluOp<=ALU_SLL;
                        3'b101: begin
                            if(instruction_i[30]) instruction_o.AluOp<=ALU_SRA;
                            else instruction_o.AluOp<=ALU_SRL;
                        end
                        default: instruction_o.AluOp<=ALU_NOP;
                    endcase
                end
                7'b0110011: begin // 寄存器运算
                    instruction_o.Opcode  <= instruction_i[6:0];
                    instruction_o.SrcReg1 <= instruction_i[19:15];
                    instruction_o.SrcReg2 <= instruction_i[24:20];
                    instruction_o.DstReg  <= instruction_i[11:7];
                    instruction_o.UseALU<=1;
                    case (instruction_i[14:12])
                        3'b000: begin
                            if(instruction_i[30]) instruction_o.AluOp<=ALU_SUB;
                            else instruction_o.AluOp<=ALU_ADD;
                        end
                        3'b001: instruction_o.AluOp<=ALU_SLL;
                        3'b010: instruction_o.AluOp<=ALU_SLT;
                        3'b011: instruction_o.AluOp<=ALU_SLTU;
                        3'b100: instruction_o.AluOp<=ALU_XOR;
                        3'b110: instruction_o.AluOp<=ALU_OR;
                        3'b111: instruction_o.AluOp<=ALU_AND;
                        3'b101: begin
                            if(instruction_i[30]) instruction_o.AluOp<=ALU_SRA;
                            else instruction_o.AluOp<=ALU_SRL;
                        end
                        default: instruction_o.AluOp<=ALU_NOP;
                    endcase
                    instruction_o.Funct3  <= instruction_i[14:12];
                end
                7'b0001111: begin // 内存屏障
                    instruction_o.Opcode  <= instruction_i[6:0];
                    instruction_o.Imm     <= {24'b0,instruction_i[27:20]};

                    instruction_o.Funct3  <= 0;
                    instruction_o.ControlOp     <=Fence;
                    instruction_o.UseCtrl   <= 1;
                end
                7'b0000010: begin // 自定义指令
                    instruction_o.Opcode  <= instruction_i[6:0];
                    instruction_o.SrcReg1 <= instruction_i[19:15];
                    if(instruction_i[14:12]==3'b111) begin
                        instruction_o.Imm     <= {{14{instruction_i[31]}},instruction_i[31:20],instruction_i[11:7],1'b0};
                        instruction_o.BranchOp<=SETRPC;
                        instruction_o.UseBranch<=1;
                        instruction_o.UnpredictablePC<=1;
                    end
                    else if(instruction_i[14:12]==3'b101) begin
                        instruction_o.Imm     <= {{10{instruction_i[31]}},instruction_i[31:15],instruction_i[11:7]};
                        instruction_o.BranchOp<=PUSH;
                        instruction_o.UseBranch<=1;
                        instruction_o.UnpredictablePC<=1;
                    end
                    else if(instruction_i[14:12]==3'b110) begin
                        instruction_o.BranchOp<=POP;
                        instruction_o.UseBranch<=1;
                        instruction_o.UnpredictablePC<=1;
                    end
                    else if(instruction_i[14:12]==3'b010) begin
                        instruction_o.BranchOp<=FLUSH;
                        instruction_o.UseBranch<=1;
                        instruction_o.UnpredictablePC<=1;
                    end
                    else instruction_o.Imm<=0;
                        
                    if(instruction_i[14:12]==3'b001) begin
                        instruction_o.ControlOp<=SoftIr;
                        instruction_o.UseCtrl   <= 1;
                    end
                    else if(instruction_i[14:12]==3'b000) begin
                        if(instruction_i[24:20]==0) instruction_o.ControlOp<=SyncWorkGroup;
                        else if(instruction_i[24:20]==1) instruction_o.ControlOp<=SyncWarp;
                        else if(instruction_i[24:20]==2) instruction_o.ControlOp<=SyncGlobal;
                        instruction_o.UseCtrl   <= 1;
                    end
                    else if(instruction_i[14:12]==3'b100) begin
                        instruction_o.ControlOp<=Ret;   
                        instruction_o.UseCtrl   <= 1;
                    end
                    instruction_o.Funct3  <= instruction_i[14:12];
                end
                7'b1110011: begin // CSR
                    instruction_o.Opcode    <= instruction_i[6:0];
                    instruction_o.SrcReg1   <= instruction_i[19:15];
                    instruction_o.DstReg    <= instruction_i[11:7];
                    instruction_o.Imm       <= {27'b0,instruction_i[19:15]};

                    instruction_o.Funct3    <= instruction_i[14:12];
                    instruction_o.Csr       <= instruction_i[31:20];
                    instruction_o.UseCtrl   <= 1;
                    case (instruction_i[14:12])
                        3'b001: instruction_o.ControlOp<=CsrRw;
                        3'b010: instruction_o.ControlOp<=CsrRs;
                        3'b011: instruction_o.ControlOp<=CsrRc;
                        3'b101: instruction_o.ControlOp<=CsrRwi;
                        3'b110: instruction_o.ControlOp<=CsrRsi;
                        3'b111: instruction_o.ControlOp<=CsrRci;
                    endcase
                end
                default: begin
                    instruction_o.Opcode   <= 0;
                    instruction_o.SrcReg1  <= 0;
                    instruction_o.SrcReg2  <= 0;
                    instruction_o.DstReg   <= 0;
                    instruction_o.Imm      <= 0;
                    instruction_o.Csr      <= 0;
                    instruction_o.Funct3   <= 0;
                    instruction_o.AluOp    <= ALU_NOP;
                    instruction_o.LsuOp    <= LSU_NON;
                    instruction_o.BranchOp <= NOP;
                    instruction_o.ControlOp<= Ctrl_Non;
                    instruction_o.UnpredictablePC   <= 0;
                    instruction_o.UseALU   <= 0;
                    instruction_o.UseLSU   <= 0;
                    instruction_o.UseCtrl   <= 0;
                    instruction_o.UseBranch<=0;
                end
            endcase
        end
    end
endmodule 
