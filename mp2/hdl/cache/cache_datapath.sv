`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)(
	 input clk,
	 
	 /* Signals between control */
	 input logic load,
	 input logic read,
	 input logic set_dirty,
	 input logic set_clean,
	 input logic set_valid,
	 input logic pmem_read,
	 input logic pmem_write,
	 input logic mem_resp,	
	 output logic hit,
	 output logic miss,
	 output logic dirty, 
	 	 
	 /* Signals between cache and CPU */
	 input logic mem_write,
	 input logic mem_read,
	 input logic [31:0] mem_address,
	 
	 /* Signals between cache and main memory */
	 output logic [31:0] pmem_address,
	 output logic [255:0] pmem_wdata,
	 input logic [255:0] pmem_rdata,
	 
	 /* Signals between cache and bus adapter */
	 input logic [31:0] mem_byte_enable256,
	 input logic [255:0] mem_wdata256,
	 output logic [255:0] mem_rdata256
);

logic [2:0]  idx, block_offset;
logic [23:0] m_tag, tag_arr0_out, tag_arr1_out;
logic [255:0] din, data_arr0_out, data_arr1_out;
logic valid_arr0_out, valid_arr1_out, lrumux_out;
logic hit0, hit1, lru_arr_out,dirty_arr0_out, dirty_arr1_out;
logic lru_reg0_out, lru_reg1_out, lru_reg2_out, lru_reg3_out, lru_reg4_out, lru_reg5_out, lru_reg6_out, lru_reg7_out, hit_line, miss_line, lru_arr_in;
logic [31:0] mbe0, mbe1;
datamux::datamux_sel_t datamux_sel;
logic ld0, ld1;

always_comb begin
	/* Breaking up the address */
	m_tag = mem_address[s_offset+s_index+s_tag-1:s_offset+s_index];
	idx = mem_address[s_offset+s_index-1:s_offset];
	block_offset = mem_address[s_offset-1:0];

	din = (mem_write) ? mem_wdata256 : mem_rdata256;
	
	/* Hit detection */
	hit0 = (mem_write | mem_read) & (valid_arr0_out) ? ((tag_arr0_out == m_tag) ? 1 : 0) : 0;
	hit1 = (mem_write | mem_read) & (valid_arr1_out) ? ((tag_arr1_out == m_tag) ? 1 : 0) : 0;
	hit = (hit0 | hit1);
	miss = (mem_write | mem_read) & ~hit;

end

/*****************************************************************************/
/**********************************Arrays*************************************/

/* Two valid arrays */
array valid_arr0(
	.clk(clk),
	.read(read),
   .load(ld0),
   .index(idx),
   .datain(1'b1),
   .dataout(valid_arr0_out)
);
array valid_arr1(
	.clk(clk),
	.read(read),
   .load(ld1),
   .index(idx),
   .datain(1'b1),
   .dataout(valid_arr1_out)
);


/* Two tag arrays */
array #(.width(24)) tag[1:0](
	.clk(clk),
	.read(read),
   .load({ld1, ld0}),
   .index(idx),
   .datain(m_tag),
   .dataout({tag_arr1_out, tag_arr0_out})
);
/* Two data arrays */
data_array line[1:0](
		.clk(clk),
		.read(read),
		.write_en({mbe1, mbe0}),
		.index(idx),
		.datain(din),
		.dataout({data_arr1_out, data_arr0_out})
);

/* One lru array */
array lru_arr(
	.clk(clk),
	.read(miss),
   .load(mem_resp),
   .index(idx),
   .datain(lru_arr_in),
   .dataout(lru_arr_out)
);
register #(.width(1)) lru_reg0(
   .clk(clk),
   .load(idx == 0),
   .in(~lru_arr_out),
   .out(lru_reg0_out)

);
register #(.width(1)) lru_reg1(
   .clk(clk),
   .load(idx == 1),
   .in(~lru_arr_out),
   .out(lru_reg1_out)

);register #(.width(1)) lru_reg2(
   .clk(clk),
   .load(idx == 2),
   .in(~lru_arr_out),
   .out(lru_reg2_out)

);register #(.width(1)) lru_reg3(
   .clk(clk),
   .load(idx == 3),
   .in(~lru_arr_out),
   .out(lru_reg3_out)

);register #(.width(1)) lru_reg4(
   .clk(clk),
   .load(idx == 4),
   .in(~lru_arr_out),
   .out(lru_reg4_out)

);register #(.width(1)) lru_reg5(
   .clk(clk),
   .load(idx == 5),
   .in(~lru_arr_out),
   .out(lru_reg5_out)

);register #(.width(1)) lru_reg6(
   .clk(clk),
   .load(idx == 6),
   .in(~lru_arr_out),
   .out(lru_reg6_out)

);register #(.width(1)) lru_reg7(
   .clk(clk),
   .load(idx == 7),
   .in(~lru_arr_out),
   .out(lru_reg7_out)

);

/* Two dirty arrays */
array dirty_arr_0(
	.clk(clk),
	.read(miss),
   .load((set_dirty | set_clean) & ld0),
   .index(idx),
   .datain(set_dirty),
   .dataout(dirty_arr0_out)
);
array dirty_arr_1(
	.clk(clk),
	.read(miss),
   .load((set_dirty | set_clean) & ld1),
   .index(idx),
   .datain(set_dirty),
   .dataout(dirty_arr1_out)
);


/*****************************************************************************/
/******************************** Muxes **************************************/

always_comb begin : MUXES
	 
	 /* lrumux */
	unique case (idx)
			3'b000:		miss_line = lru_reg0_out;									
			3'b001:		miss_line = lru_reg1_out;	
			3'b010:		miss_line = lru_reg2_out;	
			3'b011:		miss_line = lru_reg3_out;	
			3'b100:		miss_line = lru_reg4_out;	
			3'b101:		miss_line = lru_reg5_out;	
			3'b110:		miss_line = lru_reg6_out;	
			3'b111:		miss_line = lru_reg7_out;
			default:		miss_line = 0;
	endcase
	unique case ({hit0, hit1})
			2'b01:		hit_line = 0;
			2'b10:		hit_line = 1;
			default:		hit_line = 0;
	endcase
	unique case (hit)
			1'b0:			lru_arr_in = miss_line;
			1'b1:			lru_arr_in = hit_line;
			default:		lru_arr_in = 0;
	endcase
	
	/* Write enable logic */
	unique case (hit)
			1'b0: begin
				ld0 = (load & ~lru_arr_out);
				ld1 = (load & lru_arr_out);
			end
			1'b1: begin
				ld0 =	(load & hit0);
				ld1 = (load & hit1);
			end
			default: begin
				ld0 = 0;
				ld1 = 0;
			end
	endcase
	unique case ({ld0, ld1})
		2'b10: begin
				mbe1 = 0;
				if (mem_write)			mbe0 = mem_byte_enable256;
				else if (mem_read)	mbe0 = 32'hffffffff;
				else						mbe0 = 32'h0;
		end
		2'b01: begin
				mbe0 = 0;
				if (mem_write)			mbe1 = mem_byte_enable256;
				else if (mem_read)	mbe1 = 32'hffffffff;
				else						mbe1 = 32'h0;
		end
		default: begin
				mbe0 = 0;
				mbe1 = 0;
		end
	endcase
	
	/* Read data logic */
	unique case (hit)
		1'b1: begin
			if (hit0)	mem_rdata256 = data_arr0_out;
			else			mem_rdata256 = data_arr1_out;
		end
		default: 		mem_rdata256 = pmem_rdata;
	endcase
	
	/* Dirty & write data logic */
	unique case (lru_arr_out)
		1'b0: begin
				dirty = dirty_arr0_out;
				pmem_wdata = data_arr0_out;
		end
		1'b1: begin
				dirty = dirty_arr1_out;
				pmem_wdata = data_arr1_out;
		end
		default: begin
				dirty = 0;
				pmem_wdata = 256'h0;
		end
	endcase

	/* pmem_address muxes */
	unique case ({pmem_write, pmem_read})
		2'b10: begin
			unique case (lru_arr_out)
				1'b0:		pmem_address = {tag_arr0_out, idx, 5'h0};
				1'b1:		pmem_address = {tag_arr1_out, idx, 5'h0};
				default: pmem_address = 32'h0;
			endcase		
		end
		2'b01:	pmem_address = mem_address;
		default: pmem_address = 32'h0;
	endcase
	
end

/*****************************************************************************/

	 
endmodule : cache_datapath
