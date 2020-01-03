import rv32i_types::*;

module riscy_choose_predictor(
	input clk,
	input rv32i_opcode opcode,
	
	input logic local_prediction,
	input logic local_correct,
	
	input logic global_prediction,
	input logic global_correct,
	
	output logic final_pred,
	output logic was_local
);

logic selected_prediction;

/* Two-bit saturated counter */
enum int unsigned {
	weak_local,
	strong_local,
	weak_global,
	strong_global
} state, next_states;

always_comb begin
	if (opcode == op_jal)
		final_pred = 1'b1;
	else if (opcode == op_jalr)
		final_pred = 1'b0;		// avoid btb, force misprediction
	else
		final_pred = selected_prediction;
end

always_comb begin : next_state_logic

	 next_states = state;

	 unique case (state)
		strong_local: begin
			selected_prediction = local_prediction;
			was_local = 1'b1;
			if (~local_correct & global_correct)
				next_states = weak_local;
		end
		weak_local: begin
			was_local = 1'b1;
			selected_prediction = local_prediction;
			if (local_correct & ~global_correct)
				next_states = strong_local;
			else if (~local_correct & global_correct)
				next_states = weak_global;
		end
		weak_global: begin
			was_local = 1'b0;
			selected_prediction = global_prediction;
			if (local_correct & ~global_correct)
				next_states = weak_local;
			else if (~local_correct & global_correct)
				next_states = strong_global;
		end
		strong_global: begin
			was_local = 1'b0;
			selected_prediction = global_prediction;
			if (local_correct & ~global_correct)
				next_states = weak_global;
		end
	 endcase
	
end


always_ff @(posedge clk)
begin: next_state_assignment
	 state <= next_states;
end

endmodule : riscy_choose_predictor