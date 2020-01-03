module array2 (

    input clk,
    input load,
	 input new_entry,
    input [2:0] if_rindex,
    input [2:0] ex_rindex,
    input [2:0] windex,
    input [1:0] datain,
	 
    output logic [1:0] if_dataout,
    output logic [1:0] ex_dataout
	 
);

logic [1:0] data [7:0] = '{default: '0};
logic [1:0] _dataout;

assign if_dataout = (new_entry) ? 2'b10 : data[if_rindex];
assign ex_dataout = data[ex_rindex];

always_ff @(posedge clk)
begin

	 if (new_entry)
			data[if_rindex] <= 2'b10;

    if(load)
        data[windex] <= datain;
end

endmodule : array2