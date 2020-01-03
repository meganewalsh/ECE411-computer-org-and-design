module vcache_data_array (
	input logic clk,
	input logic read,
	input logic [255:0] datain,
	input logic [31:0] write_en,
	
	output logic [255:0] dataout
);

logic [255:0] data = '{default: '0};
assign dataout = data;


always_ff @(posedge clk)
begin
    for (int i = 0; i < 32; i++) begin
		data[8*i +: 8] <= write_en[i] ? datain[8*i +: 8] : data[8*i +: 8];
    end
end


endmodule : vcache_data_array
