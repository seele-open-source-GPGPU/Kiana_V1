`timescale 1ns/1ns

module mshr_icache #(
  parameter int TI_WIDTH        = 7,
  parameter int BA_BITS         = 7,
  parameter int WID_BITS        = 2,
  parameter int NUM_ENTRY       = 4,
  parameter int NUM_SUB_ENTRY   = 4,
  parameter int ENTRY_DEPTH     = 2,
  parameter int SUB_ENTRY_DEPTH = 2
  )
  (
 input  logic                 clk                      ,
  input  logic                 rst_n                    ,
  
  input  logic                 miss_req_valid_i         ,
  input  logic [BA_BITS-1:0]   miss_req_block_addr_i    ,
  input  logic [TI_WIDTH-1:0]  miss_req_target_info_i   ,

  output logic                 miss_rsp_in_ready_o      ,
  input  logic                 miss_rsp_in_valid_i      ,
  input  logic [BA_BITS-1:0]   miss_rsp_in_block_addr_i ,

  input  logic                 miss_rsp_out_ready_i     ,
  output logic [BA_BITS-1:0]   miss_rsp_out_block_addr_o,

  input  logic                 miss2mem_ready_i         ,
  output logic                 miss2mem_valid_o         ,
  output logic [BA_BITS-1:0]   miss2mem_block_addr_o    ,
  output logic [WID_BITS-1:0]  miss2mem_instr_id_o 
  );

 logic miss_req_ready, miss_rsp_out_valid, miss_rsp_in_fire, miss_req_fire, miss_rsp_out_fire, miss2mem_fire;

  // 存储结构（按打平方式实现）
  logic [NUM_ENTRY*BA_BITS-1:0]                 blockAddr_Access;
  logic [NUM_ENTRY*NUM_SUB_ENTRY*TI_WIDTH-1:0]  targetInfo_Access;
  logic [NUM_ENTRY*NUM_SUB_ENTRY-1:0]           subentry_valid;

  logic [NUM_ENTRY-1:0] has_send2mem;

  logic [NUM_ENTRY-1:0]       entryMatchMissRsp, entryMatchMissReq;
  logic [ENTRY_DEPTH-1:0]     entryMatchMissRsp_bin, entryMatchMissReq_bin;

  logic [NUM_SUB_ENTRY-1:0]   subentry_valid_list_req;
  logic                       subentry_full_req;
  logic [SUB_ENTRY_DEPTH-1:0] subentry_next_req;

  logic [NUM_ENTRY-1:0]       entry_valid;
  logic                       entry_full;
  logic [ENTRY_DEPTH-1:0]     entry_next;
  
  logic primary_miss, secondary_miss;
  logic ReqConflictWithRsp;

  logic [ENTRY_DEPTH-1:0]     entry_id;
  logic [SUB_ENTRY_DEPTH-1:0] subentry_id;

  logic [NUM_ENTRY-1:0]       hasSendStatus_valid;
  logic                       hasSendStatus_full;
  logic [ENTRY_DEPTH-1:0]     hasSendStatus_next;

  logic                       req_rsp_same_time;

  assign miss_rsp_in_fire = miss_rsp_in_ready_o && miss_rsp_in_valid_i;
  assign miss_req_fire = miss_req_ready && miss_req_valid_i;
  assign miss_rsp_out_fire = miss_rsp_out_ready_i && miss_rsp_out_valid;
  assign miss2mem_fire = miss2mem_ready_i && miss2mem_valid_o;

  assign subentry_valid_list_req = subentry_valid[(NUM_SUB_ENTRY*(entryMatchMissReq_bin+1)-1)-:NUM_SUB_ENTRY];

  assign req_rsp_same_time = miss_rsp_in_fire && (miss_rsp_in_block_addr_i != miss_req_block_addr_i);

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      blockAddr_Access <= 'h0;
    end 
    else if(miss_req_fire && primary_miss) begin
      blockAddr_Access[(BA_BITS*(entry_next+1)-1)-:BA_BITS] <= miss_req_block_addr_i;
    end 
    else begin
      blockAddr_Access <= blockAddr_Access;
    end 
  end 
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      targetInfo_Access <= 'h0;
    end 
    else if(miss_req_fire) begin
      targetInfo_Access[((subentry_id+1)*TI_WIDTH*(entry_id+1)-1)-:TI_WIDTH] <= miss_req_target_info_i;
    end
    else begin
      targetInfo_Access <= targetInfo_Access;
    end 
  end 

  genvar i,j;
  generate for(i=0;i<NUM_ENTRY;i=i+1) begin:B1
    assign entry_valid[i] = |subentry_valid[(NUM_SUB_ENTRY*(i+1)-1)-:NUM_SUB_ENTRY];
    
    assign entryMatchMissRsp[i] = (blockAddr_Access[(BA_BITS*(i+1)-1)-:BA_BITS] == miss_rsp_in_block_addr_i) && entry_valid[i];

    assign entryMatchMissReq[i] = (blockAddr_Access[(BA_BITS*(i+1)-1)-:BA_BITS] == miss_req_block_addr_i) && entry_valid[i];

    assign hasSendStatus_valid[i] = ~((~has_send2mem[i]) && entry_valid[i]);

    always_ff @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        has_send2mem[i] <= 1'h0;
      end 
      else if(miss2mem_fire && (i == hasSendStatus_next)) begin
        has_send2mem[i] <= 1'h1;
      end 
      else if(miss_rsp_in_fire && miss_rsp_out_fire && (i == entryMatchMissRsp_bin)) begin
        has_send2mem[i] <= 1'h0;
      end 
      else begin
        has_send2mem[i] <= has_send2mem[i];
      end 
    end 

    for(j=0;j<NUM_SUB_ENTRY;j=j+1) begin:B2
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          subentry_valid[NUM_SUB_ENTRY*i+j] <= 'h0;
        end 
        else if(miss_req_fire) begin
          subentry_valid[NUM_SUB_ENTRY*i+j] <= (((i==entryMatchMissRsp_bin) && (j==0) && primary_miss && req_rsp_same_time && (entry_next > entryMatchMissRsp_bin)) ||
                                                ((i==entry_next) && (j==0) && primary_miss && !req_rsp_same_time) || 
                                                ((i==entry_next) && (j==0) && primary_miss && req_rsp_same_time && (entry_next <= entryMatchMissRsp_bin)) || 
                                                ((i==entryMatchMissReq_bin) && (j==subentry_next_req) && secondary_miss)) ? 1'h1 : 
                                                ((req_rsp_same_time && (i==entryMatchMissRsp_bin)) ? 1'b0 : subentry_valid[NUM_SUB_ENTRY*i+j]);
        end 
        else if(miss_rsp_out_fire) begin
          subentry_valid[NUM_SUB_ENTRY*i+j] <= (i == entryMatchMissRsp_bin) ? 'h0 : subentry_valid[NUM_SUB_ENTRY*i+j];
        end 
        else begin
          subentry_valid[NUM_SUB_ENTRY*i+j] <= subentry_valid[NUM_SUB_ENTRY*i+j];
        end 
      end 
    end 
  end 
  endgenerate

  assign primary_miss = !secondary_miss;
  assign secondary_miss = |entryMatchMissReq;

  assign entry_id = secondary_miss ? entryMatchMissReq_bin : entry_next;
  assign subentry_id = secondary_miss ? subentry_next_req : 'h0;
  
  assign miss_rsp_in_ready_o = miss_rsp_out_ready_i;
  assign miss_rsp_out_valid = miss_rsp_in_fire;

  assign miss2mem_valid_o = !has_send2mem[hasSendStatus_next] && entry_valid[hasSendStatus_next];
  assign miss2mem_block_addr_o = blockAddr_Access[(BA_BITS*(hasSendStatus_next+1)-1)-:BA_BITS];
  assign miss2mem_instr_id_o = targetInfo_Access[(TI_WIDTH*(hasSendStatus_next+1)-1)-:TI_WIDTH];

  assign miss_rsp_out_block_addr_o = blockAddr_Access[(BA_BITS*(entryMatchMissRsp_bin+1)-1)-:BA_BITS];
 
  assign ReqConflictWithRsp = miss_req_valid_i && miss_rsp_in_fire && (miss_rsp_in_block_addr_i == miss_req_block_addr_i);

  assign miss_req_ready = !((entry_full && primary_miss) || (subentry_full_req && secondary_miss) || ReqConflictWithRsp);

  get_entry_status #(
    .NUM_ENTRY  (NUM_ENTRY  ),
    .ENTRY_DEPTH(ENTRY_DEPTH),
    .FIND_SEL   (1'b0       )
    ) entryStatus(
    .valid_list_i(entry_valid),
    .full_o      (entry_full ),
    .next_o      (entry_next )
    );

  get_entry_status #(
    .NUM_ENTRY  (NUM_SUB_ENTRY  ),
    .ENTRY_DEPTH(SUB_ENTRY_DEPTH),
    .FIND_SEL   (1'b0           )
    ) subentryStatus(
    .valid_list_i(subentry_valid_list_req),
    .full_o      (subentry_full_req      ),
    .next_o      (subentry_next_req      )
    );
    
  get_entry_status #(
    .NUM_ENTRY  (NUM_ENTRY  ),
    .ENTRY_DEPTH(ENTRY_DEPTH),
    .FIND_SEL   (1'b0       )
    ) hasSendStatus(
    .valid_list_i(hasSendStatus_valid),
    .full_o      (hasSendStatus_full ),
    .next_o      (hasSendStatus_next )
    );

  one2bin #(
    .ONE_WIDTH(NUM_ENTRY  ),
    .BIN_WIDTH(ENTRY_DEPTH)
    ) one_to_bin_rsp(
    .oh (entryMatchMissRsp    ),
    .bin(entryMatchMissRsp_bin)
    );

  one2bin #(
    .ONE_WIDTH(NUM_ENTRY  ),
    .BIN_WIDTH(ENTRY_DEPTH)
    ) one_to_bin_req(
    .oh (entryMatchMissReq    ),
    .bin(entryMatchMissReq_bin)
    );

endmodule

/*-----------------------------------------------------------------------------
MSHR-ICACHE 概要说明
功能：
- 合并同块 I-Cache miss，减少下行请求：
  * primary miss：分配新 entry，登记块地址与 subentry0，向下一级发一次读请求
  * secondary miss：命中已有 entry，仅新增 subentry，等待回填
- 回填到来时按块地址匹配 entry，清空 subentries，释放 entry

核心状态机（单 entry 抽象）：
  EMPTY
    | primary miss
    v
  ALLOCATED_WAIT_SEND  (entry_valid=1, has_send2mem=0)
    | miss2mem_fire
    v
  SENT_WAIT_RSP        (entry_valid=1, has_send2mem=1)
    | miss_rsp_out_fire
    v
  EMPTY

关键信号：
- miss_req_*：登记 miss 请求，primary/secondary 判定 → entry_next 或 entryMatchMissReq_bin
- miss2mem_*：从“有效且未发送”的 entry（has_send2mem=0）选出下发下行读请求
- miss_rsp_in_* / miss_rsp_out_*：回填入口与出站握手；匹配 entryMatchMissRsp_bin，释放 entry
- entry_valid = |subentry_valid[i,*]
- has_send2mem[i]：标记该 entry 是否已下发过读请求
- get_entry_status / one2bin：用于空位/目标查找和 one-hot 编码转换

注意：
- 同拍 req 与 rsp（同块或不同块）有额外条件 req_rsp_same_time 防止竞态
- 全部存储结构按打平总线实现，查找逻辑为组合电路，fire 信号驱动寄存更新
-----------------------------------------------------------------------------*/
