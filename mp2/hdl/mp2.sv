import rv32i_types::*;

module mp2
(
    input clk,
    input pmem_resp,
    input [255:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [255:0] pmem_wdata
);

/* Signals between cache and CPU */
logic [3:0] mem_byte_enable;
logic [31:0] mem_address;
logic [31:0] mem_wdata;
logic mem_read;
logic mem_write;
logic [31:0] mem_rdata;
logic mem_resp;

// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp2 module to `cpu`
cpu cpu(.*);

// Keep cache named `cache` for RVFI Monitor
riscy_dcache dcache(
	.clk(clk),
	.l_read(mem_read),
	.l_write(mem_write),
	.l_wmask(mem_byte_enable),
	.l_addr(mem_address),
	.l_wdata(mem_wdata),
	.u_resp(pmem_resp),
	.u_rdata256(pmem_rdata),

	.dcache_resp(mem_resp),
	.dcache_rdata(mem_rdata),
	.u_addr(pmem_address),
	.u_wdata256(pmem_wdata),
	.u_read(pmem_read),
	.u_write(pmem_write)
);
	

endmodule : mp2
