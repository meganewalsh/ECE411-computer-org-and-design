module riscy_l2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,

    input mem_write,                // To Lower Level
    input mem_read,
    input [31:0] mem_byte_enable,
    input [31:0] mem_address,
    input [255:0] mem_wdata,
    output [255:0] mem_rdata,
    output mem_resp,
   
    input [255:0] pmem_rdata,       // To Higher Level
    input pmem_resp,
    output pmem_write,
    output pmem_read,
    output [255:0] pmem_wdata,
    output [31:0] pmem_address,
    output logic vcache_is_dirty
);

// Connecting Signals
logic read_data;
logic set_valid;
logic set_dirty;
logic clear_dirty;
logic load_tag;
logic [1:0] way_sel;
logic [31:0] data_write_en;
logic load_lru;
// logic lru_in;
logic [1:0] lru_out;
logic [2:0] pmem_address_sel;
logic [31:0] data_in_sel;
logic [3:0] hit;
logic [3:0] dirty;
logic [3:0] valid_out;
logic bus_rdata_sel;

// Module Instantiation

riscy_l2_cache_control control(.*);

riscy_l2_cache_datapath datapath(.*);

endmodule : riscy_l2_cache
