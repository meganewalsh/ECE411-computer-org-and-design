module riscy_icache_adapter
(
    input [255:0] rdata256,
    input [31:0] resp_address,
    output [31:0] rdata
);

assign rdata = rdata256[(32*resp_address[4:2]) +: 32];

endmodule : riscy_icache_adapter
