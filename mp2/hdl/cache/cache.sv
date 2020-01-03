module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)(
	 input clk,
	 
	 /* Signals between cache and CPU */
	 input logic [3:0] mem_byte_enable,
	 input logic [31:0] mem_address,
	 input logic mem_read,
	 input logic mem_write,
	 input logic [31:0] mem_wdata,
	 output logic [31:0] mem_rdata,
	 output logic mem_resp,	 
	 
	 /* Signals between cache and main memory */
	 input logic [255:0] pmem_rdata,
	 input logic pmem_resp,
	 output logic [31:0] pmem_address,
	 output logic [255:0] pmem_wdata,
	 output logic pmem_read,
	 output logic pmem_write
);

/* Additional control signals */
logic hit;
logic miss;
logic dirty;	 
logic load;
logic read;
logic set_dirty;
logic set_clean; 
logic set_valid;

/* Additional datapath signals */

/* Additional bus adapter signals */
logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;
logic [31:0] mem_byte_enable256;


/* ---- Module instantiation ---- */
cache_control control(.*);

cache_datapath datapath(.*);

bus_adapter adapter( .*, .address(mem_address));

endmodule : cache
