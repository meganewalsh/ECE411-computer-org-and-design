module vcache_array #(parameter width = 1) (
	input logic clk,
   input logic [width-1:0] in,
	input logic load,
	input logic read,
	
   output logic [width-1:0] out
);

logic [width-1:0] data = '{default: '0};
assign out = data;

always_ff @(posedge clk) begin
	data = (load) ? in : data;
end

endmodule : vcache_array
