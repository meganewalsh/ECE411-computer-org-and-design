module riscy_vcache(
	input clk,

	/* Between vcache and L2 */
	input logic l_read,
	input logic l_write,
	input logic [31:0] l_addr,
	input logic [255:0] l_wdata,
    input logic l_is_dirty,
	output logic l_resp,
	output logic [255:0] l_rdata,
	
	/* Between vcache and pmem */
	input logic u_resp,
	input logic [255:0] u_rdata,
	output logic [31:0] u_addr,
	output logic [255:0] u_wdata,
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
logic hit_dirty;
logic [2:0] lru;
logic mru_is_lru;
logic load_lru;

vcache_control control(.*);

vcache_datapath datapath(.*);
		 
endmodule : riscy_vcache
