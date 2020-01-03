`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)
module vcache_datapath(

	input clk,
	
	/* Between datapath and control */
	input logic  load_data,
	input logic  set_dirty,
	input logic  set_clean,
	input logic  [7:0] set_valid,
	input logic  u_read,
	input logic  u_write,
	input logic  l_resp,
   input logic  mru_is_lru,
	input logic  load_lru,
	output logic hit,
	output logic miss,
	output logic dirty,
    output logic hit_dirty, //Whether the hit way is dirty
	output logic [2:0] lru,
	
	/* Between datapath and cpu */
	input logic l_write,
	input logic l_read,
	input logic [31:0] l_addr,
	input logic [255:0]  l_wdata,
	output logic [255:0] l_rdata,

	/* Between datapath and pmem */
	input logic [255:0]  u_rdata,	
	output logic [255:0] u_wdata,
	output logic [31:0]  u_addr
);

logic [7:0] dirty_out, hit_arr, valid, ld;
logic [31:0] mbe [7:0];
logic [255:0] data_out [7:0];
logic [26:0] tag_addr;
logic [26:0] tag_out [7:0];
logic [255:0] data_mux_out, data_in; 
logic [2:0] mru, mru_hit_in;

assign tag_addr = l_addr[31:5];

assign hit_dirty = (hit_arr & valid & dirty_out) != 8'd0;

always_comb begin : Upper
    u_wdata = data_out[lru];
    dirty = dirty_out[lru] & valid[lru];

	if (u_write) begin
		u_addr = {tag_out[lru], 5'h0};
	end else begin
		u_addr = l_addr;
	end
end

always_comb begin : Ld
	for (int i = 0; i < 8; i++) begin
		ld[i] = (hit) ? (load_data & hit_arr[i]) : (load_data & (lru == i));
	end
end

always_comb begin : Mbe
	for (int i = 0; i < 8; i++) begin
        mbe[i] = (ld[i]) ? 32'hFFFFFFFF : 0;
	end
end

always_comb begin : Hits
	for (int i = 0; i < 8; i++) begin
		hit_arr[i] = (tag_out[i] == tag_addr) & valid[i];
	end
	hit  = (hit_arr[0] | hit_arr[1] | hit_arr[2] | hit_arr[3] | hit_arr[4] | hit_arr[5] | hit_arr[6] | hit_arr[7]);
	miss = ~hit;
end

vcache_data_array data_arr [7:0] (
	.clk(clk),
	.datain(data_in),
	.write_en(mbe),
	.read(1'b1),
	.dataout(data_out)
);

vcache_array #(.width(27)) tag_arr [7:0] (
	.clk(clk),
	.in(tag_addr),
	.load(ld),
	.read(1'b1),
	.out(tag_out)
);

vcache_array valid_arr [7:0] (
	.clk(clk),
   .in(1'b1),
	.load(set_valid),
	.read(1'b1),
   .out(valid)
);

vcache_array dirty_arr [7:0] (
	.clk(clk),
	.read(miss),
   .load({((set_dirty|set_clean)&ld[7]), ((set_dirty|set_clean)&ld[6]), ((set_dirty|set_clean)&ld[5]), ((set_dirty|set_clean)&ld[4]), ((set_dirty|set_clean)&ld[3]), ((set_dirty|set_clean)&ld[2]), ((set_dirty|set_clean)&ld[1]), ((set_dirty|set_clean)&ld[0])}),
   .in(set_dirty),
   .out(dirty_out)
);

riscy_lru_array_8 lru_array(
   .clk(clk),
   .load(load_lru),
   .mru(mru),
   .out(lru)
);

/************************* MUXES *************************/
always_comb begin : Muxes
	/* data mux */
	unique case (hit_arr)
		8'b10000000:	begin mru_hit_in = 3'd7; data_mux_out = data_out[7]; end
		8'b01000000:	begin mru_hit_in = 3'd6; data_mux_out = data_out[6]; end
		8'b00100000:	begin mru_hit_in = 3'd5; data_mux_out = data_out[5]; end
		8'b00010000:	begin mru_hit_in = 3'd4; data_mux_out = data_out[4]; end
		8'b00001000:	begin mru_hit_in = 3'd3; data_mux_out = data_out[3]; end
		8'b00000100:	begin mru_hit_in = 3'd2; data_mux_out = data_out[2]; end
		8'b00000010:	begin mru_hit_in = 3'd1; data_mux_out = data_out[1]; end
		8'b00000001:	begin mru_hit_in = 3'd0; data_mux_out = data_out[0]; end
		default:        begin mru_hit_in = 3'd0; data_mux_out = 256'b0; end
	endcase

    /* MRU Mux*/
    unique case (mru_is_lru)
        1'd0:   mru = mru_hit_in;
        1'd1:   mru = lru;
        default: begin mru = mru_hit_in; end
    endcase
	
	/* l_rdata mux */
	unique case (hit)
		1'b1:				l_rdata = data_mux_out;
		default:			l_rdata = u_rdata;
	endcase
	
	/* data_in mux */
	unique case (l_write)
		1'b0:				data_in = u_rdata;
		1'b1:				data_in = l_wdata;
		default:			data_in = 256'b0;
	endcase
	
end

endmodule : vcache_datapath
