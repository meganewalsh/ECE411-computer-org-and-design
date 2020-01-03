module riscy_prediction(

	input clk,
	
	input logic branch_taken,
	input logic update,
	input logic [1:0] current_prediction,
	
	output logic [1:0] new_prediction
);

/* Two-bit saturated counter */
logic [1:0] STRONG_NT, WEAK_NT, WEAK_T, STRONG_T;
assign STRONG_NT = 2'b00;
assign WEAK_NT   = 2'b01;
assign WEAK_T    = 2'b10;
assign STRONG_T  = 2'b11;

always_comb begin

	if          (current_prediction == STRONG_T & update & ~branch_taken)		new_prediction = WEAK_T;
	else if     (current_prediction == WEAK_T & update) begin
		if       (branch_taken)																	new_prediction = STRONG_T;
		else																							new_prediction = WEAK_NT;
	end else if (current_prediction == WEAK_NT & update) begin
		if       (branch_taken)																	new_prediction = WEAK_T;
		else 																							new_prediction = STRONG_NT;
	end else if (current_prediction == STRONG_NT & update & branch_taken)		new_prediction = WEAK_NT;
	else																								new_prediction = current_prediction;

end

endmodule : riscy_prediction
