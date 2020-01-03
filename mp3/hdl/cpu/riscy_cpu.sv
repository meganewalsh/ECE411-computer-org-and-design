import rv32i_types::*;
import rs1_types::*;
import rs2_types::*;

module riscy_cpu(
	input clk,

   input icache_resp,	
   input [31:0] icache_rdata,	
   output icache_read,
   output [31:0] icache_addr,

   input logic dcache_resp,
   input logic [31:0] dcache_rdata,
   output dcache_read,
   output dcache_write,
   output [3:0] dcache_wmask,
   output [31:0] dcache_addr,
   output [31:0] dcache_wdata
);

logic reset_register_block;
logic flush_ex;
logic branch_prediction;
logic ex_cmp_out;
logic incorrect_prediction;
logic was_local, IF_ID_was_local_out, ID_was_local_out, ID_EX_was_local_out;
logic [2:0] shift_data, IF_shift_data_out, IF_ID_shift_data_out, ID_shift_data_out, ID_EX_shift_data_out;

logic load_IF_ID, load_ID_EX, load_EX_MEM, load_MEM_WB, IF_branch_prediction_out, IF_ID_branch_prediction_out, ID_branch_prediction_out, ID_EX_branch_prediction_out;
logic stall_IF, stall_ID, stall_EX, stall_MEM, stall_WB;

rv32i_word IF_pc_in, IF_pc_out;
rv32i_word IF_ID_pc_out, IF_ID_ir_out;
rv32i_word ID_ir_out, ID_pc_out, ID_rs1_out, ID_rs2_out;
rv32i_word ID_EX_pc_out, ID_EX_ir_out, ID_EX_rs1_out, ID_EX_rs2_out;
rv32i_word EX_pc_out, EX_ir_out, EX_rs1_out, EX_rs2_out;
rv32i_word EX_MEM_pc_out, EX_MEM_ir_out, EX_MEM_rs1_out, EX_MEM_rs2_out;
rv32i_word MEM_rs2_out, MEM_rs1_out, MEM_ir_out, MEM_pc_out;
rv32i_word MEM_WB_pc_out, MEM_WB_ir_out, MEM_WB_rs1_out, MEM_WB_rs2_out;
rv32i_word WB_pc_out, WB_rd_out;
rv32i_reg WB_rd;

logic ex_rs1_sel, ex_rs2_sel;

rv32i_control_word ID_ctrl_out, ID_EX_ctrl_out, EX_ctrl_out, EX_MEM_ctrl_out, MEM_ctrl_out, MEM_WB_ctrl_out, WB_ctrl_out;

logic [31:0] internal_icache_rdata, internal_dcache_rdata;

fwd_rs1mux_sel_t forward_ID_rs1mux_sel;
fwd_rs2mux_sel_t forward_ID_rs2mux_sel;

always_latch begin
	if (icache_resp)
		internal_icache_rdata = icache_rdata;
	if (dcache_resp)
		internal_dcache_rdata = dcache_rdata;
end

riscy_branch_predictor rbp(
	.clk(clk),
	.if_PC(IF_pc_out),
	.ex_PC(ID_EX_pc_out),
	.if_IR(internal_icache_rdata),
	.ex_IR(ID_EX_ir_out),
	.cmp_out(ex_cmp_out),
	
	.ex_incorrect_prediction(incorrect_prediction),
	.ex_was_local(ID_EX_was_local_out),
	.ex_shift_data(ID_EX_shift_data_out),
	
	.final_prediction(branch_prediction),
	.was_local(was_local),
	.if_shift_data(shift_data)
);

riscy_stall_forward_block s_fwd_block(
    .clk(clk),
	.ir_IF_ID(IF_ID_ir_out),
	.ir_ID_EX(ID_EX_ir_out),
	.ir_EX_MEM(EX_MEM_ir_out),
	.ir_MEM_WB(MEM_WB_ir_out),
	.dcache_resp(dcache_resp),
	.icache_resp(icache_resp),
	.dcache_read(dcache_read),
	.icache_read(icache_read),
	.dcache_write(dcache_write),

	.load_IF_ID(load_IF_ID),
	.load_ID_EX(load_ID_EX),
	.load_EX_MEM(load_EX_MEM),
	.load_MEM_WB(load_MEM_WB),
	.stall_IF(stall_IF),
	.stall_ID(stall_ID),
	.stall_EX(stall_EX),
	.stall_MEM(stall_MEM),
	.stall_WB(stall_WB),
	.forward_ID_rs1mux_sel(forward_ID_rs1mux_sel),
	.forward_ID_rs2mux_sel(forward_ID_rs2mux_sel),
    .forward_MEM_EX_1(ex_rs1_sel),
    .forward_MEM_EX_2(ex_rs2_sel),
   .flush_ex(flush_ex)
);


IF IF(
	.clk(clk),
	.pc_in(IF_pc_out),
   .EX_ctrl_out(EX_ctrl_out),
	.stall(stall_IF),
	.EX_pc_out(EX_pc_out),
	
	.if_ir(internal_icache_rdata),
	.branch_prediction(branch_prediction),
	.incorrect_prediction(incorrect_prediction),
	
	.pc_out(IF_pc_out),
	.icache_read(icache_read),
	.icache_addr(icache_addr),
   .icache_resp(icache_resp)
);


register_block IF_ID(
	.clk(clk),
	.load(load_IF_ID),
	.reset(reset_register_block),
	.pc_in(IF_pc_out),
	.ir_in(internal_icache_rdata),
	.branch_prediction_in(branch_prediction),
	.was_local_in(was_local),
	.shift_data_in(shift_data),
	
	.shift_data_out(IF_ID_shift_data_out),
	.was_local_out(IF_ID_was_local_out),
	.branch_prediction_out(IF_ID_branch_prediction_out),
	.pc_out(IF_ID_pc_out),
	.ir_out(IF_ID_ir_out),
	
	// Unused
	.ctrl_in(),
	.rs1_in(),
	.rs2_in(),
	.ctrl_out(),
	.rs1_out(),
	.rs2_out()
);


ID ID(
	.clk(clk),
	.branch_prediction_in(IF_ID_branch_prediction_out),
	.ex_branch(ID_EX_branch_prediction_out),
	.was_local_in(IF_ID_was_local_out),
	.shift_data_in(IF_ID_shift_data_out),
	.ir_in(IF_ID_ir_out),
	.pc_in(IF_ID_pc_out),
   .load_regfile(WB_ctrl_out.wb.load_regfile),
	.regfile_in(WB_rd_out),
	.regfile_rd(WB_rd),
	.stall(stall_ID),
	.forward_ID_rs1mux_sel(forward_ID_rs1mux_sel),
	.forward_ID_rs2mux_sel(forward_ID_rs2mux_sel),
	.EX_rs1_out(EX_rs1_out),
	.WB_rd_out(WB_rd_out),
	.MEM_rs1_out(MEM_rs1_out),
	.EX_rs2_out(EX_rs1_out),		// Take from RD (which is stored into RS1 of Mem)
	.MEM_rs2_out(MEM_rs1_out), 	// Take from RD (which is stored into RS1 of WB)
	
	.incorrect_prediction(incorrect_prediction),
	.cmp_out(ex_cmp_out),

	.branch_prediction_out(ID_branch_prediction_out),
	.was_local_out(ID_was_local_out),
	.shift_data_out(ID_shift_data_out),
	.ir_out(ID_ir_out),
	.pc_out(ID_pc_out),
   .ctrl_out(ID_ctrl_out),
	.rs1_out(ID_rs1_out),	
	.rs2_out(ID_rs2_out)
);


register_block ID_EX(
	.clk(clk),
	.load(load_ID_EX),
	.reset(reset_register_block | flush_ex),
	.pc_in(ID_pc_out),
	.ir_in(ID_ir_out),
	.ctrl_in(ID_ctrl_out),
	.rs1_in(ID_rs1_out),
	.rs2_in(ID_rs2_out),
	.branch_prediction_in(ID_branch_prediction_out),
	.was_local_in(ID_was_local_out),
	.shift_data_in(ID_shift_data_out),
	
	.shift_data_out(ID_EX_shift_data_out),
	.was_local_out(ID_EX_was_local_out),
	.branch_prediction_out(ID_EX_branch_prediction_out),
	.pc_out(ID_EX_pc_out),
	.ir_out(ID_EX_ir_out),
	.ctrl_out(ID_EX_ctrl_out),
	.rs1_out(ID_EX_rs1_out),
	.rs2_out(ID_EX_rs2_out)
);


EX EX(
	.clk(clk),
	.ctrl_in(ID_EX_ctrl_out),
   .pc_in(ID_EX_pc_out),
	.ir_in(ID_EX_ir_out),
	.rs1_in(ID_EX_rs1_out),
	.rs2_in(ID_EX_rs2_out),
	.stall(stall_EX),
	.branch_prediction_in (ID_EX_branch_prediction_out),
	.incorrect_prediction(incorrect_prediction),

    .dcache_rdata(internal_dcache_rdata),   //TODO add forward sel for RS1/RS2, Remove from existing
    .rs1_sel(ex_rs1_sel),
    .rs2_sel(ex_rs2_sel),

	.ctrl_out(EX_ctrl_out),
	.pc_out(EX_pc_out),
	.ir_out(EX_ir_out),
	.rs1_out(EX_rs1_out),
	.rs2_out(EX_rs2_out),
	.reset_register_block(reset_register_block),
	.cmp_out(ex_cmp_out)
);


register_block EX_MEM(
	.clk(clk),
	.load(load_EX_MEM),
	.reset(),
	.pc_in(EX_pc_out),
	.ir_in(EX_ir_out),
	.ctrl_in(EX_ctrl_out),
	.rs1_in(EX_rs1_out),
	.rs2_in(EX_rs2_out),
	
	.pc_out(EX_MEM_pc_out),
	.ir_out(EX_MEM_ir_out),
	.ctrl_out(EX_MEM_ctrl_out),
	.rs1_out(EX_MEM_rs1_out),
	.rs2_out(EX_MEM_rs2_out),

	// Unused
	.branch_prediction_in(),
	.branch_prediction_out(),
	.was_local_in(),
	.was_local_out(),
	.shift_data_in(),
	.shift_data_out()
);

MEM MEM(
	.clk(clk),
	.ctrl_in(EX_MEM_ctrl_out),
	.pc_in(EX_MEM_pc_out),
	.ir_in(EX_MEM_ir_out),
	.rs1_in(EX_MEM_rs1_out),
	.rs2_in(EX_MEM_rs2_out),
	.dcache_rdata(internal_dcache_rdata),
	.dcache_resp(dcache_resp),
	.stall(stall_MEM),

	.rs2_out(MEM_rs2_out),
	.rs1_out(MEM_rs1_out),
	.ir_out(MEM_ir_out),
	.pc_out(MEM_pc_out),
	.ctrl_out(MEM_ctrl_out),
	.dcache_addr(dcache_addr),
	.dcache_wdata(dcache_wdata),
	.dcache_read(dcache_read),
	.dcache_write(dcache_write),
	.dcache_wmask(dcache_wmask)
);


register_block MEM_WB(
	.clk(clk),
	.load(load_MEM_WB),
	.reset(),
	.pc_in(MEM_pc_out),
	.ir_in(MEM_ir_out),
	.ctrl_in(MEM_ctrl_out),
	.rs1_in(MEM_rs1_out),
	.rs2_in(MEM_rs2_out),
	
	.pc_out(MEM_WB_pc_out),
	.ir_out(MEM_WB_ir_out),
	.ctrl_out(MEM_WB_ctrl_out),
	.rs1_out(MEM_WB_rs1_out),
	.rs2_out(MEM_WB_rs2_out),

	// Unused
	.branch_prediction_in(),
	.branch_prediction_out(),
	.was_local_in(),
	.was_local_out(),
	.shift_data_in(),
	.shift_data_out()
);


WB WB(
    .ctrl_in(MEM_WB_ctrl_out),
    .pc_in(MEM_WB_pc_out),
    .ir_in(MEM_WB_ir_out),
    .rd_in(MEM_WB_rs1_out),
	 .stall(stall_WB),

    .ctrl_out(WB_ctrl_out),
    .pc_out(WB_pc_out),
    .rd(WB_rd),			//addr
    .rd_out(WB_rd_out)	//val
);

endmodule : riscy_cpu
