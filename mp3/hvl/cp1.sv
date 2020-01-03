module cp1_tb();

timeunit 1ns;
timeprecision 1ns;

logic clk;

logic icache_resp;
logic [31:0] icache_rdata;
logic icache_read;
logic [31:0] icache_addr;

logic dcache_resp;
logic [31:0] dcache_rdata;
logic dcache_read;
logic dcache_write;
logic [3:0] dcache_wmask;
logic [31:0] dcache_addr;
logic [31:0] dcache_wdata;

riscy_cpu dut(.*);

magic_memory_dp magic_mem(
    .clk(clk),
    .read_a(icache_read),
    .address_a(icache_addr),
    .resp_a(icache_resp),
    .rdata_a(icache_rdata),
    .read_b(dcache_read),
    .write(dcache_write),
    .wmask(dcache_wmask),
    .address_b(dcache_addr),
    .wdata(dcache_wdata),
    .resp_b(dcache_resp),
    .rdata_b(dcache_rdata)
);

initial begin
    clk = '1;
end


always_ff @(posedge clk) begin
    if (dut.MEM_WB.ir_out == 32'h00000063) begin // If half loop then end
        $display("Halt Loop Reached");
        $finish;
    end
end 

always #5 clk = ~clk;

endmodule : cp1_tb
