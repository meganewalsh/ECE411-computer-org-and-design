module riscy_icache_array #(
	parameter width = 1
)
(
    input logic clk,
    input logic load,
    input logic [width-1:0] in,
    output logic [width-1:0] out
);

logic [width-1:0] data = '{default: '0};
assign out = data;

always_ff @(posedge clk)
begin
    data <= (load) ? in : data;
end

endmodule : riscy_icache_array

