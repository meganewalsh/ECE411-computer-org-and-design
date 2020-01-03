import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
	 /* Datapath to control */
    input clk,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
	 
	 /* Memory to control */
	 input logic mem_resp,
	 input rv32i_word mem_address,
	 
	 /* Control to memory */
	 output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,
	 
	 /* Control to datapath */
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
	 output branch_funct3_t cmpop
);

/****************** USED BY RVFIMON --- DO NOT MODIFY ************************/
logic trap;
logic[4:0] rs1_addr, rs2_addr;
logic[3:0] rmask, wmask;
logic[4:0]  rd;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check_do_not_modify
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011;
                lb, lbu: rmask = 4'b0001;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011;
                sb: wmask = 4'b0001;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
	 fetch1,
	 fetch2,
	 fetch3,
	 decode,
	 s_imm,
	 r_imm,
	 lui,
	 L_calc_addr,
	 S_calc_addr,
	 auipc,
	 temp,
	 br,
	 ld1,
	 st1,
	 ld2,
	 st2,
	 jal,
	 jalr
} state, next_states;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
	load_pc = 1'b0;
   load_ir = 1'b0;
   load_regfile = 1'b0;
   load_mar = 1'b0;
   load_mdr = 1'b0;
   load_data_out = 1'b0;
   pcmux_sel = pcmux::pc_plus4;
	cmpop = branch_funct3_t'(funct3);
   alumux1_sel = alumux::rs1_out;
   alumux2_sel = alumux::i_imm;
   regfilemux_sel = regfilemux::alu_out;
   marmux_sel = marmux::pc_out;
   cmpmux_sel = cmpmux::rs2_out;
   aluop = alu_ops'(funct3);
	mem_read = 1'b0;
   mem_write = 1'b0;
   mem_byte_enable = 4'b1111;
endfunction

/*****************************************************************************/
always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
	 
    /* Actions for each state */
	 unique case (state)
	 
		/* Fetch process */
	 	fetch1: begin
			load_mar = 1;
		end
		
		fetch2: begin
			load_mdr = 1;
			mem_read = 1;
		end
		
		fetch3: begin
			load_ir = 1;
		end
		
		/* Decode process */
		decode:;
		
		/* Register-immediate arithmetic operations */
		s_imm: begin
			load_regfile = 1;
			load_pc = 1;
			case (arith_funct3)
				add:		aluop = alu_add;
				sll:		aluop = alu_sll;
				slt: begin
					cmpop = blt;
					regfilemux_sel = regfilemux::br_en;
					cmpmux_sel = cmpmux::i_imm;
				end
				sltu: begin
					cmpop = bltu;
					regfilemux_sel = regfilemux::br_en;
					cmpmux_sel = cmpmux::i_imm;
				end
				sr:		aluop = (funct7[5] ? alu_sra : alu_srl);
				axor:		aluop = alu_xor;
				aor:		aluop = alu_or;
				aand:		aluop = alu_and;
				default:	;
			endcase
			
		end
		
		/* Register-register arithmetic operations */
		r_imm: begin
			load_regfile = 1;
			load_pc = 1;
			alumux2_sel = alumux::rs2_out;
			case (arith_funct3)
				add:		aluop = (funct7[5] ? alu_sub : alu_add);
				sll:		aluop = alu_sll;
				slt: begin
					cmpop = blt;
					regfilemux_sel = regfilemux::br_en;
					cmpmux_sel = cmpmux::i_imm;
				end
				sltu: begin
					cmpop = bltu;
					regfilemux_sel = regfilemux::br_en;
					cmpmux_sel = cmpmux::i_imm;
				end
				sr:		aluop = (funct7[5] ? alu_sra : alu_srl);
				axor:		aluop = alu_xor;
				aor:		aluop = alu_or;
				aand:		aluop = alu_and;
				default:	;
			endcase
			
		end
		
		/* U-type operations */
		lui: begin
			load_regfile = 1;
			load_pc = 1;
			regfilemux_sel = regfilemux::u_imm;
		end

		auipc: begin
			alumux1_sel = alumux::pc_out;
			alumux2_sel = alumux::u_imm;
			load_regfile = 1;
			load_pc = 1;
			aluop = alu_add;
		end
		
		/* Branch operations */
		br: begin
			if (br_en)
				pcmux_sel = pcmux::alu_out;
			else
				pcmux_sel = pcmux::pc_plus4;
			load_pc = 1;
			alumux1_sel = alumux::pc_out;
			alumux2_sel = alumux::b_imm;
			aluop = alu_add;
		end
		
		/* Load process */
		L_calc_addr: begin
			aluop = alu_add;
			load_mar = 1;
			marmux_sel = marmux::alu_out;
		end
		
		ld1: begin
			load_mdr = 1;
			mem_read = 1;
		end

		ld2: begin
			case (load_funct3)
				lb:	regfilemux_sel = regfilemux::lb;
				lh:	regfilemux_sel = regfilemux::lh;
				lw:	regfilemux_sel = regfilemux::lw;
				lbu:	regfilemux_sel = regfilemux::lbu;
				lhu:	regfilemux_sel = regfilemux::lhu;
			endcase
			load_regfile = 1;
			load_pc = 1;
		end

		/* Store process */		
		S_calc_addr: begin
			alumux2_sel = alumux::s_imm;
			aluop = alu_add;
			load_mar = 1;
			marmux_sel = marmux::alu_out;
		end
		
		temp: begin
			load_data_out = 1;
		end

		st1: begin
			mem_write = 1;
			case (store_funct3)
				sb: begin
					case (mem_address[1:0])
						2'b00: mem_byte_enable = 4'b0001;
						2'b01: mem_byte_enable = 4'b0010;
						2'b10: mem_byte_enable = 4'b0100;
						2'b11: mem_byte_enable = 4'b1000;
					endcase
				end
				sh: begin
					case(mem_address[1])
						1'b0:	mem_byte_enable = 4'b0011;
						1'b1: mem_byte_enable = 4'b1100;
					endcase
				end
				sw: mem_byte_enable = 4'b1111;
			endcase
		end	
			
		st2: begin
			load_pc = 1;
		end
		
		// JAL is J-type, JALR is I-type.
		/* Jump operations */
		jal: begin
		/* R[rd] = PC + 4; PC = PC + sext(j_imm) */
			alumux1_sel = alumux::pc_out;
			alumux2_sel = alumux::j_imm;
			pcmux_sel = pcmux::alu_out;
			regfilemux_sel = regfilemux::pc_plus4;
			load_regfile = 1;
			load_pc = 1;
		end
			
		jalr: begin
		/* R[rd] = PC + 4; PC = ( R[rs1] + sext(i_imm) ) & 0xfffffffe */
			pcmux_sel = pcmux::alu_mod2;
			regfilemux_sel = regfilemux::pc_plus4;
			load_regfile = 1;
			load_pc = 1;
		end
		
		default: ;
	 endcase
	 
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */

	 /* Default no change */ 
	 next_states = state;

	 unique case (state)
	 	  
	  	 fetch1:
			next_states = fetch2;
			
		 fetch2: begin
			if (mem_resp)
				next_states = fetch3;
		 end
		 
		 fetch3:
				next_states = decode;
				
		 decode: begin
			case (opcode)
				op_jal:
					next_states = jal;
				op_jalr:
					next_states = jalr;
				op_imm:
					next_states = s_imm;
				op_reg:
					next_states = r_imm;
				op_lui:
					next_states = lui;
				op_load: 
					next_states = L_calc_addr;
				op_store:
					next_states = S_calc_addr;
				op_auipc:
					next_states = auipc;
				op_br:
					next_states = br;
				default: ;
			endcase
		 end
		 
		 s_imm, r_imm, lui, auipc, br, jal, jalr:
			next_states = fetch1;
				
		 L_calc_addr:
			next_states = ld1;
		
		 S_calc_addr:
				next_states = temp;
		
		temp:
				next_states = st1;
		 
		 ld1: begin
			if (mem_resp)
				next_states = ld2;
		 end
		 
		 st1: begin
			if (mem_resp)
				next_states = st2;
		 end
		 
		 ld2, st2:
			next_states = fetch1;
			
		 default: ;
	endcase	
	
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_states;
end

endmodule : control
