module array32(

    input clk,
    input load,
    input [2:0] index,
    input [31:0] datain,
	 
    output logic [31:0] dataout
	 
);

logic [31:0] data [7:0] = '{default: '0};
logic [31:0] _dataout;

assign dataout = data[index];

always_ff @(posedge clk)
begin
    if(load)
        data[index] <= datain;
end

endmodule : array32