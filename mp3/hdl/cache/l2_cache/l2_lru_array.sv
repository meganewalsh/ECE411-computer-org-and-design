module riscy_l2_lru_array (
    input clk,
    input load,
    input [2:0] index,
    input [1:0] mru,
    output [1:0] out
);

logic [7:0] i_load, i_load_in;

logic [1:0] i_mru, i_mru_in;

logic [1:0] i_out [7:0];

riscy_lru_array_4 arr [7:0] (
	.clk(clk),
	.load(i_load),
	.mru(i_mru),
	.out(i_out)
);

assign out = i_out[index];

assign i_mru_in = mru;

always_comb begin
    i_load_in = '0;
    i_load_in[index] = load;
end

always_ff @(posedge clk) begin
    i_load <= i_load_in;
    i_mru <= i_mru_in;
end

endmodule : riscy_l2_lru_array
