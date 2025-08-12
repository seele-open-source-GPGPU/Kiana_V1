`timescale 1ns/1ns

//作用：把前五位tag拿出来
module get_setid #(
  parameter int DATA_WIDTH       = 32,//data_i 的位宽（输入数据/地址的宽度）
  parameter int XLEN             = 32,//CPU 系统地址宽度 
  parameter int SETIDXBITS       = 5 ,//组索引位宽（例如 5 表示 2^5=32 组）
  parameter int BLOCK_OFFSETBITS = 1 ,//字内字节偏移所占位数 
  parameter int WORD_OFFSETBITS  = 1 ,//块内第几字 
  parameter int BA_BITS          = 6   
  )
  (
  input  logic [DATA_WIDTH-1:0] data_i,
  output logic [SETIDXBITS-1:0] data_o
  );

  assign data_o = (DATA_WIDTH == XLEN) ? data_i[SETIDXBITS+BLOCK_OFFSETBITS+WORD_OFFSETBITS-1:BLOCK_OFFSETBITS+WORD_OFFSETBITS] : 
                  ((DATA_WIDTH == BA_BITS) ? data_i[SETIDXBITS-1:0] : {DATA_WIDTH{1'h1}});
endmodule
