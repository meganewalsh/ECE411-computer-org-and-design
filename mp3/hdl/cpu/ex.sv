import rv32i_types::*;

module EX(
    input clk,
	 input stall,

    input rv32i_control_word ctrl_in,
    input rv32i_word pc_in,
    input rv32i_word ir_in,
    input rv32i_word rs1_in,
    input rv32i_word rs2_in,
    input logic branch_prediction_in,

    input rv32i_word dcache_rdata, 
    input logic rs1_sel,    //Note 1 is use dcache, 0 is use reg
    input logic rs2_sel,    //Note 1 is use dcache, 0 is use reg

    output rv32i_control_word ctrl_out,
    output rv32i_word pc_out,
    output rv32i_word ir_out,
    output rv32i_word rs1_out,
    output rv32i_word rs2_out,
	 output logic reset_register_block,
	 output logic cmp_out,
	 output logic incorrect_prediction
);
rv32i_word alu_mux1_out, alu_mux2_out, alu_out;
rv32i_word cmpmux_out;
rv32i_word regfilemux_out;

rv32i_word internal_rs1_in;
rv32i_word internal_rs2_in;
assign internal_rs1_in = (rs1_sel) ? dcache_rdata : rs1_in;
assign internal_rs2_in = (rs2_sel) ? dcache_rdata : rs2_in;

logic [31:0] i_imm; logic [31:0] s_imm;
logic [31:0] b_imm; logic [31:0] u_imm;
logic [31:0] j_imm;
arith_funct3_t funct3;
rv32i_opcode opcode;
assign i_imm = {{21{ir_in[31]}}, ir_in[30:20]};
assign s_imm = {{21{ir_in[31]}}, ir_in[30:25], ir_in[11:7]};
assign b_imm = {{20{ir_in[31]}}, ir_in[7], ir_in[30:25], ir_in[11:8], 1'b0};
assign u_imm = {ir_in[31:12], 12'h000};
assign j_imm = {{12{ir_in[31]}}, ir_in[19:12], ir_in[20], ir_in[30:21], 1'b0};
assign funct3 = arith_funct3_t'(ir_in[14:12]);
assign opcode = rv32i_opcode'(ir_in[6:0]);

assign incorrect_prediction = (opcode == op_jalr || (opcode == op_br & cmp_out != branch_prediction_in));

assign reset_register_block = (~stall & incorrect_prediction);

cmp cmp(
    .cmpop(ctrl_in.ex.cmpop),
    .a(internal_rs1_in),
    .b(cmpmux_out),
    .f(cmp_out)
);

alu alu(
    .aluop(ctrl_in.ex.aluop),
    .a(alu_mux1_out),
    .b(alu_mux2_out),
    .f(alu_out)
);

assign ir_out = ir_in;
assign rs1_out = regfilemux_out;   // Addresses should be stored in RS1, TODO Note ALU_OUT Comes here
assign rs2_out = internal_rs2_in;

always_comb begin : Muxes
    // ALU MUX 1
    unique case (ctrl_in.ex.alumux1_sel)
        alumux::rs1_out: alu_mux1_out = internal_rs1_in;
        alumux::pc_out:  alu_mux1_out = pc_in;
        default: alu_mux1_out = internal_rs1_in;
    endcase

    // ALU MUX 2
    unique case (ctrl_in.ex.alumux2_sel)
        alumux::i_imm:   alu_mux2_out = i_imm;
        alumux::u_imm:   alu_mux2_out = u_imm;
        alumux::b_imm:   alu_mux2_out = b_imm;
        alumux::s_imm:   alu_mux2_out = s_imm;
        alumux::j_imm:   alu_mux2_out = j_imm;
        alumux::rs2_out: alu_mux2_out = internal_rs2_in;
        default: alu_mux2_out = internal_rs2_in;
    endcase

    // PC out MUX
    unique case (ctrl_out.ex.pcmux_sel)
        pcmux::alu_out:  pc_out = alu_out;
        pcmux::alu_mod2: pc_out = (alu_out & 32'hFFFFFFFE);
        default: pc_out = pc_in + 4;
    endcase

    // REGFILE MUX
    //TODO mux input ot rs1_out
    unique case (ctrl_in.ex.regfilemux_sel)
        regfilemux::alu_out:  regfilemux_out = alu_out;
        regfilemux::br_en:    regfilemux_out = {31'd0, cmp_out};
        regfilemux::u_imm:    regfilemux_out = u_imm;
        regfilemux::pc_plus4: regfilemux_out = pc_in + 4;
        default: regfilemux_out = alu_out;
    endcase

    // CMP MUX
    unique case (ctrl_in.ex.cmpmux_sel)
        cmpmux::rs2_out: cmpmux_out = internal_rs2_in;
        cmpmux::i_imm:   cmpmux_out = i_imm;
        default: cmpmux_out = internal_rs2_in;
    endcase
end : Muxes

always_comb begin : Control_Signal_Updates
    ctrl_out = ctrl_in;
	 if (incorrect_prediction) begin
		if (branch_prediction_in)			ctrl_out.ex.pcmux_sel = pcmux::pc_plus4;
		else 										ctrl_out.ex.pcmux_sel = pcmux::alu_out;
	end
end

/******* Counters *******/
int branches = 0;
int mispredictions = 0;
always_ff @ (posedge clk) begin
	if (opcode == op_br)				branches = branches + 1;	//includes first couple branches on halt loop..
	if (incorrect_prediction)		mispredictions = mispredictions + 1;
end
/************************/

endmodule : EX
