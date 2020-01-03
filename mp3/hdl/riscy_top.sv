import rv32i_types::*;

module riscy_top(
    input clk,
    input pmem_resp,
    input [255:0] pmem_rdata,
     
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [255:0] pmem_wdata
);

/* CPU to/from ICache */
logic icache_resp;
logic [31:0] icache_rdata;
logic icache_read;
logic [31:0] icache_addr;
/* ICache */
logic icache_u_resp;
logic [255:0] icache_u_rdata;
logic icache_u_read;
logic [31:0] icache_u_addr;

/* Between dcache and cpu */
logic dcache_read;
logic dcache_write;
logic [3:0] dcache_wmask;
logic [31:0] dcache_addr;
logic [31:0] dcache_wdata;
logic dcache_resp;
logic [31:0] dcache_rdata;
/* Between dcache and arbiter */
logic dcache_u_resp;
logic [255:0] dcache_u_rdata256;
logic [31:0] dcache_u_addr;
logic [255:0] dcache_u_wdata256;
logic dcache_u_read;
logic dcache_u_write;

/* Between L2 cache and arbiter */
logic [255:0] l2cache_rdata;
logic [255:0] l2cache_wdata;
logic [31:0] l2cache_addr;
logic l2cache_resp;
logic l2cache_read;
logic l2cache_write;

/* Between vcache and L2 */
logic vcache_read;
logic vcache_write;
logic [31:0] vcache_addr;
logic [255:0] vcache_wdata;
logic vcache_is_dirty;
logic vcache_resp;
logic [255:0] vcache_rdata;

riscy_cpu cpu(.*);

riscy_dcache dcache(
    .clk(clk),
    .l_read(dcache_read),
    .l_write(dcache_write),
    .l_wmask(dcache_wmask),
    .l_addr(dcache_addr),
    .l_wdata(dcache_wdata),
    .u_resp(dcache_u_resp),
    .u_rdata256(dcache_u_rdata256),

    .dcache_resp(dcache_resp),
    .dcache_rdata(dcache_rdata),
    .u_addr(dcache_u_addr),
    .u_wdata256(dcache_u_wdata256),
    .u_read(dcache_u_read),
    .u_write(dcache_u_write)
);
    
riscy_icache icache(
    .clk(clk),
    /* To/From Lower */
    .l_read(icache_read),
    .l_addr(icache_addr),
    .l_rdata(icache_rdata),
    .l_resp(icache_resp),
    /* To/From Upper */
    .u_resp(icache_u_resp),
    .u_rdata(icache_u_rdata),
    .u_read(icache_u_read),
    .u_addr(icache_u_addr)
);

riscy_arbiter arbiter(
    .clk(clk),
    .icache_read(icache_u_read),
    .icache_u_addr(icache_u_addr),
    .dcache_read(dcache_u_read),
    .dcache_write(dcache_u_write),
    .dcache_u_addr(dcache_u_addr),
    .dcache_u_wdata(dcache_u_wdata256),
    .l2cache_rdata(l2cache_rdata),
    .l2cache_resp(l2cache_resp),
    
    .icache_resp(icache_u_resp),
    .icache_u_rdata(icache_u_rdata), 
    .dcache_resp(dcache_u_resp),
    .dcache_u_rdata(dcache_u_rdata256),
    .l2cache_read(l2cache_read),
    .l2cache_write(l2cache_write),
    .l2cache_wdata(l2cache_wdata),
    .l2cache_addr(l2cache_addr)
);

riscy_l2_cache l2_cache(
   .clk(clk),
    .mem_write(l2cache_write),
   .mem_read(l2cache_read),
   .mem_byte_enable(32'hFFFFFFFF),
   .mem_address(l2cache_addr),
   .mem_wdata(l2cache_wdata),
   .pmem_rdata(vcache_rdata),
   .pmem_resp(vcache_resp),
   
    .mem_rdata(l2cache_rdata),
   .mem_resp(l2cache_resp),
   .pmem_write(vcache_write),
   .pmem_read(vcache_read),
   .pmem_wdata(vcache_wdata),
   .pmem_address(vcache_addr),
   .vcache_is_dirty(vcache_is_dirty)
);

riscy_vcache vcache(
     .clk(clk),
    /* Between vcache and L2 */
    .l_read(vcache_read),
    .l_write(vcache_write),
    .l_addr(vcache_addr),
    .l_wdata(vcache_wdata),
    .l_is_dirty(vcache_is_dirty),
    .l_resp(vcache_resp),
    .l_rdata(vcache_rdata),
    /* Between vcache and pmem */
    .u_resp(pmem_resp),
    .u_rdata(pmem_rdata),
    .u_addr(pmem_address),
    .u_wdata(pmem_wdata),
    .u_read(pmem_read),
    .u_write(pmem_write)
);

endmodule : riscy_top

