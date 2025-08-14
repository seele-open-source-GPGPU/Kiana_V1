// 接收指令，取出操作数并放入fifo
module issue(
    input clk,
    input rst_n,

    output logic m_tready_issue_fifo,
    input m_tvalid_request,
    input [102:0] dispatch_request,

    // 从寄存器文件输入操作数
    output logic [4:0] reg_file_read_warp_id,

    input oprand_1_data_valid,
    input [31:0] oprand_1_data[32],
    output logic [4:0] oprand_1_addr,
    output logic oprand_1_request,

    input oprand_2_data_valid,
    input [31:0] oprand_2_data[32],
    output logic [4:0] oprand_2_addr,
    output logic oprand_2_request,

    output logic issue_fifo_empty,
    output logic [31:0] data_o_1[32],
    output logic [31:0] data_o_2[32],

    output logic err
);
    // 再译码一下
    logic has_rs1,has_rs2,has_imm;
    // 驱动寄存器文件
    typedef enum logic [1:0] {
        IDLE,
        WAITING_FOR_OPRAND,
        OK_TO_DISPATCH
    } oprand_collector_states_t;

    oprand_collector_states_t state;
    // m_tready_issue_fifo要延迟一拍更新
    logic [2:0] has_rs1_rs2_imm;
    logic [31:0] oprand_1_temp_store[32];
    logic [31:0] oprand_2_temp_store[32];
    logic [102:0] dispatch_request_reg;
    logic oprand_get;
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            oprand_1_addr<=0;
            oprand_1_request<=0;
            oprand_2_addr<=0;
            oprand_2_request<=0;

            has_rs1_rs2_imm<=0;
            oprand_1_temp_store<='{default:0};
            oprand_2_temp_store<='{default:0};
            oprand_get<=0;

            dispatch_request_reg<=0;
            state<=IDLE;
        end
        else begin
            logic _err;
            case(state)
                IDLE: begin
                    if(m_tvalid_request) begin
                        logic [4:0] rs1,rs2;
                        logic [62:0] dispatched_instruction;
                        dispatch_request_reg<dispatch_request
                        dispatched_instruction=dispatch_request[97:35];
                        rs1=dispatched_instruction[57:53];
                        rs2=dispatched_instruction[52:48];
                        has_rs1_rs2_imm<=get_has_rs1_rs2_imm(dispatched_instruction);
                        
                        reg_file_read_warp_id<=dispatch_request[102:98];
                        if(~&rs1) begin
                            oprand_1_addr<=rs1;
                            oprand_1_request<=1;
                        end
                        else oprand_1_request<=0;

                        if(~&rs2) begin
                            oprand_2_addr<=rs2;
                            oprand_2_request<=1;
                        end
                        else oprand_2_request<=0;

                        m_tready_issue_fifo<=0;
                        if(has_rs1_rs2_imm[2] | has_rs1_rs2_imm[1]) begin
                            state<=PUSH_TO_FIFO;
                        end
                        else begin
                            state<=WAITING_FOR_OPRAND;
                        end
                    end
                    else begin
                        m_tready_issue_fifo<=1;
                        state<=IDLE;
                    end
                    oprand_get<=0;
                end
                WAITING_FOR_OPRAND: begin
                    if(oprand_1_data_valid) begin
                        oprand_1_temp_store<=oprand_1_data;
                        oprand_get[0]<=1;
                    end
                    if(oprand_2_data_valid) begin
                        oprand_2_temp_store<=oprand_2_data;
                        oprand_get[1]<=1;
                    end

                    if(&oprand_get) state<=OK_TO_DISPATCH;
                    else state<=WAITING_FOR_OPRAND;
                end
                OK_TO_DISPATCH: begin
                    else state<=IDLE;
                end
            endcase
            
        end
    end
    function automatic logic[2:0] get_has_rs1_rs2_imm(input [62:0] dispatched_instruction);
        logic [7:0] opcode;
        logic has_rs1,has_rs2,has_imm;
        dispatched_instruction=dispatch_request[97:35];
        opcode=dispatched_instruction[47:40];
        if(opcode<6) begin
            has_rs1=1;
            has_rs2=1;
            has_imm=1;
        end  
        else if(opcode<11) begin
            has_rs1=1;
            has_rs2=0;
            has_imm=0;
        end
        else if(opcode<14) begin
            has_rs1=1;
            has_rs2=1;
            has_imm=0;
        end
        else if(opcode<23) begin
            has_rs1=1;
            has_rs2=0;
            has_imm=1;
        end
        else if(opcode<33) begin
            has_rs1=1;
            has_rs2=1;
            has_imm=0;
        end
        else if(opcode<36) begin
            has_rs1=0;
            has_rs2=0;
            has_imm=0;
        end
        else if(opcode<37) begin
            has_rs1=0;
            has_rs2=0;
            has_imm=1;
        end
        else if(opcode<38) begin
            has_rs1=1;
            has_rs2=0;
            has_imm=1;
        end
        else if(opcode<40) begin
            has_rs1=0;
            has_rs2=0;
            has_imm=1;
        end
        else if(opcode<41) begin
            has_rs1=0;
            has_rs2=0;
            has_imm=1;
        end
        else if(opcode<43) begin
            has_rs1=0;
            has_rs2=0;
            has_imm=0;
        end
        else begin
            has_rs1=0;
            has_rs2=0;
            has_imm=0;
        end
        return {has_rs1,has_rs2,has_imm};
    endfunction
    // issue_fifo   
    logic [2047:0]  
    
endmodule 
