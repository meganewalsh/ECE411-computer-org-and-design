module shift_reg(
	input logic clk,
	input logic en,
	input logic data_in,
	
	output logic [2:0] data_out
);

logic [2:0] data = '{default: '0};
assign data_out = data;

always @(posedge clk) begin

	if (en) begin
		data = data << 1'b1;
		data[0] = data_in;
	end
	
end
endmodule : shift_reg
