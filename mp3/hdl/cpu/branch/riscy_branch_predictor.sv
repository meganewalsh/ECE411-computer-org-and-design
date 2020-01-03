import rv32i_types::*;

module riscy_branch_predictor(

	input clk,
	
	input logic [31:0] if_PC,
	input logic [31:0] ex_PC,
	input [31:0] if_IR,
	input [31:0] ex_IR,
	input logic cmp_out,
	
	input logic ex_incorrect_prediction,
	input logic ex_was_local,
	input logic [2:0] ex_shift_data,
	
	output logic final_prediction,
	output logic was_local,
	output logic [2:0] if_shift_data
	
);

rv32i_opcode if_opcode, ex_opcode;
assign if_opcode = rv32i_opcode'(if_IR[6:0]);
assign ex_opcode = rv32i_opcode'(ex_IR[6:0]);

logic [1:0] local_prediction;
logic [1:0] global_prediction;
logic selected_prediction;
logic local_correct;
logic global_correct;

assign local_correct =  (ex_opcode == op_br) &  ex_was_local & ~ex_incorrect_prediction;
assign global_correct = (ex_opcode == op_br) & ~ex_was_local & ~ex_incorrect_prediction;

//For debugging, also outdated now
//assign final_prediction = (if_opcode == op_br) ? local_prediction[1]  : 1'b0;
//assign final_prediction = (if_opcode == op_br) ? global_prediction[1] : 1'b0;

assign final_prediction = selected_prediction;

riscy_local_predictor lp(
	.clk(clk),
	.if_PC(if_PC),
	.ex_PC(ex_PC),
	.if_IR(if_IR),
	.ex_IR(ex_IR),
	.cmp_out(cmp_out),
	
	.final_prediction(local_prediction)
);

riscy_global_predictor gp(
	.clk(clk),
	.if_PC(if_PC),
	.ex_PC(ex_PC),
	.if_IR(if_IR),
	.ex_IR(ex_IR),
	.cmp_out(cmp_out),
	.ex_shift_data(ex_shift_data),
	
	.final_prediction(global_prediction),
	.if_shift_data(if_shift_data)
);

riscy_choose_predictor cp(
	.clk(clk),
	.opcode(if_opcode),
	
	.local_prediction(local_prediction[1]),
	.local_correct(local_correct),
	.global_prediction(global_prediction[1]),
	.global_correct(global_correct),
	
	.final_pred(selected_prediction),
	.was_local(was_local)
);

endmodule : riscy_branch_predictor