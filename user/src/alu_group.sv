module alu_group(
    input clk,
    input rst_n,

    input [2:0] dispatch_dest,
    input [31:0] data_o_1[32],
    input [31:0] data_o_2[32],
    input [102:0] dispatched_request,

    output logic [31:0] results_o[32],
    output logic tready_alu
);
    logic [31:0] rs1[16];
    logic [31:0] rs2[16];
    logic [31:0] imm;
    logic [31:0] results[16];
    logic [7:0] opcode;

    genvar i;
    generate 
        for(i=0;i<16;i++) begin
            _alu alu_inst(
                .opcode(opcode),
                .rs1(rs1[i]),
                .rs2(rs2[i]),
                .imm(imm),
                .result(results[i])
            );
        end
    endgenerate

    // 状态机
    typedef enum logic[1:0] {
        IDLE,
        FIRST_16,
        SECOND_16
    } alu_states_t;
    alu_states_t state;
    logic [31:0] data_o_1_reg[32];
    logic [31:0] data_o_2_reg[32];
    logic [102:0] dispatched_request_reg;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            state<=IDLE;
            tready_alu<=0;
            results_o<='{default:0};
            data_o_1_reg<='{default:0};
            data_o_2_reg<='{default:0};
            dispatched_request_reg<=0;
        end
        else begin
            case(state) 
                IDLE: begin
                    tready_alu<=0;
                    if(dispatch_dest[2]) begin
                        for(int i=0;i<16;i++) begin
                            logic [62:0] dispatched_instruction;
                            dispatched_instruction=dispatched_request[97:35];
                            rs1[i]<=data_o_1[i];
                            rs2[i]<=data_o_2[i];
                            imm<=dispatched_instruction[39:8];
                            opcode<=dispatched_instruction[47:40];
                        end
                        state<=FIRST_16;
                    end
                    else state<=IDLE;

                    dispatched_request_reg<=dispatched_request;
                    data_o_1_reg<=data_o_1;
                    data_o_2_reg<=data_o_2;
                end
                FIRST_16: begin
                    for(int i=0;i<16;i++) begin
                        results_o[i]<=results[i];
                    end
                    for(int i=0;i<16;i++) begin
                        logic [62:0] dispatched_instruction;
                        dispatched_instruction=dispatched_request_reg[97:35];
                        rs1[i]<=data_o_1_reg[i+16];
                        rs2[i]<=data_o_2_reg[i+16];
                        imm<=dispatched_instruction[39:8];
                        opcode<=dispatched_instruction[47:40];
                    end

                    state<=SECOND_16;
                end
                SECOND_16: begin
                    for(int i=0;i<16;i++) begin
                        results_o[i+16]<=results[i];
                    end
                    tready_alu<=1;
                    state<=IDLE;
                end
            endcase
        end
    end
endmodule