import icache_types::*;

module riscy_icache(
    input clk,

    /* To/From Lower */
    input logic l_read,
    input logic [31:0] l_addr,
    output logic [31:0] l_rdata,
    output logic l_resp,

    /* To/From Upper */
    input logic u_resp,
    input logic [255:0] u_rdata,
    output logic u_read,
    output logic [31:0] u_addr 
);

/* To/From Control */
logic [15:0] load_data;
logic [15:0] set_valid;
logic [15:0] clear_valid;
logic       load_lru;
logic [3:0] mru_in;

adapter_mux_sel_t adapter_mux_sel;

logic [15:0] hit;
logic [3:0] hit_way;
logic [3:0] lru;

logic load_pf_tag;
logic [15:0] pf_hit;       //For HW Prefetch
tag_in_sel_t tag_in_sel;

riscy_icache_datapath ic_dp(.*);

riscy_icache_control ic_c(.*);

endmodule : riscy_icache


