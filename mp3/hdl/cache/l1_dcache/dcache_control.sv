module dcache_control (

	input clk,

	 /* Between datapath and control */
	input logic  hit,
	input logic  miss,
	input logic  dirty,
	input logic  [2:0] lru,
	output logic load_data,
	output logic set_dirty,
	output logic set_clean,
	output logic u_read,
	output logic [7:0] set_valid,
	output logic u_write,
	output logic dcache_resp,
    output logic mru_is_lru,
    output logic [1:0] mbe_sel, //TODO
	
	/* Between cpu and control */
	input logic l_read,
	input logic l_write,
	input logic u_resp
	  
);

enum int unsigned {
    /* List of states */
	idle_compare,
	write_back,
	allocate
} state, next_states;

/************************* Function Definitions *******************************/
function void set_defaults();
	load_data = 0;
	set_dirty = 0;
	set_clean = 0;
	u_read = 0;
	u_write = 0;
	dcache_resp = 0;
	set_valid = 0;
    mru_is_lru = 1'd0;
    mbe_sel = 2'd0;
endfunction

/*****************************************************************************/
/*P. Counters */
int read_hits = 0;
int write_hits = 0;
int read_miss = 0;
int write_miss = 0;
int write_backs = 0;
int read_hits_in, write_hits_in, write_miss_in, read_miss_in, write_backs_in;

int total_writes, total_reads, total_hits, total_access;
assign total_hits = read_hits + write_hits;
assign total_writes = write_hits + write_miss;
assign total_reads = read_hits + read_miss;
assign total_access = total_writes + total_reads;

function void counter_defaults();
    read_hits_in = read_hits;
    write_hits_in = write_hits;
    read_miss_in = read_miss;
    write_miss_in = write_miss;
    write_backs_in = write_backs;
endfunction

task update_counters();
    read_hits <= read_hits_in;
    write_hits <= write_hits_in;
    read_miss <= read_miss_in;
    write_miss <= write_miss_in;
    write_backs <= write_backs_in;
endtask
//TODO more
/*****************************************************************************/

always_comb begin : state_signals
	 set_defaults();

	 unique case (state)
	 	idle_compare: begin
			if (l_write | l_read) begin
                if (hit & l_write) begin
					set_dirty = 1;
                    mbe_sel = 2'd1;
					load_data = 1;
					dcache_resp = 1;
				end else if (hit & l_read) begin
					dcache_resp = 1;
				end
			end
		end
		
		write_back: begin
			u_write = 1;
		end
		
		allocate: begin
			u_read = 1;
			if (u_resp) begin
				set_valid[lru] = 1;
				load_data = 1;
                mru_is_lru = 1'd1;
                if (l_read) begin
                    mbe_sel = 2'd3;
				    set_clean = 1;
                end else begin
                    mbe_sel = 2'd2;
				    set_dirty = 1;
                end
				dcache_resp = 1;
			end
		end
	 endcase
end

	
always_comb begin : next_state_logic_and_counter
	 next_states = state;
     counter_defaults();

	 unique case (state)
	 	idle_compare: begin
			if (l_write | l_read) begin
				if (miss && dirty) begin
					next_states = write_back;
                    if (l_write) begin write_miss_in = write_miss + 1; end
                    else begin read_miss_in = read_miss + 1; end 
				end else if (miss && ~dirty) begin
					next_states = allocate;
                    if (l_write) begin write_miss_in = write_miss + 1; end
                    else begin read_miss_in = read_miss + 1; end 
				end else if (hit & l_write) begin
					next_states = idle_compare;
                    write_hits_in = write_hits + 1;
				end else if (hit & l_read) begin
					next_states = idle_compare;
                    read_hits_in = read_hits + 1;
				end
			end
		end
		
		write_back: begin
			if (u_resp) begin
				next_states = allocate;
                write_backs_in = write_backs + 1;
            end
		end
		
		allocate: begin
			if (u_resp) begin
				next_states = idle_compare;
			end
		end
	 endcase
end : next_state_logic_and_counter


always_ff @(posedge clk)
begin: next_state_assignment
	 state <= next_states;
     update_counters();
end
endmodule : dcache_control
