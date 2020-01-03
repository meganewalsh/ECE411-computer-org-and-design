module riscy_dcache(

	input clk,

	/* Between dcache and cpu */
	input logic l_read,
	input logic l_write,
	input logic [3:0] l_wmask,
	input logic [31:0] l_addr,
	input logic [31:0] l_wdata,
	output logic dcache_resp,
	output logic [31:0] dcache_rdata,
	
	/* Between dcache and arbiter */
	input logic u_resp,
	input logic [255:0] u_rdata256,
	output logic [31:0] u_addr,
	output logic [255:0] u_wdata256,
	output logic u_read,
	output logic u_write
	
);

/* Between datapath and control */
logic load_data;
logic set_dirty;
logic set_clean;
logic [7:0] set_valid;
logic hit;
logic miss;
logic dirty;
logic [2:0] lru;
logic mru_is_lru;
logic [1:0] mbe_sel;
	
/* Between datapath and line adapter*/
logic [31:0] mem_byte_enable256;
logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;

dcache_control control(.*);

dcache_datapath datapath(.*);
		 
line_adapter adapter(
	.mem_rdata256(mem_rdata256),
	.mem_wdata(l_wdata),
	.mem_byte_enable(l_wmask),
	.resp_address(l_addr),
   .address(l_addr),
	
	.mem_wdata256(mem_wdata256),
	.mem_rdata(dcache_rdata),
	.mem_byte_enable256(mem_byte_enable256)
);

endmodule : riscy_dcache
