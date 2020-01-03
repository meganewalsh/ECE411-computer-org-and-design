import rv32i_types::*;

module random_tb(
    tb_itf.tb itf,
    tb_itf.mem mem_itf
);

//input clk,
//input pmem_resp,
//input [255:0] pmem_rdata,
//input logic [3:0] mem_byte_enable;
//input logic [31:0] mem_address;
//input logic [31:0] mem_wdata;
//input logic mem_read;
//input logic mem_write;

//output logic pmem_read,
//output logic pmem_write,
//output rv32i_word pmem_address,
//output [255:0] pmem_wdata
//output logic [31:0] mem_rdata;
//output logic mem_resp;

initial begin
    itf.mem_byte_enable = 4'b0011;
	 itf.mem_address = 32'hffffffff;
	 itf.mem_wdata = 32'haaaaaaaa;
	 itf.mem_read = 1;
	 @(posedge itf.clk);
	 itf.mem_read = 0;
	 itf.mem_write = 1;
	 @(posedge itf.clk);
	 itf.mem_write = 0;
end

endmodule : random_tb


