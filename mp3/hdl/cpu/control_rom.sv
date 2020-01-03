import rv32i_types::*;

module control_rom(
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
	 input logic incorrect_prediction, cmp_out, branch_prediction,

    output rv32i_control_word ctrl
);

function void set_defaults();
    // Fetch Stage Signals
    // Nothing to Set
    ctrl.ifs.filler = 1'b0;

    // Decode Stage Signals
    // Nothing to Set
    ctrl.id.filler = 1'b0;

    // Execute Stage Signals
    ctrl.ex.pcmux_sel = pcmux::pc_plus4;
    ctrl.ex.alumux1_sel = alumux::rs1_out;
    ctrl.ex.alumux2_sel = alumux::rs2_out;
    ctrl.ex.cmpmux_sel = cmpmux::rs2_out;
    ctrl.ex.cmpop = beq;
    ctrl.ex.aluop = alu_add;
     ctrl.ex.regfilemux_sel = regfilemux::alu_out;

    // Mem Stage Signals
    ctrl.mem.write = 1'b0;
    ctrl.mem.read = 1'b0;
    ctrl.mem.wmask = 4'b1111;

    // Write Back Stage Signals
    ctrl.ex.load_pc = 1'd0;   // Default is to use IF_PC + 4
	 ctrl.wb.load_regfile = 1'd0;
endfunction

always_comb begin
    set_defaults();
    case(opcode)
    op_lui: begin
        // U-type
        ctrl.ex.regfilemux_sel = regfilemux::u_imm;
        ctrl.ex.load_pc = 1'd0;   // Load PC + 4
        ctrl.wb.load_regfile = 1'd1;
    end
    op_auipc: begin
        // U-type
        ctrl.ex.alumux1_sel = alumux::pc_out;
        ctrl.ex.alumux2_sel = alumux::u_imm;
        ctrl.ex.aluop = alu_add;
        ctrl.ex.regfilemux_sel = regfilemux::alu_out;
        ctrl.wb.load_regfile = 1'd1;
        ctrl.ex.load_pc = 1'd0;   // Load PC + 4
    end
    op_jal: begin
        // J type
        /*setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
        loadRegfile(regfilemux::pc_plus4);
        loadPC(pcmux::alu_out);*/
		  ctrl.ex.alumux1_sel = alumux::pc_out;
		  ctrl.ex.alumux2_sel = alumux::j_imm;
		  ctrl.ex.regfilemux_sel = regfilemux::pc_plus4;
		  ctrl.wb.load_regfile = 1'd1;
		  ctrl.ex.pcmux_sel = pcmux::alu_out;
		  ctrl.ex.load_pc = 1'd1;
	 end
    op_jalr: begin
        // I type
        /*setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
        loadRegfile(regfilemux::pc_plus4);
        loadPC(pcmux::alu_mod2);*/
		  ctrl.ex.alumux1_sel = alumux::rs1_out;
		  ctrl.ex.alumux2_sel = alumux::i_imm;
		  ctrl.ex.regfilemux_sel = regfilemux::pc_plus4;
		  ctrl.wb.load_regfile = 1'd1;
		  ctrl.ex.pcmux_sel = pcmux::alu_mod2;
		  ctrl.ex.load_pc = 1'd1;
    end
    op_br: begin
        // B-type
        ctrl.ex.alumux1_sel = alumux::pc_out;
        ctrl.ex.alumux2_sel = alumux::b_imm;
        ctrl.ex.aluop = alu_add;
		  ctrl.ex.pcmux_sel = pcmux::alu_out;
        ctrl.ex.cmpop = branch_funct3_t'(funct3);
    end
    op_load: begin
        ctrl.ex.alumux1_sel = alumux::rs1_out;
        ctrl.ex.alumux2_sel = alumux::i_imm;
        ctrl.ex.aluop = alu_add;

        ctrl.mem.write = 1'b0;
        ctrl.mem.read = 1'b1;

        ctrl.ex.load_pc = 1'b0;
        ctrl.wb.load_regfile = 1'd1;
    end
    
    op_store: begin
        ctrl.ex.alumux1_sel = alumux::rs1_out;
        ctrl.ex.alumux2_sel = alumux::s_imm;
        ctrl.ex.aluop = alu_add;

        ctrl.mem.write = 1'b1;
        ctrl.mem.read = 1'b0;
		case (store_funct3_t'(funct3))
            sb: ctrl.mem.wmask = 4'b0001;
            sh: ctrl.mem.wmask = 4'b0011;
            sw: ctrl.mem.wmask = 4'b1111;
            default: ctrl.mem.wmask = 4'b0;
        endcase
        ctrl.ex.load_pc = 1'b0;
    end
    op_imm: begin
        // I Type
        case(arith_funct3_t'(funct3))
            slt: begin
                ctrl.ex.regfilemux_sel = regfilemux::br_en;
                ctrl.ex.cmpop = blt;
                ctrl.ex.cmpmux_sel = cmpmux::i_imm;
            end
            sltu: begin
                ctrl.ex.regfilemux_sel = regfilemux::br_en;
                //setCMP()
                ctrl.ex.cmpop = bltu;
                ctrl.ex.cmpmux_sel = cmpmux::i_imm;
            end
            sr: begin
                case (funct7)
                    7'b0000000: begin
                        //setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
                        ctrl.ex.alumux1_sel = alumux::rs1_out;
                        ctrl.ex.alumux2_sel = alumux::i_imm;
                        ctrl.ex.aluop = alu_srl;
                    end
                    7'b0100000: begin
                        //setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
                        ctrl.ex.alumux1_sel = alumux::rs1_out;
                        ctrl.ex.alumux2_sel = alumux::i_imm;
                        ctrl.ex.aluop = alu_sra;
                    end
                endcase
                //loadRegfile(regfilemux::alu_out);
                ctrl.ex.regfilemux_sel = regfilemux::alu_out;
            end
            add, sll, axor, aor, aand: begin
                //loadRegfile(regfilemux::alu_out);
                ctrl.ex.regfilemux_sel = regfilemux::alu_out;
                //setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(arith_funct3));
                ctrl.ex.alumux1_sel = alumux::rs1_out;
                ctrl.ex.alumux2_sel = alumux::i_imm;
                ctrl.ex.aluop = alu_ops'(funct3);
            end
        endcase

        ctrl.wb.load_regfile = 1'd1;
        ctrl.ex.load_pc = 1'b0;
    end
    op_reg: begin
        // R-type
        case (funct7)
        7'b0000000: begin
            case (arith_funct3_t'(funct3))
                slt: begin
                    //loadRegfile(regfilemux::br_en);
                    ctrl.ex.regfilemux_sel = regfilemux::br_en;
                    //setCMP(cmpmux::rs2_out, blt);
                    ctrl.ex.cmpop = blt;
                    ctrl.ex.cmpmux_sel = cmpmux::rs2_out;
                end
                sltu: begin
                    //loadRegfile(regfilemux::br_en);
                    ctrl.ex.regfilemux_sel = regfilemux::br_en;
                    //setCMP(cmpmux::rs2_out, bltu);
                    ctrl.ex.cmpop = bltu;
                    ctrl.ex.cmpmux_sel = cmpmux::rs2_out;
                end
                sr: begin
                    //loadRegfile(regfilemux::alu_out);
                    ctrl.ex.regfilemux_sel = regfilemux::alu_out;
                    //setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
                    ctrl.ex.alumux1_sel = alumux::rs1_out;
                    ctrl.ex.alumux2_sel = alumux::rs2_out;
                    ctrl.ex.aluop = alu_srl;
                end
                add, sll, axor, aor, aand: begin
                    //loadRegfile(regfilemux::alu_out);
                    ctrl.ex.regfilemux_sel = regfilemux::alu_out;
                    //setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(arith_funct3));
                    ctrl.ex.alumux1_sel = alumux::rs1_out;
                    ctrl.ex.alumux2_sel = alumux::rs2_out;
                    ctrl.ex.aluop = alu_ops'(funct3);
                end
            endcase
        end
        7'b0100000: begin
            case (arith_funct3_t'(funct3))
                sr: begin
                    //loadRegfile(regfilemux::alu_out);
                    ctrl.ex.regfilemux_sel = regfilemux::alu_out;
                    //setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
                    ctrl.ex.alumux1_sel = alumux::rs1_out;
                    ctrl.ex.alumux2_sel = alumux::rs2_out;
                    ctrl.ex.aluop = alu_sra;
                end
                add: begin  // Register sub
                    //loadRegfile(regfilemux::alu_out);
                    ctrl.ex.regfilemux_sel = regfilemux::alu_out;
                    //setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
                    ctrl.ex.alumux1_sel = alumux::rs1_out;
                    ctrl.ex.alumux2_sel = alumux::rs2_out;
                    ctrl.ex.aluop = alu_sub;
                end
            endcase
        end
        endcase

        ctrl.wb.load_regfile = 1'd1;
        ctrl.ex.load_pc = 1'b0;
    end
    op_csr: begin /* Do Nothing, Unimplemented OP */ end
    default: ;
    endcase    
end

endmodule : control_rom
    
    
