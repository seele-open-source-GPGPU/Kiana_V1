module dual_sram#(parameter DATA_WIDTH=4,parameter ADDR_WIDTH=4)(
    input rst,

    input rclk,
    input r_en,
    input [ADDR_WIDTH-1:0] r_addr,
    output logic[DATA_WIDTH-1:0] r_data,

    input wclk,
    input w_en,
    input [ADDR_WIDTH-1:0] w_addr,
    input [DATA_WIDTH-1:0] w_data
);
    logic [DATA_WIDTH-1:0] mem [1<<ADDR_WIDTH];
    always_ff @(posedge wclk or posedge rst) begin
        if(rst) mem<='{default:0};
        else if(w_en) mem[w_addr]<=w_data;
    end
    always_ff @(posedge rclk or posedge rst) begin
        if(rst) r_data<=0;
        else if(r_en) r_data<=mem[r_addr];
        else r_data<='z;
    end
endmodule

module sync_fifo#(parameter DEPTH,parameter WIDTH)(
    input clk,
    input rst,
    input[WIDTH-1:0] w_data,
    input w_en, // write valid
    input r_en, // read valid
    output [WIDTH-1:0] r_data,
    output logic full, 
    output logic r_data_valid,
    output logic empty // !read ready
);
    generate
        if(DEPTH!=1) begin
            localparam ADDR_WIDTH=$clog2(DEPTH);
            logic[ADDR_WIDTH:0] w_ptr,r_ptr;
            logic[ADDR_WIDTH:0] w_ptr_next,r_ptr_next;
            logic full_i,empty_i,r_data_valid_next;

            dual_sram #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(WIDTH)
            ) sram(
                .rst(rst),
                .rclk(clk),
                .r_en(r_en),
                .r_addr(r_ptr[ADDR_WIDTH-1:0]),
                .r_data(r_data),
                .wclk(clk),
                .w_en(w_en),
                .w_addr(w_ptr[ADDR_WIDTH-1:0]),
                .w_data(w_data)
            );
            always_ff @(posedge clk or posedge rst) begin
                if(rst) begin
                    w_ptr<=0;
                    r_ptr<=0;
                    r_data_valid<=0;
                end
                else begin
                    w_ptr<=w_ptr_next;
                    r_ptr<=r_ptr_next;
                    r_data_valid<=r_data_valid_next;
                end
            end
            always_comb begin
                if(w_en && !full_i) begin
                    w_ptr_next[ADDR_WIDTH-1:0] =(w_ptr[ADDR_WIDTH-1:0]==DEPTH-1) ? 0 : w_ptr[ADDR_WIDTH-1:0]+1;
                    w_ptr_next[ADDR_WIDTH]     =(w_ptr[ADDR_WIDTH-1:0]==DEPTH-1) ^ w_ptr[ADDR_WIDTH];
                end
                else w_ptr_next=w_ptr;

                if(r_en && !empty_i) begin
                    r_ptr_next[ADDR_WIDTH-1:0] =(r_ptr[ADDR_WIDTH-1:0]==DEPTH-1)   ? 0 : r_ptr[ADDR_WIDTH-1:0]+1;
                    r_ptr_next[ADDR_WIDTH]     =(r_ptr[ADDR_WIDTH-1:0]==DEPTH-1)   ^ r_ptr[ADDR_WIDTH];
                    r_data_valid_next=1;
                end
                else begin
                    r_ptr_next=r_ptr;
                    r_data_valid_next=0;
                end

                full = (w_ptr_next[ADDR_WIDTH-1:0]==r_ptr_next[ADDR_WIDTH-1:0]) && (w_ptr_next[ADDR_WIDTH]^r_ptr_next[ADDR_WIDTH]);
                full_i = (w_ptr[ADDR_WIDTH-1:0]==r_ptr[ADDR_WIDTH-1:0]) && (w_ptr[ADDR_WIDTH]^r_ptr[ADDR_WIDTH]);

                empty_i = w_ptr==r_ptr;
                empty = w_ptr_next==r_ptr_next;
            end
        end else begin
            logic w_ptr,r_ptr;
            logic w_ptr_next,r_ptr_next;
            logic empty_i,full_i;
            logic r_data_valid_next;
            logic [WIDTH-1:0] storage,r_data_i;

            always_ff@(posedge clk or posedge rst) begin
                if(rst) begin
                    storage<=0;
                    w_ptr<=0;
                    r_ptr<=0;
                    r_data_valid<=0;
                end
                else begin
                    w_ptr<=w_ptr_next;
                    r_ptr<=r_ptr_next;
                    r_data_valid<=r_data_valid_next;
                    if(w_en && ~full_i) storage<=w_data;
                    if(r_en && ~empty_i) r_data_i<=storage;
                end
            end
            assign r_data=r_data_i;
            always_comb begin
                w_ptr_next=(w_en && ~full_i) ^ w_ptr;
                r_ptr_next=(r_en && ~empty_i) ^ r_ptr;
                r_data_valid_next=r_en && ~empty_i;

                full_i= w_ptr ^ r_ptr;
                full=   w_ptr_next ^ r_ptr_next;
                empty_i=w_ptr == r_ptr;
                empty=  w_ptr_next == r_ptr_next;
            end
        end
    endgenerate
endmodule