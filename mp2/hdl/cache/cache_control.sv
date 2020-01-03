module cache_control (
	 input clk,
	 input logic mem_read,
	 input logic mem_write,
	 input logic hit,
	 input logic miss,
	 input logic dirty,
	 input logic pmem_resp,
	 
	 output logic load,
	 output logic read,
	 output logic set_dirty,
	 output logic set_clean,
	 output logic set_valid,
	 output logic pmem_read,
	 output logic pmem_write,
	 output logic mem_resp	 
);

enum int unsigned {
    /* List of states */
	idle,
	write_back,
	allocate,
	compare
} state, next_states;

/************************* Function Definitions *******************************/
function void set_defaults();
	load = 0;
	read = 0;
	set_dirty = 0;
	set_clean = 0;
	pmem_read = 0;
	pmem_write = 0;
	mem_resp = 0;
	set_valid = 0;
endfunction

/*****************************************************************************/

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */

	 /* Default no change */ 
	 set_defaults();
	 next_states = state;

	 unique case (state)
	 
	 	idle: begin
			read = 1;
			if (mem_write | mem_read) begin
				next_states = compare;
			end
		end
		
		compare: begin
				if (miss && dirty) begin
					next_states = write_back;
				end else if (miss && ~dirty) begin
					next_states = allocate;
				end else if (hit & mem_write) begin
					set_dirty = 1;
					load = 1;
					mem_resp = 1;
					next_states = idle;
				end else if (hit & mem_read) begin
					mem_resp = 1;
					next_states = idle;
				end
		end
		
		write_back: begin
			pmem_write = 1;
			if (pmem_resp)
				next_states = allocate;
		end
		
		allocate: begin
			pmem_read = 1;
			if (pmem_resp) begin
				load = 1;
				mem_resp = 1;
				set_valid = 1;
				set_clean = 1;
				next_states = idle;
			end
		end
		
	 endcase
	
end


always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_states;
end
endmodule : cache_control
