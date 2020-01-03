module dcache_datapath(

	input clk,
	
	/* Between datapath and control */
	input logic  load_data,
	input logic  set_dirty,
	input logic  set_clean,
	input logic  [7:0] set_valid,
	input logic  u_read,
	input logic  u_write,
	input logic  dcache_resp,
    input logic  mru_is_lru,
    input logic [1:0] mbe_sel,
	output logic hit,
	output logic miss,
	output logic dirty,
	output logic [2:0] lru,
	
	/* Between datapath and cpu */
	input logic l_write,
	input logic l_read,
	input logic [31:0] l_addr,
	 
	/* Between datapath and line adapter*/
	input logic [31:0]   mem_byte_enable256,
	input logic [255:0]  mem_wdata256,
	output logic [255:0] mem_rdata256,

	/* Between datapath and arbiter */
	input logic [255:0]  u_rdata256,	
	output logic [255:0] u_wdata256,
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

always_comb begin : Upper
    u_wdata256 = data_out[lru];
    dirty = dirty_out[lru] & valid[lru];

	if (u_write) begin
		u_addr = {tag_out[lru], 5'h0};
	end else begin
		u_addr = {l_addr[31:5], 5'd0};
	end
end

always_comb begin : Ld
	for (int i = 0; i < 8; i++) begin
		ld[i] = (hit) ? (load_data & hit_arr[i]) : (load_data & lru == i);
	end
end

always_comb begin : Mbe
    unique case(mbe_sel)
        2'd1: begin
            for (int i = 0; i < 8; i++) begin mbe[i] = (ld[i]) ? mem_byte_enable256: 0; end
        end
        2'd2: begin
            for (int i = 0; i < 8; i++) begin mbe[i] = (ld[i]) ? 32'hffffffff: 0; end
        end
        2'd3: begin
            for (int i = 0; i < 8; i++) begin mbe[i] = (ld[i]) ? 32'hffffffff: 0; end
        end
        default: begin
            for (int i = 0; i < 8; i++) begin mbe[i] = 0; end
        end
    endcase
end

always_comb begin : Hits
	for (int i = 0; i < 8; i++) begin
		hit_arr[i] = (tag_out[i] == tag_addr) & valid[i]; end
	hit  = (l_read | l_write) & (hit_arr[0] | hit_arr[1] | hit_arr[2] | hit_arr[3] | hit_arr[4] | hit_arr[5] | hit_arr[6] | hit_arr[7]);
	miss = (l_read | l_write) & ~hit;
end

dcache_data_array data_arr [7:0] (
	.clk(clk),
	.datain(data_in),
	.write_en(mbe),
	.read(1'b1),
	.dataout(data_out)
);

dcache_array #(.width(27)) tag_arr [7:0] (
	.clk(clk),
	.in(tag_addr),
	.load(ld),
	.read(1'b1),
	.out(tag_out)
);

dcache_array valid_arr [7:0] (
	.clk(clk),
   .in(1'b1),
	.load(set_valid),
	.read(1'b1),
   .out(valid)
);

dcache_array dirty_arr [7:0] (
	.clk(clk),
	.read(miss),
   .load({((set_dirty|set_clean)&ld[7]), ((set_dirty|set_clean)&ld[6]), ((set_dirty|set_clean)&ld[5]), ((set_dirty|set_clean)&ld[4]), ((set_dirty|set_clean)&ld[3]), ((set_dirty|set_clean)&ld[2]), ((set_dirty|set_clean)&ld[1]), ((set_dirty|set_clean)&ld[0])}),
   .in(set_dirty),
   .out(dirty_out)
);

// TODO lru
riscy_plru_array_8 lru_array(
   .clk(clk),
   .load(dcache_resp),
   .mru(mru),
   .out(lru) // index of replacement
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
        default: mru = mru_hit_in;
    endcase
	
	/* mem_rdata256 mux */
	unique case (hit)
		1'b1:				mem_rdata256 = data_mux_out;
		default:			mem_rdata256 = u_rdata256;
	endcase
	
	/* data_in mux */
    unique case(mbe_sel)
    2'd1: begin
        for (int i = 0; i < 32; i++) begin
            data_in[8*i +: 8] = (mem_byte_enable256[i]) ? mem_wdata256[8*i +: 8] 
                                                        : u_rdata256[8*i +: 8];
        end
    end
    2'd2: begin
        for (int i = 0; i < 32; i++) begin
            data_in[8*i +: 8] = (mem_byte_enable256[i]) ? mem_wdata256[8*i +: 8] 
                                                        : u_rdata256[8*i +: 8];
        end
    end
    2'd3: begin
        data_in = u_rdata256;
    end
    default: data_in = u_rdata256;
    endcase
end

endmodule : dcache_datapath
