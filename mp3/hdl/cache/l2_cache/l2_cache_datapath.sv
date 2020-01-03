module riscy_l2_cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input logic read_data,
    input logic set_valid,
    input logic set_dirty,
    input logic clear_dirty,
    input logic load_tag,
    input logic [1:0] way_sel,
    input logic [31:0] data_write_en,
	 
	 input logic bus_rdata_sel,

    input logic load_lru,
    // input logic lru_in,
    output logic [1:0] lru_out,

    input logic [2:0] pmem_address_sel,
    input logic [31:0] data_in_sel,

    output logic [3:0] hit,
    output logic [3:0] dirty,
	 output logic [3:0] valid_out,

    // External Memory Signals
    input logic mem_write,                // To Lower Level
    input logic mem_read,
    input logic [31:0] mem_address,
    input logic [255:0] mem_wdata,
    output logic [255:0] mem_rdata,

    input logic [255:0] pmem_rdata,       // To Higher Level
    output logic [255:0] pmem_wdata,
    output logic [31:0] pmem_address
);

logic [3:0] way;                    // Output of Way decoder
assign way[0] = (way_sel == 2'b00);
assign way[1] = (way_sel == 2'b01);
assign way[2] = (way_sel == 2'b10);
assign way[3] = (way_sel == 2'b11);

logic [1:0] mru;

logic [127:0] data_write_en_in;      // Data Write enable signal for {Array 3, Array 2, Array 1, Array 0}
logic [3:0] load_tag_in;            // Load Tag signal for {Tag 3, Tag 2, Tag 1, Tag 0} 
logic [3:0] set_dirty_in;
logic [3:0] clear_dirty_in;
logic [3:0] set_valid_in;
logic [3:0] load_dirty;

assign data_write_en_in = {((way[3]) ? data_write_en : 32'd0), ((way[2]) ? data_write_en : 32'd0), ((way[1]) ? data_write_en : 32'd0), ((way[0]) ? data_write_en : 32'd0)};
assign load_tag_in = {((way[3]) ? load_tag : 1'b0), ((way[2]) ? load_tag : 1'b0), ((way[1]) ? load_tag : 1'b0), ((way[0]) ? load_tag : 1'b0)};

assign set_dirty_in = way & {4{set_dirty}};
assign clear_dirty_in = way & {4{clear_dirty}};
assign set_valid_in = way & {4{set_valid}};
assign load_dirty = {(set_dirty_in[3] | clear_dirty_in[3]), (set_dirty_in[2] | clear_dirty_in[2]), (set_dirty_in[1] | clear_dirty_in[1]), (set_dirty_in[0] | clear_dirty_in[0])};

logic [255:0] data_in_mux_out;
logic [255:0] data_out_mux_out;
logic [1023:0] line_out;     // Output of 4 data arrays
logic [95:0] tag_out;       // Output of 4 tag arrays
logic [3:0] dirty_out;      // Output of 4 Dirty arrays
 
/****** Arrays and Bus Adapter ************************************************/
// Data Arrays
riscy_l2_data_array line[3:0](
    .clk(clk),
    .read(read_data),
    .write_en(data_write_en_in),
    .index(mem_address[7:5]),
    .datain(data_in_mux_out),
    .dataout(line_out)
);

// Tag Arrays
riscy_l2_array #(.width(24)) tag[3:0](
    .clk(clk),
    .read(read_data),
    .load(load_tag_in),
    .index(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag_out)
);

// Valid Arrays
riscy_l2_array valid[3:0](
    .clk(clk),
    .read(1'b1),
    .load(set_valid_in),
    .index(mem_address[7:5]),
    .datain(1'b1),
    .dataout(valid_out)
);

// Dirty Arrays
riscy_l2_array DIRTY[3:0](
    .clk(clk),
    .read(1'b1),
    .load(load_dirty),
    .index(mem_address[7:5]),
    .datain(set_dirty_in),
    .dataout(dirty_out)
);
assign dirty = {(dirty_out[3] & valid_out[3]), (dirty_out[2] & valid_out[2]), (dirty_out[1] & valid_out[1]), (dirty_out[0] & valid_out[0])};

// LRU
riscy_l2_lru_array lru(
	.clk(clk),
	.load(load_lru),
    .index(mem_address[7:5]),
	.mru(way_sel),
	.out(lru_out)
);

/****** MUXes *****************************************************************/
always_comb begin : muxes
    // PMEM ADDR SEL MUX
    unique case(pmem_address_sel)
        3'd0:   pmem_address = {mem_address[31:5], 5'd0};                       // From Higher Level
        3'd2:   pmem_address = {tag_out[23:0], mem_address[7:5], 5'd0};         // Way 0
        3'd3:   pmem_address = {tag_out[47:24], mem_address[7:5], 5'd0};        // Way 1
        3'd4:   pmem_address = {tag_out[71:48], mem_address[7:5], 5'd0};		// Way 2
        3'd5:	pmem_address = {tag_out[95:72], mem_address[7:5], 5'd0};		// Way 3
        default: pmem_address = {mem_address[31:5], 5'd0};
    endcase

    // Data Array Input MUX
    for (int i = 0; i < 32; i++) begin
        data_in_mux_out[8*i +: 8] = (data_in_sel[i]) ? mem_wdata[8*i +: 8] : pmem_rdata[8*i +: 8];
    end

    // Data Array Output MUX to Bus Adapter
    unique case(hit)
        4'b0001: data_out_mux_out = line_out[255:0];   // Way 0
        4'b0010: data_out_mux_out = line_out[511:256]; // Way 1
        4'b0100: data_out_mux_out = line_out[767:512]; // Way 2
        4'b1000: data_out_mux_out = line_out[1023:768]; // Way 3
        default: data_out_mux_out = 256'd0;
    endcase

    // Data Array Output MUX to PMEM
    unique case(lru_out)
        2'b00: pmem_wdata = line_out[255:0];   // Way 0
        2'b01: pmem_wdata = line_out[511:256]; // Way 1
        2'b10: pmem_wdata = line_out[767:512]; // Way 2
        2'b11: pmem_wdata = line_out[1023:768]; // Way 3
        default: pmem_wdata = 256'd0;
    endcase
	 
	 // Bus rdata output MUX
	 unique case (bus_rdata_sel)
		  1'b0: mem_rdata = data_out_mux_out;
		  1'b1: mem_rdata = pmem_rdata;
		  default: mem_rdata = data_out_mux_out;
	 endcase
end

/****** Hit Comparators *******************************************************/
assign hit[0] = valid_out[0] & (mem_address[31:8] == tag_out[23:0]);   // Check if Hit on Way 0
assign hit[1] = valid_out[1] & (mem_address[31:8] == tag_out[47:24]);  // Check if Hit on Way 1
assign hit[2] = valid_out[2] & (mem_address[31:8] == tag_out[71:48]);  // Check if Hit on Way 2
assign hit[3] = valid_out[3] & (mem_address[31:8] == tag_out[95:72]);  // Check if Hit on Way 3

endmodule : riscy_l2_cache_datapath
