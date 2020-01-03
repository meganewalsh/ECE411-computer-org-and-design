`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)
import rv32i_types::*;

module ID(
	input clk,
	input logic branch_prediction_in,
	input logic ex_branch,
	input logic was_local_in,
	input rv32i_word ir_in,
	input rv32i_word pc_in,
	input rv32i_word regfile_in,
	input rv32i_reg regfile_rd,
   input logic load_regfile,
	input logic stall,
	input logic incorrect_prediction,
	input logic cmp_out,
	input logic [2:0] shift_data_in,
	
	/* Forwarding */
	input rs1_types::fwd_rs1mux_sel_t forward_ID_rs1mux_sel,
	input rs2_types::fwd_rs2mux_sel_t forward_ID_rs2mux_sel,
	input rv32i_word EX_rs1_out,
	input rv32i_word WB_rd_out,
	input rv32i_word MEM_rs1_out,
	input rv32i_word EX_rs2_out,
	input rv32i_word MEM_rs2_out,

	output logic [2:0] shift_data_out,
	output logic branch_prediction_out,
	output logic was_local_out,
	output rv32i_word ir_out,
   output rv32i_word pc_out,
   output rv32i_control_word ctrl_out,
	output rv32i_word rs1_out,	
	output rv32i_word rs2_out
);

logic [2:0] funct3;
logic [6:0] funct7;
logic [4:0] rs1, rs2, rd;
rv32i_opcode opcode;
rv32i_word regfile_rs1_out, regfile_rs2_out; 

assign funct3 = ir_in[14:12];
assign funct7 = ir_in[31:25];
assign opcode = rv32i_opcode'(ir_in[6:0]);
assign rs1 = ir_in[19:15];
assign rs2 = ir_in[24:20];

assign ir_out = ir_in;
assign pc_out = pc_in;
assign branch_prediction_out = branch_prediction_in;
assign was_local_out = was_local_in;
assign shift_data_out = shift_data_in;


control_rom control_rom(
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
	 .incorrect_prediction(incorrect_prediction),
	 .cmp_out(cmp_out),
	 .branch_prediction(ex_branch),

    .ctrl(ctrl_out)
);

regfile regfile(
    .clk(clk),
    .load(load_regfile),
    .in(regfile_in),
    .src_a(rs1),
	.src_b(rs2),
	.dest(regfile_rd),

    .reg_a(regfile_rs1_out),
	.reg_b(regfile_rs2_out)
);

always_comb begin : Forwarding

	unique case (forward_ID_rs1mux_sel)
		rs1_types::EX_rs1_out:			rs1_out = EX_rs1_out;
		rs1_types::MEM_rs1_out:			rs1_out = MEM_rs1_out;
		rs1_types::WB_rd_out:			rs1_out = WB_rd_out;
		rs1_types::regfile_rs1_out:	rs1_out = regfile_rs1_out;
		default:								rs1_out = regfile_rs1_out;
	endcase

	unique case (forward_ID_rs2mux_sel)
		rs2_types::EX_rs2_out:			rs2_out = EX_rs2_out;
		rs2_types::MEM_rs2_out:			rs2_out = MEM_rs2_out;
		rs2_types::WB_rd_out:			rs2_out = WB_rd_out;
		rs2_types::regfile_rs2_out:	rs2_out = regfile_rs2_out;
		default: 							rs2_out = regfile_rs2_out;
	endcase

end

endmodule : ID
