`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module datapath
(
    input clk,
	 
	 /* Memory to datapath */
    input rv32i_word mem_rdata,

	 /* Control to datapath */
	 input logic load_pc,
	 input logic load_ir,
	 input logic load_regfile,
	 input logic load_mar,
	 input logic load_mdr,
	 input logic load_data_out,
	 input pcmux::pcmux_sel_t pcmux_sel,
	 input branch_funct3_t cmpop,
	 input alumux::alumux1_sel_t alumux1_sel,
	 input alumux::alumux2_sel_t alumux2_sel,	 
	 input regfilemux::regfilemux_sel_t regfilemux_sel,
	 input marmux::marmux_sel_t marmux_sel,
	 input cmpmux::cmpmux_sel_t cmpmux_sel,	 
	 input alu_ops aluop,
	 
	 /* Datapath to control */
	 output rv32i_opcode opcode,
	 output logic[2:0] funct3,
	 output logic[6:0] funct7,
	 output logic br_en,
	 output rv32i_reg rs1,
	 output rv32i_reg rs2,
	 
	 /* Datapath to memory (ports) */
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
	 output rv32i_word mem_address

);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word mdrreg_out;

/*****************************************************************************/
rv32i_word i_imm, u_imm, b_imm, s_imm, j_imm;
logic[4:0]  rd;
rv32i_word pc_out, alu_out, alumux1_out, alumux2_out, marmux_out, cmpmux_out, regfilemux_out;
rv32i_word rs1_out, rs2_out;

/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
	 /* Inputs */
    .clk(clk),
    .load(load_ir),
    .in(mdrreg_out),
	 /* Outputs */
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)
);

register MDR(
	 /* Inputs */
    .clk(clk),
    .load(load_mdr),
    .in(mem_rdata),
	 /* Outputs */
    .out(mdrreg_out)
);

register MAR(
	 /* Inputs */
    .clk(clk),
    .load(load_mar),
    .in(marmux_out),
	 /* Outputs */
    .out(mem_address)
);

data MEM_DATA_OUT(
	 /* Inputs */
    .clk(clk),
    .load(load_data_out),
	 .addr(mem_address),
	 .funct3(funct3),
    .in(rs2_out),
	 /* Outputs */
    .out(mem_wdata)
);

regfile regfile(
	 /* Inputs */
    .clk(clk),
    .load(load_regfile),
    .in(regfilemux_out),
    .src_a(rs1),
	 .src_b(rs2),
	 .dest(rd),
	 /* Outputs */
    .reg_a(rs1_out),
	 .reg_b(rs2_out)
);

pc_register PC(
	 /* Inputs */
    .clk(clk),
    .load(load_pc),
    .in(pcmux_out),
	 /* Outputs */
    .out(pc_out)
);


/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu ALU(
	 /* Inputs */
    .aluop(aluop),
    .a(alumux1_out),
	 .b(alumux2_out),
	 /* Outputs */
    .f(alu_out)
);

cmp CMP(
	 /* Inputs */
	 .a(rs1_out),
	 .b(cmpmux_out),
	 .cmpop(cmpop),
	 /* Outputs */
	 .out(br_en)
);

/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog.  In this case, we actually use 
    // Offensive programming --- making simulation halt with a fatal message
    // warning when an unexpected mux select value occurs
	 
	 /* PC mux */
    unique case (pcmux_sel)
        pcmux::pc_plus4: 				pcmux_out = pc_out + 4;
		  pcmux::alu_out:					pcmux_out = alu_out;
		  /* Setting LSB to 0 for JALR */
		  pcmux::alu_mod2:				pcmux_out = alu_out & 32'hFFFFFFFE;				// cp2
        default: `BAD_MUX_SEL;
    endcase
	 
	 /* ALU mux 1 */
	 unique case (alumux1_sel)
        alumux::rs1_out: 				alumux1_out = rs1_out;
		  alumux::pc_out:					alumux1_out = pc_out;
        default: `BAD_MUX_SEL;
    endcase
	 
	 /* ALU mux 2 */
	 unique case (alumux2_sel)
        alumux::i_imm: 					alumux2_out = $signed(i_imm);
		  alumux::u_imm:					alumux2_out = u_imm;
		  alumux::b_imm:					alumux2_out = b_imm;
		  alumux::s_imm:					alumux2_out = s_imm;
		  alumux::j_imm:					alumux2_out = $signed(j_imm);
		  alumux::rs2_out:				alumux2_out = rs2_out;
        default: `BAD_MUX_SEL;
    endcase
	 
	 /* REGFILE mux */
	 unique case (regfilemux_sel)
        regfilemux::alu_out: 			regfilemux_out = alu_out;
		  regfilemux::br_en:				regfilemux_out = br_en;
        regfilemux::u_imm: 			regfilemux_out = u_imm;		  
		  regfilemux::pc_plus4: 		regfilemux_out = pc_out + 4;						// cp2
		  
		  regfilemux::lb: begin																		// cp2 - 8-bit sign extended
				case (mem_address[1:0])
					2'b00:	regfilemux_out = $signed(mdrreg_out[7:0]);
					2'b01:	regfilemux_out = $signed(mdrreg_out[15:8]);
					2'b10:	regfilemux_out = $signed(mdrreg_out[23:16]);
					2'b11:	regfilemux_out = $signed(mdrreg_out[31:24]);
				endcase
			end
			
			regfilemux::lbu: begin																	// cp2 - 8-bit zero extended
				case (mem_address[1:0])
					2'b00:	regfilemux_out = {24'b0, mdrreg_out[7:0]};
					2'b01:	regfilemux_out = {24'b0, mdrreg_out[15:8]};
					2'b10:	regfilemux_out = {24'b0, mdrreg_out[23:16]};
					2'b11:	regfilemux_out = {24'b0, mdrreg_out[31:24]};
				endcase
			end
		  regfilemux::lh: begin																		// cp2 - 16-bit sign extended
				case (mem_address[1])
					1'b0:		regfilemux_out = $signed(mdrreg_out[15:0]);
					1'b1:		regfilemux_out = $signed(mdrreg_out[31:16]);
				endcase
			end
		  regfilemux::lhu: begin																	// cp2 - 16-bit zero extended
				case(mem_address[1])
					1'b0:		regfilemux_out = {16'b0, mdrreg_out[15:0]};
					1'b1:		regfilemux_out = {16'b0, mdrreg_out[31:16]};
				endcase
			end
		  regfilemux::lw:					regfilemux_out = mdrreg_out;						// 32-bit value
        default: `BAD_MUX_SEL;
    endcase
	 
	 /* MAR mux */
	 unique case (marmux_sel)
        marmux::pc_out: 				marmux_out = pc_out;
		  marmux::alu_out:				marmux_out = alu_out;
        default: `BAD_MUX_SEL;
    endcase
	 
	 /* CMP mux */
	 unique case (cmpmux_sel)
        cmpmux::rs2_out: 				cmpmux_out = rs2_out;
		  cmpmux::i_imm:					cmpmux_out = i_imm;
        default: `BAD_MUX_SEL;
    endcase

end
/*****************************************************************************/
endmodule : datapath
