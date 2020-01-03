`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)
import rv32i_types::*;

module MEM(
    input clk,
    input rv32i_control_word ctrl_in,
    input logic [31:0] pc_in,
    input logic [31:0] ir_in,
    input logic [31:0] rs1_in,
    input logic [31:0] rs2_in,
    input logic [31:0] dcache_rdata,
    input logic dcache_resp,
	 input logic stall,

    output rv32i_control_word ctrl_out,
    output logic dcache_read,
    output logic dcache_write,
    output logic [3:0] dcache_wmask,
    output logic [31:0] dcache_addr,
    output logic [31:0] dcache_wdata,
    output logic [31:0] rs2_out,
    output logic [31:0] rs1_out,
    output logic [31:0] ir_out,
    output logic [31:0] pc_out
);

rv32i_opcode opcode;
load_funct3_t load_funct3;
logic internal_dcache_read, internal_dcache_write;

assign load_funct3 = load_funct3_t'(ir_in[14:12]);
assign opcode = rv32i_opcode'(ir_in[6:0]);
assign ctrl_out = ctrl_in;
assign rs2_out = rs2_in;
assign ir_out = ir_in;
assign pc_out = pc_in;

assign dcache_addr = (ctrl_in.mem.write) ? {rs1_in[31:2], 2'd0} : rs1_in;
assign dcache_write = internal_dcache_write;
assign dcache_read = internal_dcache_read;
assign dcache_wmask = ctrl_in.mem.wmask << rs1_in[1:0];
assign dcache_wdata = rs2_in << (8*rs1_in[1:0]);

/*
always_latch begin
	if (dcache_resp | ~stall) begin
		internal_dcache_read = (ctrl_in.mem.read & ~stall);
		internal_dcache_write = (ctrl_in.mem.write & ~stall);
	end
end
*/  //TODO
assign internal_dcache_read = ctrl_in.mem.read;
assign internal_dcache_write = ctrl_in.mem.write;

always_comb begin
    case (opcode)
        op_load:
        begin
            case (load_funct3)
                lb:
                    rs1_out = {{25{dcache_rdata[7]}}, dcache_rdata[6:0]};
                lh:
                    rs1_out = {{17{dcache_rdata[15]}}, dcache_rdata[14:0]};
                lw:
                    rs1_out = dcache_rdata;
                lbu:
                    rs1_out = {{24{1'b0}}, dcache_rdata[7:0]};
                lhu:
                    rs1_out = {{16{1'b0}}, dcache_rdata[15:0]};

            endcase // funct3

            rs1_out = dcache_rdata;
        end

        op_store:
        begin
            rs1_out = rs1_in;
        end

        default: 
        begin
            rs1_out = rs1_in;
        end
    endcase // opcode
end

endmodule : MEM
