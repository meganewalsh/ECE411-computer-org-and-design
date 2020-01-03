module riscy_arbiter
(
	input clk,
	output logic icache_resp,
	input logic icache_read,
	input logic [31:0] icache_u_addr,
	output logic [255:0] icache_u_rdata,

	output logic dcache_resp,
	input logic dcache_read,
	input logic dcache_write,
	input logic [31:0] dcache_u_addr,
	input logic [255:0] dcache_u_wdata,
	output logic [255:0] dcache_u_rdata,

	output logic l2cache_read,
	output logic l2cache_write,
	input logic [255:0] l2cache_rdata,
	output logic [255:0] l2cache_wdata,
	output logic [31:0] l2cache_addr,
	input logic l2cache_resp
);

enum int unsigned {
	icache_inter, dcache_inter, idle
} state, next_states;

function void set_defaults();
	icache_resp = 1'b0;
	dcache_resp = 1'b0;
	l2cache_read = 1'b0;
	l2cache_write = 1'b0;
	l2cache_wdata = 256'b0;
	l2cache_addr = 32'b0;
endfunction	

assign icache_u_rdata = l2cache_rdata;
assign dcache_u_rdata = l2cache_rdata;

always_comb
begin: state_actions

	set_defaults();
	
	unique case (state)
		icache_inter: begin
			l2cache_addr = icache_u_addr;
            l2cache_read = icache_read;
			icache_resp = l2cache_resp;
        end

		dcache_inter: begin
			l2cache_addr = dcache_u_addr;
			dcache_resp = l2cache_resp;
            l2cache_read = dcache_read;
            l2cache_write = dcache_write;
            l2cache_wdata = dcache_u_wdata;
        end
        
		idle: ;
        default: ;
	endcase // state
end

always_comb 
begin: next_state_logic
	unique case(state)
		icache_inter:
			if (l2cache_resp == 1'b1)
				next_states = idle;
			else
				next_states = icache_inter;
			
		dcache_inter:
			if (l2cache_resp == 1'b1)
				next_states = idle;
			else
				next_states = dcache_inter;

		idle:
			if ( dcache_read == 1'b1 | dcache_write == 1'b1 )
			begin
				next_states = dcache_inter;
			end 

			else if ( icache_read == 1'b1 )
			begin
				next_states = icache_inter;
			end
			
			else 
			begin
				next_states = idle; 
			end

		default:
			next_states = idle;

	endcase // state
end


always_ff @(posedge clk)
begin: next_state_assignment
	state <= next_states;
end

endmodule : riscy_arbiter
