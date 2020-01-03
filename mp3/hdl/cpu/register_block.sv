import rv32i_types::*;

module register_block
(
	input clk,
	input load,
	input reset,
	
	input rv32i_word pc_in,
	input rv32i_word ir_in,
   input rv32i_control_word ctrl_in,
	input rv32i_word rs1_in,
   input rv32i_word rs2_in,
   input logic branch_prediction_in,
	input logic was_local_in,
	input logic [2:0] shift_data_in,
	
	output logic [2:0] shift_data_out,	
	output logic was_local_out,
	output logic branch_prediction_out,
	output rv32i_word pc_out,
	output rv32i_word ir_out,
   output rv32i_control_word ctrl_out,
	output rv32i_word rs1_out,
	output rv32i_word rs2_out

);

logic [2:0] shift_data;
logic branch_prediction, was_local;
rv32i_word rs1, rs2, pc, ir;
rv32i_control_word control_word;

always_ff @(posedge clk) begin

	if (reset) begin
		pc = 0;
		ir = 0;
		rs1 = 0;
		rs2 = 0;
		control_word = 0;
		branch_prediction = 0;
		was_local = 0;
		shift_data = 3'b0;
	end else if (load) begin
		was_local = was_local_in;
		branch_prediction = branch_prediction_in;
		pc = pc_in;
		ir = ir_in;
		rs1 = rs1_in;
		rs2 = rs2_in;
		control_word = ctrl_in;
		shift_data = shift_data_in;
	end
	
end


always_comb begin
	pc_out = pc;
	ir_out = ir;
	rs1_out = rs1;
	rs2_out = rs2;
	ctrl_out = control_word;
	branch_prediction_out = branch_prediction;
	was_local_out = was_local;
	shift_data_out = shift_data;
end


endmodule : register_block
