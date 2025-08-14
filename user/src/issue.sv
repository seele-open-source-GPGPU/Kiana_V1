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
    input [31:0] oprand_1_data,
    output logic [4:0] oprand_1_addr,
    output logic oprand_1_request,

    input oprand_2_data_valid,
    input [31:0] oprand_2_data,
    output logic [4:0] oprand_2_addr,
    output logic oprand_2_request,

    output logic issue_fifo_empty,
    output logic [31:0] data_o_1[31:0],
    output logic [31:0] data_o_2[31:0],

    output logic err
);
    // 驱动寄存器文件
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            oprand_1_addr<=0;
            oprand_1_request<=0;
            oprand_2_addr<=0;
            oprand_2_request<=0;
        end
        else begin
            logic _err;
            if(m_tvalid_request) begin
                logic [4:0] rs1,rs2;
                logic [62:0] dispatched_instruction;
                dispatched_instruction=dispatch_request[97:35];
                rs1=dispatched_instruction[57:53];
                rs2=dispatched_instruction[52:48];
                
                reg_file_read_warp_id<=dispatch_request[102:98];
                if(&rs1) begin
                    oprand_1_addr<=rs1;
                    oprand_1_request<=1;
                end
                else oprand_1_request<=0;

                if(&rs2) begin
                    oprand_2_addr<=rs2;
                    oprand_2_request<=1;
                end
                else oprand_2_request<=0;
            end
        end
    end
    
endmodule 
