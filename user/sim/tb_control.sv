`timescale 1ns/1ns
module tb_control();
    logic clk, rst_n;
    logic initialize;
    logic [31:0] next_pc[32];
    logic [4:0] warp_id[32];
    // output declaration of module fetch
    wire [4:0] warp_id_from_fetch_to_icache;
    wire [31:0] selected_pc_from_fetch_to_icache;
    wire s_tready_from_fetch_to_ib_sb;
    wire m_tvalid_from_fetch_to_icache;
    wire m_tlast_from_fetch_to_icache;

    // output declaration of module access_instruction_cache
    wire [4:0] selected_warp_id_from_icache_to_decoders;
    wire m_tvalid_from_icache_to_decoder;
    wire m_tlast_from_icache_to_decoder;
    wire [31:0] instruction_from_icache_to_decoder;

    // output declaration of module decode
    wire [4:0] warp_id_out_from_decode_to_ib_sb;
    wire m_tvalid_from_decode_to_ib_sb;
    wire [4:0] rd_from_decode_to_ib_sb;
    wire [4:0] rs1_from_decode_to_ib_sb;
    wire [4:0] rs2_from_decode_to_ib_sb;
    wire [7:0] opcode_from_decode_to_ib_sb;
    wire [31:0] imm_from_decode_to_ib_sb;
    wire m_tlast_from_decode_to_ib_sb;
    wire [7:0] feature_flags_from_decode_to_ib_sb;
    
    // output declaration of module instruction_buffer_and_scoreboard
    wire [31:0] warp_ready_mask;
    wire [62:0] instruction_buffer;
    wire m_tvalid_fetch_ib_sb_to_fetch;
    wire [31:0] warp_fetch_mask_ib_sb_to_fetch;

    fetch u_fetch(
        .clk              	(clk),
        .rst_n            	(rst_n),
        .initialize       	(initialize),
        .next_pc          	(next_pc),
        .warp_id          	(warp_id),
        .warp_mask        	(warp_fetch_mask_ib_sb_to_fetch),
        .selected_warp_id 	(warp_id_from_fetch_to_icache),
        .selected_pc      	(selected_pc_from_fetch_to_icache),
        .s_tvalid         	(m_tvalid_fetch_ib_sb_to_fetch),
        .s_tready         	(s_tready_from_fetch_to_ib_sb),
        .m_tvalid         	(m_tvalid_from_fetch_to_icache),
        .m_tlast          	(m_tlast_from_fetch_to_icache),
        .err              	()
    );

    access_instruction_cache u_access_instruction_cache(
        .clk                	(clk),
        .rst_n              	(rst_n),
        .selected_warp_id   	(warp_id_from_fetch_to_icache),
        .selected_pc        	(selected_pc_from_fetch_to_icache),
        .s_tvalid           	(m_tvalid_from_fetch_to_icache),
        .s_tlast            	(m_tlast_from_fetch_to_icache),
        .o_selected_warp_id 	(selected_warp_id_from_icache_to_decoders),
        .m_tvalid           	(m_tvalid_from_icache_to_decoder),
        .m_tlast            	(m_tlast_from_icache_to_decoder),
        .o_instruction      	(instruction_from_icache_to_decoder)
    );

    decode u_decode(
        .clk               	(clk),
        .rst_n             	(rst_n),
        .s_tvalid          	(m_tvalid_from_icache_to_decoder),
        .instruction       	(instruction_from_icache_to_decoder),
        .warp_id_in        	(selected_warp_id_from_icache_to_decoders),
        .s_tlast           	(m_tlast_from_icache_to_decoder),
        .warp_id_out       	(warp_id_out_from_decode_to_ib_sb),
        .m_tvalid          	(m_tvalid_from_decode_to_ib_sb),
        .rd                	(rd_from_decode_to_ib_sb),
        .rs1               	(rs1_from_decode_to_ib_sb),
        .rs2               	(rs2_from_decode_to_ib_sb),
        .opcode            	(opcode_from_decode_to_ib_sb),
        .imm               	(imm_from_decode_to_ib_sb),
        .m_tlast           	(m_tlast_from_decode_to_ib_sb),
        .feature_flags 	(feature_flags_from_decode_to_ib_sb  ),
        .err               	()
    );
    
    instruction_buffer_and_scoreboard u_instruction_buffer_and_scoreboard(
        .clk                   	(clk),
        .rst_n                 	(rst_n),
        .warp_id_decoder        	(warp_id_out_from_decode_to_ib_sb),
        .s_tvalid_decoder       	(m_tvalid_from_decode_to_ib_sb),
        .s_tlast_decoder        	(m_tlast_from_decode_to_ib_sb),
        .rd                    	(rd_from_decode_to_ib_sb),
        .rs1                   	(rs1_from_decode_to_ib_sb),
        .rs2                   	(rs2_from_decode_to_ib_sb),
        .opcode                	(opcode_from_decode_to_ib_sb),
        .imm                   	(imm_from_decode_to_ib_sb),
        .feature_flags     	(feature_flags_from_decode_to_ib_sb),
        .target_warp           	(),
        .target_gpr_in         	(),
        .target_unir_in        	(),
        .target_is_pc          	(),
        .target_is_pred        	(),
        .s_tvalid_schedular    	(),
        .warp_ready_mask       	(),
        .instruction_buffer    	(),
        .m_tready_fetch        	(s_tready_from_fetch_to_ib_sb),
        .m_tvalid_fetch        	(m_tvalid_fetch_ib_sb_to_fetch),
        .warp_fetch_mask       	(warp_fetch_mask_ib_sb_to_fetch),
        .s_tvalid_rf           	(),
        .finish_wr_warp_id_rf  	(),
        .finish_wr_gpr         	(),
        .finish_wr_unir        	(),
        .s_tvalid_bar          	(),
        .finish_wr_warp_id_bar 	(),
        .is_finish_update_pc   	(),
        .is_finish_update_pred 	(),
        .err                   	()
    );
    // 时钟生成
    initial clk = 0;
    always #5 clk = ~clk;
    clocking cb @(posedge clk);
        default input #1 output #1;
        output initialize,next_pc,warp_id;
    endclocking
    // 波形输出（可选）
    initial begin
        // $dumpfile("../control_tb.vcd");
        $dumpvars(0);
        rst_n=1;
        initialize=0;
        next_pc='{default:0};
        warp_id='{default:0};
        #1 rst_n=0;
        #1 rst_n=1;
        @cb;
        cb.initialize<=1;
        for (int i = 0; i < 32; i++) begin
            cb.next_pc[i] <= 32'h0000_1000;
            cb.warp_id[i] <= i;
        end
        @cb;
        cb.initialize<=0;

        repeat(60) @cb;
        $dumpflush;
        #1 $finish;
    end
endmodule 