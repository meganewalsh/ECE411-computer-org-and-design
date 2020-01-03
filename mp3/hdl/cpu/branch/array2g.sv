module array2g (

    input clk,
    input load,
    input [2:0] if_rindex,
    input [2:0] ex_rindex,
    input [2:0] windex,
    input [1:0] datain,
	 
    output logic [1:0] if_dataout,
    output logic [1:0] ex_dataout
	 
);

logic [1:0] data [7:0] = '{default: 2'b10};
logic [1:0] _dataout;

assign if_dataout = data[if_rindex];
assign ex_dataout = data[ex_rindex];

always_ff @(posedge clk) begin

    if (load)
        data[windex] <= datain;
		  
end

endmodule : array2g