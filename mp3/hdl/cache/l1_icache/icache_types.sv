package icache_types;

typedef enum logic {
    mux_data_out = 1'b0,    // Output Data Array
    mux_upper_out = 1'b1    // Output upper_rdata
} adapter_mux_sel_t;

typedef enum logic {
    lower_address = 1'b0,
    prefetch_address = 1'b1
} tag_in_sel_t;

endpackage : icache_types
