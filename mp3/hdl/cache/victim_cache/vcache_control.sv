module vcache_control (

	input clk,

	 /* Between datapath and control */
	input logic  hit,
	input logic  miss,
	input logic  dirty,
	input logic  hit_dirty,
	input logic  [2:0] lru,
    input logic l_is_dirty,
	output logic load_data,
	output logic set_dirty,
	output logic set_clean,
	output logic u_read,
	output logic [7:0] set_valid,
	output logic u_write,
	output logic l_resp,
    output logic mru_is_lru,
	output logic load_lru,
	
	/* Between cpu and control */
	input logic l_read,
	input logic l_write,
	input logic u_resp
	  
);

enum int unsigned {
    /* List of states */
	IDLE_COMPARE,
	WRITE_BACK,
	ALLOCATE
} state, next_states;

/************************* Function Definitions *******************************/
function void set_defaults();
	load_data = 0;
	set_dirty = 0;
	set_clean = 0;
	u_read = 0;
	u_write = 0;
	l_resp = 0;
	set_valid = 0;
    mru_is_lru = 1'd0;
    load_lru = 1'd0;
endfunction

/*****************************************************************************/
/*P. Counters */
int read_hits = 0;
int write_hits = 0;
int write_miss_not_dirty = 0;
int write_miss_dirty = 0;
int allocates = 0;
int read_hits_in, write_hits_in, write_miss_not_dirty_in, write_miss_dirty_in, allocates_in;

function void counter_defaults();
	read_hits_in = read_hits;
	write_hits_in = write_hits;
	write_miss_not_dirty_in = write_miss_not_dirty;
	write_miss_dirty_in = write_miss_dirty;
	allocates_in = allocates;
endfunction
//TODO more
/*****************************************************************************/

always_comb begin : state_signals
	 set_defaults();
	 counter_defaults();
	
	 unique case (state)	 
	 	IDLE_COMPARE: begin
            if (l_write) begin
                if (hit) begin
				    write_hits_in = write_hits + 1;
                    if (~hit_dirty) begin
                        set_dirty = l_is_dirty;						  
                        set_clean = ~l_is_dirty;						  
                    end
                   load_data = 1;
				   load_lru = 1'd1;
                    l_resp = 1;
                end else if (miss & ~dirty) begin
					write_miss_not_dirty_in = write_miss_not_dirty + 1;
                    set_dirty = l_is_dirty;
                    set_clean = ~l_is_dirty;						  
                    mru_is_lru = 1'd1;				
                    load_data = 1;
					load_lru = 1'd1;
                    l_resp = 1;
                end
            end else if (hit & l_read) begin
                read_hits_in = read_hits + 1;
                load_lru = 1'd1;
				l_resp = 1'd1;
            end
        end
		
		WRITE_BACK: begin
			u_write = 1;
            if (u_resp & l_write) begin
                write_miss_dirty_in = write_miss_dirty + 1;
                set_dirty = l_is_dirty;
                set_clean = ~l_is_dirty;						  
                mru_is_lru = 1'd1;				
                load_data = 1;
                load_lru = 1'd1;
                l_resp = 1;
            end
		end
		
		ALLOCATE: begin
			u_read = 1;
			if (u_resp) begin
			    allocates_in = allocates + 1;
				set_valid[lru] = 1;
                mru_is_lru = 1'd1;		
				load_lru = 1'd1;	 
				load_data = 1;
				set_clean = 1;
				l_resp = 1;
			end
		end
	 endcase
end

always_comb begin : next_state_logic
	 next_states = state;

	 unique case (state)
	 	IDLE_COMPARE: begin
			if ((l_write | l_read) && miss && dirty) begin
            	next_states = WRITE_BACK;
			end else if (l_read && miss && ~dirty) begin
            	next_states = ALLOCATE;
            end
		end
		
		WRITE_BACK: begin
			if (u_resp) begin
                if (l_read) begin
				    next_states = ALLOCATE;
                end else begin
				    next_states = IDLE_COMPARE;
                end
            end
		end
		
		ALLOCATE: begin
			if (u_resp) begin
				next_states = IDLE_COMPARE;
			end
		end
	 endcase
end


always_ff @(posedge clk)
begin: next_state_assignment
	 state <= next_states;

    //Update counters
	read_hits <= read_hits_in;
	write_hits <= write_hits_in;
	write_miss_not_dirty <= write_miss_not_dirty_in;
	write_miss_dirty <= write_miss_dirty_in;
	allocates <= allocates_in;
end
endmodule : vcache_control
