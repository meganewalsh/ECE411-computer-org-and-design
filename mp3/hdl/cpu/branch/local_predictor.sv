import rv32i_types::*;

module riscy_local_predictor(

	input clk,
	
	input logic [31:0] if_PC, // for reading
	input logic [31:0] ex_PC, // for updating
	input [31:0] if_IR,
	input [31:0] ex_IR,
	input logic cmp_out,
	
	output logic [1:0] final_prediction
);

rv32i_opcode if_opcode, ex_opcode;
assign if_opcode = rv32i_opcode'(if_IR[6:0]);
assign ex_opcode = rv32i_opcode'(ex_IR[6:0]);

logic [2:0] if_index, ex_index;		// TODO for CP5: decide optimal size using performance counters after running some bigger code
assign if_index = if_PC[4:2];			// consider better replacement but eh this is ok
assign ex_index = ex_PC[4:2];

logic [31:0] current_address;
logic [1:0] new_prediction, ex_prediction;

// For debugging
logic if_branch; assign if_branch = (if_opcode == op_br);
logic ex_branch; assign ex_branch = (ex_opcode == op_br);

logic new_entry;
assign new_entry = (current_address != if_PC & if_opcode == op_br);

array32 addresses_arr(
    .clk(clk),
    .index(if_index),
    .dataout(current_address),

    .load(new_entry),
    .datain(if_PC)
);

array2 predictions_arr(
    .clk(clk),
	 .new_entry(new_entry),
	 
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


endmodule : riscy_local_predictor
