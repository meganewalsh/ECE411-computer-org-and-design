module riscy_l2_cache_control (
    input clk,

    output logic read_data,
    output logic set_valid,
    output logic set_dirty,
    output logic clear_dirty,
    output logic load_tag,
    output logic [1:0] way_sel,
    output logic [31:0] data_write_en,

    input logic [1:0] lru_out,
    output logic load_lru,
    // output logic lru_in,

    output logic [2:0] pmem_address_sel,
    output logic [31:0] data_in_sel,
    output logic bus_rdata_sel,

    input logic [3:0] hit,
    input logic [3:0] dirty,
	 input logic [3:0] valid_out,

    input logic [31:0] mem_byte_enable,

    // External Memory Signals
    input logic pmem_resp,
    output logic pmem_write,
    output logic pmem_read,
    output logic vcache_is_dirty,
	 
	input logic mem_read,
	input logic mem_write,
	output logic mem_resp
);

logic lru [3:0];                    // Output of LRU decoder
assign lru[0] = (lru_out == 2'b00);
assign lru[1] = (lru_out == 2'b01);
assign lru[2] = (lru_out == 2'b10);
assign lru[3] = (lru_out == 2'b11);

logic lru_dirty;    // Whether the current LRU is dirty or not
assign lru_dirty = (lru[0] & dirty[0]) | (lru[1] & dirty[1]) | (lru[2] & dirty[2]) | (lru[3] & dirty[3]);

logic lru_valid;    // Whether the current LRU is dirty or not
assign lru_valid = (lru[0] & valid_out[0]) | (lru[1] & valid_out[1]) | (lru[2] & valid_out[2]) | (lru[3] & valid_out[3]);

enum int unsigned {
    IDLE = 0,
    HIT_DETECT = 1,
    LOAD = 2,
    STORE = 3,
    WRITE = 4
} state, next_state;

function void set_defaults();
    way_sel = 2'b0;

    set_valid = 1'b0;

    set_dirty = 1'b0;
    clear_dirty = 1'b0;

    load_tag = 1'b0;

    load_lru = 1'b0;
    // lru_in = 1'b0;

    data_in_sel = 32'hFFFFFFFF;
    data_write_en = 32'd0;
    read_data = 1'b0;

    pmem_address_sel = 3'd0;
    pmem_write = 1'b0;
    pmem_read = 1'b0;
	 
	 mem_resp = 1'b0;
	 
	 bus_rdata_sel = 1'b0;
	 vcache_is_dirty = 1'b0;
endfunction

function void loadLRU();
    load_lru = 1'b1;
    // lru_in = new_lru;
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

always_comb begin : State_Actions
    set_defaults();
    counter_defaults();

    unique case (state)
        IDLE: begin
            if (mem_read | mem_write) begin 
                read_data = 1'b1;
            end
        end
        HIT_DETECT: begin
            if (hit[0] | hit[1] | hit[2] | hit[3]) begin
                mem_resp = 1'b1;
                loadLRU();
                if (mem_write) begin
                    if (hit[0]) way_sel = 2'b00;
                    else if (hit[1]) way_sel = 2'b01;
                    else if (hit[2]) way_sel = 2'b10;
                    else if (hit[3]) way_sel = 2'b11;

                    set_dirty = 1'b1;
                    data_in_sel = 32'hFFFFFFFF; // Load from Bus Adapter
                    data_write_en = mem_byte_enable;
                    write_hits_in = write_hits + 1;
                end else begin
                    read_hits_in = read_hits + 1;
                end
            end else begin
                if (lru_valid) begin
						read_data = 1'd1;           // Prep for storage
						pmem_address_sel = lru_out + 3'd2;
						vcache_is_dirty = lru_dirty;
					 end else begin
						// Going to LOAD            // Prep for Load
						way_sel = lru_out;              // Choose the LRU
						load_tag = 1'b1;            // Update Tag
						clear_dirty = 1'b1;         // Clear Dirty Bit
						data_in_sel = 32'd0;         // Read from PMEM
						data_write_en = 32'hFFFFFFFF;
						pmem_address_sel = 3'd0;    // Addr used for pmem load comes from core
					 end
            end
        end
        LOAD: begin
            data_in_sel = 32'd0;         // Read from PMEM or lower if write
            data_write_en = 32'h00000000;
            pmem_address_sel = 3'd0;    // Addr used for pmem load comes from core
            read_data = 1'b1;
			way_sel = lru_out;              // Choose the LRU
			pmem_read = 1'b1;
            if (pmem_resp) begin
                // Going to IDLE                             
                loadLRU();
                set_valid = 1'd1;
                data_write_en = 32'hFFFFFFFF;
                way_sel = lru_out;
                bus_rdata_sel = 1'b1;					 
                if (mem_write) begin                  
                    data_in_sel = mem_byte_enable; // Write from Core and PMEM into Cache
                    set_dirty = 1'b1; 
                    write_miss_in = write_miss + 1;
                end else begin
                    read_miss_in = read_miss + 1;
                end
                mem_resp = 1'b1;
            end

/*
            read_data = 1'b1;
            pmem_address_sel = 3'd0;    // Addr used for pmem load comes from core
			way_sel = lru_out;              // Choose the LRU

            if (mem_read) begin // Need to read from Upper
			    pmem_read = 1'b1;
                data_in_sel = 32'd0;         // Read from PMEM or lower if write
                if (pmem_resp) begin
                    loadLRU();
                    set_valid = 1'd1;
                    data_write_en = 32'hFFFFFFFF;
                    bus_rdata_sel = 1'b1;
                    read_miss_in = read_miss + 1;
                    mem_resp = 1'b1;
                end
            end else begin      // Need to read from Lower
                data_in_sel = mem_byte_enable; // Write from Core and PMEM into Cache
                loadLRU();
                set_valid = 1'd1;
                data_write_en = 32'hFFFFFFFF;
                set_dirty = 1'b1; 
                write_miss_in = write_miss + 1;
                mem_resp = 1'b1;
            end
*/
        end
        WRITE: begin
            loadLRU();
            way_sel = lru_out;              // Choose the LRU
            data_in_sel = mem_byte_enable; // Write from Core and PMEM into Cache
            set_valid = 1'd1;
            data_write_en = 32'hFFFFFFFF;
            set_dirty = 1'b1; 
            write_miss_in = write_miss + 1;
            mem_resp = 1'b1;
        end
        STORE: begin
			pmem_address_sel = lru_out + 3'd2;
            vcache_is_dirty = lru_dirty;				            
            read_data = 1'd1;
            pmem_write = 1'b1;
            if (pmem_resp) begin
                // Going to LOAD            // Prep for Load                
			    way_sel = lru_out;              // Choose the LRU
                load_tag = 1'b1;            // Update Tag
                clear_dirty = 1'b1;         // Clear Dirty Bit
                data_in_sel = 32'd0;         // Read from PMEM                  
                write_backs_in = write_backs + 1;
            end
        end
        default: set_defaults();
    endcase
end

always_comb begin : Next_State_Logic
    unique case (state)
        IDLE: next_state = (mem_read | mem_write) ? HIT_DETECT : IDLE;
        HIT_DETECT: begin
            if (hit[0] | hit[1] | hit[2] | hit[3]) begin
                // On hit we go back to IDLE
                next_state = IDLE;
            end else begin
                // Otherwise, always store/evict into victim cache					 
					 if (lru_valid) begin
						next_state = STORE;
					 end else begin
						next_state = LOAD;
					 end
            end
        end
        LOAD: next_state = (pmem_resp) ? IDLE : LOAD;
        STORE: next_state = pmem_resp ? (mem_write ? WRITE : LOAD) : STORE;
        WRITE: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

always_ff @(posedge clk) begin : State_Update
    state <= next_state;
    update_counters();
end

endmodule : riscy_l2_cache_control
