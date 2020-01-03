import icache_types::*;

module riscy_icache_datapath(
    input clk,

    /* To/From Control */
    input logic [15:0] load_data,
    input logic [15:0] set_valid,
    input logic [15:0] clear_valid,
    input logic       load_lru,
    input logic [3:0] mru_in,

    input adapter_mux_sel_t adapter_mux_sel,
    input tag_in_sel_t tag_in_sel,

    output logic [15:0] hit,
    output logic [3:0] hit_way,
    output logic [3:0] lru,

    input logic load_pf_tag,
    output logic [15:0] pf_hit,      //For HW prefetch

    /* To/From Lower */
    input logic [31:0]  l_addr,
    output logic [31:0] l_rdata,

    /* To/From Upper */
    input logic [255:0] u_rdata,
    output logic [31:0] u_addr 
);

logic [26:0] pf_tag_addr, pf_tag_addr_in;   // Address of line to prefetch
assign pf_tag_addr_in = (load_pf_tag) ? (l_addr[31:5] + 27'd1) : pf_tag_addr;
always_ff @(posedge clk) begin
    pf_tag_addr <= pf_tag_addr_in;
end

assign u_addr = {(tag_in_sel ? pf_tag_addr : l_addr[31:5]), 5'd0};

logic [15:0] comp_out;   // Output of comparators
logic [15:0] pf_comp_out;// Output of prefetch comparators
logic [15:0] valid;

logic [(16*27)-1:0] tag_out;
logic [26:0] tag_in;
assign tag_in = (tag_in_sel) ? pf_tag_addr : l_addr[31:5];

wire [4095:0] data_out;

logic [255:0] data_mux_out;
logic [255:0] adapter_mux_out;

// Data Array
riscy_icache_array #(.width(256)) data[15:0](
    .clk(clk),
    .load(load_data),
    .in(u_rdata),
    .out(data_out)
);

// Tag Array
riscy_icache_array #(.width(27)) tag[15:0](
    .clk(clk),
    .load(load_data),
    .in(tag_in),
    .out(tag_out)
);

// Valid Array
riscy_icache_array valid_arr[15:0](
    .clk(clk),
    .load((set_valid | clear_valid)),
    .in(set_valid),
    .out(valid)
);

riscy_lru_array_16 lru_arr(
    .clk(clk),
    .load(load_lru),
    .mru(mru_in),
    .out(lru)
);

// Line Adapter
riscy_icache_adapter adapter(
    .rdata256(adapter_mux_out),
    .resp_address(l_addr),
    .rdata(l_rdata)
);

assign hit = valid & comp_out;
assign pf_hit = valid & pf_comp_out;

always_comb begin : Comparators
    for (int i = 0; i < 16; i++) begin
        comp_out[i] = l_addr[31:5] == tag_out[(i*27) +: 27];
        pf_comp_out[i] = pf_tag_addr_in == tag_out[(i*27) +: 27];
    end
end

always_comb begin : MUXes
    /* Data MUX */
    unique case(hit)
        16'd32768: begin data_mux_out = data_out[(15*256) +: 256]; hit_way = 4'd15; end
        16'd16384: begin data_mux_out = data_out[(14*256) +: 256]; hit_way = 4'd14; end
        16'd8192: begin data_mux_out = data_out[(13*256) +: 256]; hit_way = 4'd13; end
        16'd4096: begin data_mux_out = data_out[(12*256) +: 256]; hit_way = 4'd12; end
        16'd2048: begin data_mux_out = data_out[(11*256) +: 256]; hit_way = 4'd11; end
        16'd1024: begin data_mux_out = data_out[(10*256) +: 256]; hit_way = 4'd10; end 
        16'd512: begin data_mux_out = data_out[(9*256) +: 256]; hit_way = 4'd9; end
        16'd256: begin data_mux_out = data_out[(8*256) +: 256]; hit_way = 4'd8; end
        16'd128: begin data_mux_out = data_out[(7*256) +: 256]; hit_way = 4'd7; end
        16'd64: begin data_mux_out = data_out[(6*256) +: 256]; hit_way = 4'd6; end
        16'd32: begin data_mux_out = data_out[(5*256) +: 256]; hit_way = 4'd5; end
        16'd16: begin data_mux_out = data_out[(4*256) +: 256]; hit_way = 4'd4; end
        16'd8: begin data_mux_out = data_out[(3*256) +: 256]; hit_way = 4'd3; end
        16'd4: begin data_mux_out = data_out[(2*256) +: 256]; hit_way = 4'd2; end 
        16'd2: begin data_mux_out = data_out[(1*256) +: 256]; hit_way = 4'd1; end
        16'd1: begin data_mux_out = data_out[(0*256) +: 256]; hit_way = 4'd0; end
        default:     begin data_mux_out = data_out[(0*256) +: 256]; hit_way = 4'd0; end
    endcase

    /* Adapter MUX */
    unique case (adapter_mux_sel)
        mux_data_out:   adapter_mux_out = data_mux_out;
        mux_upper_out:  adapter_mux_out = u_rdata;
        default:        adapter_mux_out = data_mux_out;
    endcase
end

endmodule : riscy_icache_datapath
