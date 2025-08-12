module rr_arbiter #(
    parameter int N = 4
)(
    input  logic         clk,
    input  logic         rst_n,
    input  logic [N-1:0] req,
    output logic [$clog2(N)-1:0] grant   
);
    logic [$clog2(N)-1:0] last_grant_idx;
    logic [N-1:0] grant_next;
    logic [N-1:0] rotated_req;
    logic [N-1:0] rotated_grant;
    logic [N-1:0] unrotated_grant;
    logic [$clog2(N)-1:0] offset;

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            last_grant_idx <= '0;
            grant          <= '0;
        end else begin
            if (|req) begin
                offset = last_grant_idx + 1;
                rotated_req = (req >> offset) | (req << (N - offset));
                rotated_grant = rotated_req & (~(rotated_req - 1));
                unrotated_grant = (rotated_grant << offset) | (rotated_grant >> (N - offset));
                grant_next = unrotated_grant;
                for (int i = 0; i < N; i++) begin
                    if (grant_next[i])
                        grant = i;
                end
                last_grant_idx <= grant;
            end else begin
                grant = last_grant_idx;
                last_grant_idx <= last_grant_idx;
            end
        end
    end
endmodule
