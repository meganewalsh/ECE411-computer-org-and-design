import rv32i_types::*;

module IF(
	
	input clk,
	input rv32i_word pc_in,
   input rv32i_control_word EX_ctrl_out,
   input rv32i_word if_ir,
	input icache_resp, 
	input stall,
	input branch_prediction,
	input incorrect_prediction,
	input [31:0] EX_pc_out,

	output rv32i_word pc_out,
	output icache_read,
	output [31:0] icache_addr
		 
);

logic [4:0] rs1, rs2, rd;
assign rs1 = if_ir[19:15];
assign rs2 = if_ir[24:20];
assign rd = if_ir[11:7];

rv32i_word pcmux_out;
logic internal_icache_read;
rv32i_opcode if_opcode;

assign icache_read = internal_icache_read;
assign icache_addr = pc_out;

/*
always_latch begin
	if (icache_resp | ~stall)
		internal_icache_read = ~stall;
end
*/
assign internal_icache_read = 1'd1;

pc_register PC(
    .clk(clk),
    .load(icache_resp & ~stall),
    .in(pcmux_out),
    .out(pc_out)
);

logic [31:0] b_imm, i_imm, j_imm;
assign b_imm = {{20{if_ir[31]}}, if_ir[7], if_ir[30:25], if_ir[11:8], 1'b0};
assign i_imm = {{21{if_ir[31]}}, if_ir[30:20]};
assign j_imm = {{12{if_ir[31]}}, if_ir[19:12], if_ir[20], if_ir[30:21], 1'b0};
assign if_opcode = rv32i_opcode'(if_ir[6:0]);

// PC MUX
always_comb begin : Mux
		if (incorrect_prediction) 				pcmux_out = EX_pc_out;
		else if (branch_prediction) begin
			if (if_opcode == op_br)				pcmux_out = pc_in + b_imm;
			else if (if_opcode == op_jal)		pcmux_out = pc_in + j_imm;
			else										pcmux_out = pc_in + 4;
		end else  									pcmux_out = pc_in + 4;
end : Mux

endmodule : IF
