module riscy_icache_data_array (
    input logic clk,
    input logic [31:0] write_en,
    input logic [255:0] in,
    output logic [255:0] out
);

logic [255:0] data;
assign out = data;

/* Initialize array */
initial
begin
    data = 1'b0;
end

always_ff @(posedge clk)
begin
    for (int i = 0; i < 32; i++)
    begin
		data[8*i +: 8] <= write_en[i] ? in[8*i +: 8] : data[8*i +: 8];
    end
end

endmodule : riscy_icache_data_array

