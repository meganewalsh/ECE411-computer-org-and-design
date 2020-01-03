import rv32i_types::*;
import rs1_types::*;
import rs2_types::*;

module riscy_stall_forward_block(
    input clk,
	input rv32i_word ir_IF_ID,
	input rv32i_word ir_ID_EX,
	input rv32i_word ir_EX_MEM,
	input rv32i_word ir_MEM_WB,
	input logic dcache_read,
	input logic icache_read,
	input logic dcache_write,
	input logic dcache_resp,
	input logic icache_resp,

	output logic load_IF_ID,
	output logic load_ID_EX,
	output logic load_EX_MEM,
	output logic load_MEM_WB,
	output logic stall_IF,
	output logic stall_ID,
	output logic stall_EX,
	output logic stall_MEM,
	output logic stall_WB,
	output fwd_rs1mux_sel_t forward_ID_rs1mux_sel,
	output fwd_rs2mux_sel_t forward_ID_rs2mux_sel,

    output logic forward_MEM_EX_1, //TODO
    output logic forward_MEM_EX_2,
    output logic flush_ex
);

/******* Counters *******/
int stalls_all = 0;
int stalls_IF_ID = 0;
int stalls_all_in, stalls_IF_ID_in;
/************************/

rv32i_reg if_id_rs1, if_id_rs2;
rv32i_reg id_ex_rd, ex_mem_rd, mem_wb_rd;
rv32i_reg id_ex_rs1, id_ex_rs2;
rv32i_opcode if_id_op, id_ex_op, ex_mem_op, mem_wb_op;

assign if_id_op = rv32i_opcode'(ir_IF_ID[6:0]);
assign id_ex_op = rv32i_opcode'(ir_ID_EX[6:0]);
assign ex_mem_op = rv32i_opcode'(ir_EX_MEM[6:0]);
assign mem_wb_op = rv32i_opcode'(ir_MEM_WB[6:0]);

assign if_id_rs1 = ir_IF_ID[19:15];
assign if_id_rs2 = ir_IF_ID[24:20];
assign id_ex_rs1 = ir_ID_EX[19:15];
assign id_ex_rs2 = ir_ID_EX[24:20];
assign id_ex_rd = ir_ID_EX[11:7];
assign ex_mem_rd = ir_EX_MEM[11:7];
assign mem_wb_rd = ir_MEM_WB[11:7];

logic load_IF_ID_in, load_ID_EX_in, load_EX_MEM_in, load_MEM_WB_in, stall_IF_in, stall_ID_in, stall_EX_in, stall_MEM_in, stall_WB_in; 
logic load_IF_ID_out, load_ID_EX_out, load_EX_MEM_out, load_MEM_WB_out, stall_IF_out, stall_ID_out, stall_EX_out, stall_MEM_out, stall_WB_out; 

assign load_IF_ID = load_IF_ID_out;
assign load_ID_EX = load_ID_EX_out;
assign load_EX_MEM = load_EX_MEM_out;
assign load_MEM_WB = load_MEM_WB_out;
assign stall_IF = stall_IF_out;
assign stall_ID = stall_ID_out;
assign stall_EX = stall_EX_out;
assign stall_MEM = stall_MEM_out;
assign stall_WB = stall_WB_out;

assign load_IF_ID_in =  ~stall_ID_in;
assign load_ID_EX_in =  ~stall_EX_in;
assign load_EX_MEM_in = ~stall_MEM_in;
assign load_MEM_WB_in = ~stall_WB_in;

function void set_defaults();
	stall_IF_in =  1'b0;
	stall_ID_in =  1'b0;
	stall_EX_in =  1'b0;
	stall_MEM_in = 1'b0;
	stall_WB_in =  1'b0;
   flush_ex = 1'b0;
    forward_MEM_EX_1 = '0;
    forward_MEM_EX_2 = '0;
endfunction

function void stall_all();
	stall_IF_in =  1'b1;
	stall_ID_in =  1'b1;
	stall_EX_in =  1'b1;
	stall_MEM_in = 1'b1;
	stall_WB_in =  1'b1;
endfunction

function void stall_id();
	stall_IF_in =  1'b1;
	stall_ID_in =  1'b1;
endfunction

function void counter_defaults();
	stalls_all_in = stalls_all;
	stalls_IF_ID_in = stalls_IF_ID;
endfunction

always_comb begin
	set_defaults();
	counter_defaults();

	if (ex_mem_op == op_load) begin
        forward_MEM_EX_1 = (id_ex_rs1 == ex_mem_rd);
        forward_MEM_EX_2 = (id_ex_rs2 == ex_mem_rd);
    end

	if ((icache_read & ~icache_resp) | (dcache_read & ~dcache_resp) | (dcache_write & ~dcache_resp)) begin
        flush_ex = 1'b0;    // Hold off on flushing EX until MEM is not stalling
		  stalls_all_in = stalls_all + 1;
		  stall_all();
	end
end

always_ff @(negedge clk)  begin
	load_IF_ID_out <=  load_IF_ID_in;
	load_ID_EX_out <=  load_ID_EX_in;
	load_EX_MEM_out <= load_EX_MEM_in;
	load_MEM_WB_out <= load_MEM_WB_in;
	stall_IF_out <=  stall_IF_in;
	stall_ID_out <=  stall_ID_in;
	stall_EX_out <=  stall_EX_in;
	stall_MEM_out <= stall_MEM_in;
	stall_WB_out <=  stall_WB_in;
end

always_comb begin : Forwarding
	forward_ID_rs1mux_sel = rs1_types::regfile_rs1_out;
	forward_ID_rs2mux_sel = rs2_types::regfile_rs2_out;

	if ((if_id_op == op_br) |
		 (if_id_op == op_reg) |
		 (if_id_op == op_imm) |
		 (if_id_op == op_store) |
		 (if_id_op == op_jal) |
		 (if_id_op == op_jalr) |
		 (if_id_op == op_load)) begin	/* Where source can be a reg */
		/* WB_DEC */
		if ((mem_wb_op == op_reg) |
		 	(mem_wb_op == op_imm) |
			(mem_wb_op == op_auipc) |
			(mem_wb_op == op_lui) |
		    (mem_wb_op == op_jal) |
		    (mem_wb_op == op_jalr) |
		 	(mem_wb_op == op_load)) begin
			if ((if_id_rs1 != 'd0) && (if_id_rs1 == mem_wb_rd)) begin forward_ID_rs1mux_sel = rs1_types::WB_rd_out; end
			if ((if_id_rs2 != 'd0) && (if_id_rs2 == mem_wb_rd)) begin forward_ID_rs2mux_sel = rs2_types::WB_rd_out; end
		end
		/* MEM-DEC */
		if ((ex_mem_op == op_reg) |
		 	(ex_mem_op == op_imm) |
			(ex_mem_op == op_auipc) |
			(ex_mem_op == op_lui) |
		    (ex_mem_op == op_jal) |
		    (ex_mem_op == op_jalr) |
		 	(ex_mem_op == op_load)) begin
			if ((if_id_rs1 != 'd0) && (if_id_rs1 == ex_mem_rd)) begin forward_ID_rs1mux_sel = MEM_rs1_out; end
			if ((if_id_rs2 != 'd0) && (if_id_rs2 == ex_mem_rd)) begin forward_ID_rs2mux_sel = MEM_rs2_out; end
		end
		/* EX-DEC */
		if ((id_ex_op == op_imm) |
			(id_ex_op == op_auipc) |
			(id_ex_op == op_lui) |
		    (id_ex_op == op_jal) |
		    (id_ex_op == op_jalr) |
			(id_ex_op == op_reg)) begin
			if ((if_id_rs1 != 'd0) && (if_id_rs1 == id_ex_rd)) begin forward_ID_rs1mux_sel = EX_rs1_out; end
			if ((if_id_rs2 != 'd0) && (if_id_rs2 == id_ex_rd)) begin forward_ID_rs2mux_sel = EX_rs2_out; end
		end
	end
end

always_ff @(posedge clk) begin
	stalls_all   <= stalls_all_in;
	stalls_IF_ID <= stalls_IF_ID_in;
end

endmodule : riscy_stall_forward_block
