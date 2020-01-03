import rv32i_types::*;

module WB(
    input rv32i_control_word ctrl_in,
    input rv32i_word pc_in,
    input rv32i_word ir_in,
    input rv32i_word rd_in,
	 input stall,

    output rv32i_control_word ctrl_out,
    output rv32i_word pc_out,
    output rv32i_reg rd,
    output rv32i_word rd_out
);

assign rd = ir_in[11:7];
assign rd_out = rd_in;
assign pc_out = pc_in;
assign ctrl_out = ctrl_in;

endmodule : WB
