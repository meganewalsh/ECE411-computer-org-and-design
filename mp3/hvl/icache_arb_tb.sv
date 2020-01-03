module icache_arb_tb();

timeunit 1ns;
timeprecision 1ns;

bit clk;

logic resp;
logic [31:0] rdata;
logic read;
logic [31:0] addr;

logic u_resp;
logic [255:0] u_rdata;
logic u_read;
logic [31:0] u_addr;

logic pmem_resp;
logic [255:0] pmem_rdata;
logic pmem_read;
logic [31:0] pmem_addr;

riscy_icache dut(
    .clk(clk),
    /* To/From Lower */
    .l_read(read),
    .l_addr(addr),
    .l_rdata(rdata),
    .l_resp(resp),
    /* To/From Upper */
    .u_resp(u_resp),
    .u_rdata(u_rdata),
    .u_read(u_read),
    .u_addr(u_addr)
);

riscy_arbiter arb(
    .clk(clk),
    .icache_resp(u_resp),
    .icache_read(u_read),
    .icache_u_addr(u_addr),
    .icache_u_rdata(u_rdata),

    .dcache_resp(),
    .dcache_read(),
    .dcache_write(),
    .dcache_u_addr(),
    .dcache_u_wdata(),
    .dcache_u_rdata(),

    .l2cache_read(pmem_read),
    .l2cache_write(),
    .l2cache_rdata(pmem_rdata),
    .l2cache_wdata(),
    .l2cache_addr(pmem_addr),
    .l2cache_resp(pmem_resp)
);

memory mem(
    .clk(clk),
    .read(pmem_read),
    .write(1'b0),
    .address(pmem_addr),
    .wdata(),
    .resp(pmem_resp),
    .error(),
    .rdata(pmem_rdata)
);

// TODO check if the data is actually correct
task read_word(logic [31:0] address, logic should_hit = 1'b0);
    @(posedge clk);
    if (should_hit) begin
        $display("\tReading from %0h : Hit EXPECTED", address);
    end else begin
        $display("\tReading from %0h : Hit NOT EXPECTED", address);
    end
    addr = address;
    read = 1'b1; 

    if (should_hit) begin
        // Should be 0-cycle response on hit
        @(clk); // Neg edge? TODO
        if (!resp) begin
            $display("\tERROR: No 0-cycle response on hit");
            @(posedge clk); @(posedge clk);
            $finish;
        end
    end else begin
        @(clk iff resp);    // Wait for response
        //TODO check what the value is here
    end

    if (resp) begin
        @(posedge clk)
        read = 1'b0;
    end
endtask

task read_word_test();
    int j;
    $display("Starting Read Word Test");

    for (int i = 0; i < 8; i++) begin   /* Test Proper load and read */
        read_word(({24'd0, i[2:0], 5'd0} | 32'h00000000), 1'b0);
        read_word(({24'd0, i[2:0], 5'd0} | 32'h00000000), 1'b1);
        if (i > 0) begin
            /* Check to see that the MRU before this was nto evicted */
            j = i - 1;
            read_word(({24'd0, j[2:0], 5'd0} | 32'h00000000), 1'b1);    
            /* Then reset MRU to i */
            read_word(({24'd0, i[2:0], 5'd0} | 32'h00000000), 1'b1);
        end
    end
    $display("ICache Fill/Init - PASS");

    //TODO any more tests
    //$display("Passed Eviction");

    $display("Finishing Read Word Test - PASS");
endtask

initial begin
    clk = '1;
    //TODO test icache
    read_word_test();  
    $finish();
end

always #5 clk = ~clk;
endmodule : icache_arb_tb
