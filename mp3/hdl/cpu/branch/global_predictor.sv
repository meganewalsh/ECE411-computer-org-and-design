import rv32i_types::*;
// gshare tagless

module riscy_global_predictor(

	input clk,
	
	input logic [31:0] if_PC, // for reading
	input logic [31:0] ex_PC, // for updating
	input [31:0] if_IR,
	input [31:0] ex_IR,
	input logic cmp_out,
	input logic [2:0] ex_shift_data,
	
	output logic [1:0] final_prediction,
	output logic [2:0] if_shift_data
);

rv32i_opcode if_opcode, ex_opcode;
assign if_opcode = rv32i_opcode'(if_IR[6:0]);
assign ex_opcode = rv32i_opcode'(ex_IR[6:0]);

logic [1:0] new_prediction, ex_prediction;

// For debugging
logic if_branch; assign if_branch = (if_opcode == op_br);
logic ex_branch; assign ex_branch = (ex_opcode == op_br);

logic [2:0] if_index, ex_index;
assign if_index = (if_PC[2:0] ^ if_shift_data);
assign ex_index = (ex_PC[2:0] ^ ex_shift_data);

shift_reg history(
	.clk(clk),
	.data_in(cmp_out),
	.en(ex_opcode == op_br),

	.data_out(if_shift_data)
);

array2g predictions_arr(
    .clk(clk),
	 
    .if_rindex(if_index),
    .if_dataout(final_prediction),
	 
	 .ex_rindex(ex_index),
	 .ex_dataout(ex_prediction),
	 
    .load(ex_opcode == op_br),
    .windex(ex_index),
    .datain(new_prediction)
);

riscy_prediction pred(
	.clk(clk),
	.branch_taken(cmp_out & (ex_opcode == op_br)),
	.current_prediction(ex_prediction),
	.update(ex_opcode == op_br),
	
	.new_prediction(new_prediction)
);


endmodule : riscy_global_predictor