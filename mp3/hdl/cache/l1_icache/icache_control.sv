import icache_types::*;

module riscy_icache_control(
    input clk,

    /* To/From Datapath */
    input logic [15:0] hit,
    input logic [3:0] hit_way,
    input logic [3:0] lru,

    input logic [15:0] pf_hit,       //For HW Prefetch
    output logic load_pf_tag,

    output logic [15:0] load_data,
    output logic [15:0] set_valid,
    output logic [15:0] clear_valid,
    output logic       load_lru,
    output logic [3:0] mru_in,

    output adapter_mux_sel_t adapter_mux_sel,
    output tag_in_sel_t tag_in_sel,

    /* To/From Lower */
    input logic l_read,
    output logic l_resp,

    /* To/From Upper */
    input logic u_resp,
    output logic u_read
);

typedef enum int {
    HIT_DETECT_NP,      // Hit Detect/Load with and without background prefetch
    LOAD_NP,
    HIT_DETECT_P,
    LOAD_P
} riscy_icache_state_t;

riscy_icache_state_t state, next_state;

function void set_defaults();
    /* To/From Datapath */
    load_data = 'd0;
    set_valid = 'd0;
    clear_valid = 'd0;

    load_lru = 'd0;
    mru_in = lru;

    adapter_mux_sel = mux_data_out;
    tag_in_sel = lower_address;
    load_pf_tag = 1'd1;

    /* To/From Lower */
    l_resp = 1'd0;

    /* To/From Upper */
    u_read = 1'd0;
endfunction

function void updateLRU(logic [3:0] new_mru);
    mru_in = new_mru;
    load_lru = 1'b1;
endfunction

/*****************************************************************************/
/*P. Counters */
int num_prefetch = 0;   //TODO re-do counters
int read_hits = 0;
int read_miss = 0;
int total_reads;
assign total_reads = read_hits + read_miss;
int read_hits_in, read_miss_in, num_prefetch_in;

function void counter_defaults();
    read_hits_in = read_hits;
    read_miss_in = read_miss;
endfunction

task update_counters();
    read_hits <= read_hits_in;
    read_miss <= read_miss_in;
endtask
//TODO more
/*****************************************************************************/

always_comb begin : State_Signals
    set_defaults();

    unique case(state)
        HIT_DETECT_NP: begin
            if (l_read & (hit != 16'd0)) begin
                // HIT, output data
                // Update MRU
                updateLRU(hit_way);

                l_resp = 1'b1;
            end
        end
        LOAD_NP: begin
            if (u_resp) begin
                // Update MRU
                updateLRU(lru);

                // Route Response to Data Array
                load_data = 16'b00000001 << lru;

                // Set Valid
                set_valid = 16'b00000001 << lru;

                // Route Response to output
                adapter_mux_sel = mux_upper_out; 

                l_resp = 1'b1;
            end else begin
                // Read from Upper
                u_read = 1'b1;
            end 
        end
        HIT_DETECT_P: begin
            // Read at Prefetch address
            u_read = 1'b1;
            load_pf_tag = 1'd0;
            tag_in_sel = prefetch_address;

            if (l_read & (hit != 16'd0)) begin
                // Route Response to output
                adapter_mux_sel = mux_data_out; 
                l_resp = 1'b1;
            end

            unique case({u_resp, l_read}) 
                2'b01: begin
                    if (hit != 16'd0) begin
                        // HIT, output data
                        // Update MRU
                        updateLRU(hit_way);
                    end
                end
                2'b10: begin
                    //Route data from upper into lru way, load data into array
                    u_read = 1'b0;
                    // Update MRU
                    updateLRU(lru);

                    // Route Response to Data Array
                    load_data = 16'b00000001 << lru;
    
                    // Set Valid
                    set_valid = 16'b00000001 << lru;
                end
                2'b11: begin
                    //If hit then hit_np, else load_np
                    //Route data from upper into lru way, load data into array
                    u_read = 1'b0;
                    // Update MRU
                    updateLRU(lru);

                    // Route Response to Data Array
                    load_data = 16'b00000001 << lru;
    
                    // Set Valid
                    set_valid = 16'b00000001 << lru;
                end
                default: ;
            endcase
        end
        LOAD_P: begin
            // Read at Prefetch address
            u_read = 1'b1;
            load_pf_tag = 1'd0;
            tag_in_sel = prefetch_address;
            if (u_resp) begin
                 //Route data from upper into lru way, load data into array
                u_read = 1'b0;
                // Update MRU
                updateLRU(lru);

                // Route Response to Data Array
                load_data = 16'b00000001 << lru;

                // Set Valid
                set_valid = 16'b00000001 << lru;
            end
        end
        default: ;
    endcase 
end

always_comb begin : Next_State_Logic_Counters
    counter_defaults();

    unique case(state)
        HIT_DETECT_NP: begin
            if (l_read) begin
                unique case({(hit != 16'd0), (pf_hit != 16'd0)})
                    2'b00: begin // If miss and pf_miss
                        next_state = LOAD_NP;
                    end
                    2'b01: begin // If miss and pf_hit
                        next_state = LOAD_NP;
                    end
                    2'b10: begin // If hit and pf_miss
                        next_state = HIT_DETECT_P;
                    end
                    2'b11: begin // If hit and pf_hit
                        next_state = HIT_DETECT_NP;
                    end
                    default: next_state = HIT_DETECT_NP;
                endcase
            end else begin
                next_state = HIT_DETECT_NP;
            end
        end
        LOAD_NP: begin
            if (u_resp) begin
                if (pf_hit != 16'd0) begin
                    next_state = HIT_DETECT_NP;
                end else begin
                    next_state = HIT_DETECT_P;
                end
            end else begin
                next_state = LOAD_NP;
            end 
        end
        HIT_DETECT_P: begin
            unique case({u_resp, l_read})
                2'b00: next_state = HIT_DETECT_P;
                2'b01: next_state = (hit != 16'd0) ? HIT_DETECT_P : LOAD_P;
                2'b10: next_state = HIT_DETECT_NP;
                2'b11: next_state = HIT_DETECT_NP;
                default: next_state = HIT_DETECT_P;
            endcase
        end
        LOAD_P: begin
            next_state = (u_resp) ? HIT_DETECT_NP : LOAD_P;
        end
        default: next_state = HIT_DETECT_NP;
    endcase 
end

always_ff @(posedge clk) begin : State_Update
    /* Update State on Edge */
    state <= next_state;
    update_counters();
end

endmodule : riscy_icache_control
