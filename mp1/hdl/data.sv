import rv32i_types::*;

module data #(parameter width = 32)
(
    input clk,
    input load,
    input [width-1:0] in,
	 input rv32i_word addr,
	 input logic[2:0] funct3,
    output logic [width-1:0] out
);

logic [width-1:0] data = 1'b0;
store_funct3_t store_funct3;

always_ff @(posedge clk)
begin
    if (load)
    begin
		case (store_funct3)
			sw:	data = in;
			sb: begin
				case (addr[1:0])
					2'b00:	data = {24'b0, in[7:0]};
					2'b01:	data = {16'b0, in[7:0], 8'b0};
					2'b10:	data = {8'b0, in[7:0], 16'b0};
					2'b11:	data = {in[7:0], 24'b0};
				endcase
			end
			sh: begin
				case (addr[1])
					1'b0:	data = {16'b0, in[15:0]};
					1'b1:	data = {in[15:0], 16'b0};
				endcase
			end
		endcase
    end
end

always_comb
begin
    out = data;
	 store_funct3 = store_funct3_t'(funct3);
end

endmodule : data
