module instruction_cache(
    input clk,
    input rst_n,
    input [4:0] selected_warp_id,
    input [31:0] selected_pc,
    input s_tvalid,
    input s_tlast,

    output logic [4:0] o_selected_warp_id,
    output logic m_tvalid,
    output logic m_tlast,
    output logic [31:0] o_instruction
);
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            m_tlast<=0;
            m_tvalid<=0;
            o_selected_warp_id<=0;
            o_instruction<=0;
        end
        else begin
            m_tlast<=s_tlast;
            m_tvalid<=s_tvalid;
            o_selected_warp_id<=selected_warp_id;
            if(s_tvalid)
                case(selected_pc)
                    32'h0000_1000: o_instruction<=32'b1111111_00010_00001_000_11111_1100011;
                    default: o_instruction<='z;
                endcase
            else o_instruction<='z;
        end
    end
endmodule