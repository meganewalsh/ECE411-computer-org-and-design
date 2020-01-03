module memory
#(
    parameter real freq = 100.00 // Frequency in MHz
)
(
    input clk,
    input read,
    input write,
    input [31:0] address,
    input [255:0] wdata,
    output logic resp,
    output logic error,
    output logic [255:0] rdata
);

localparam int offset = 5;
localparam int base_cycles = 25;
 //only get fraction of 4GB addressable space due to modelsim limits
logic [255:0] mem [2**(22)];
logic [21:0] internal_address;
logic internal_read, internal_write;
logic [255:0] internal_wdata;
logic ready;
int duration;

enum {snone, sbusy} state;

default clocking test @(posedge clk); endclocking
default disable iff 1'b0;

/* Initialize memory contents from memory.lst file */
initial
begin
    string filename;
    real frequency;
    state = snone;
    if (!$value$plusargs("memory=%s", filename))
        filename = "memory.lst";
    if (!$value$plusargs("frequency=%d", frequency))
        frequency = 100.0;
    duration = base_cycles * frequency / 100.0;
    error = 1'b0;
    $readmemh(filename, mem);
    resp = 1'b0;
end

task memread(input logic [31:0] addr);
    static int lineno;
    lineno = addr >> offset;
    assert(state == snone) else begin
        $display("PMEM Read Error: Read from illegal state");
    end
    state <= sbusy;
    fork : f
        begin : error_check
            // This process simply runs some assertions at each 
            // new cycle, asserting error and ending the read if any assertion
            // fails
            forever @(test iff !resp) begin
                read_steady: assert(read) else begin
                    $display("PMEM Read Error: Read deasserted early\n");
                    error <= 1'b1;
                    disable f;
                    break;
                end
                no_write: assert(!write) else begin
                    $display("PMEM Read Error: Write asserted\n");
                    error <= 1'b1;
                    disable f;
                    break;
                end
                addr_read_steady: assert(address == addr) else begin
                    $display("PMEM Read Error: Address changed\n");
                    $display("Address %8x != addr %8x", address, addr);
                    error <= 1'b1;
                    disable f;
                    break;
                end
            end
        end
        begin : memreader
            ##(duration);
            rdata <= mem[lineno];
            resp <= 1'b1;
            ##1;
            resp <= 1'b0;
            disable f;
        end
    join
    ##1;
    state <= snone;
endtask : memread

task memwrite(input logic [31:0] addr, input logic [255:0] line);
    static int lineno;
    lineno = addr >> offset;
    assert(state == snone) else begin
        $display("PMEM Read Error: Read from illegal state");
    end
    state <= sbusy;
    fork : f
        begin : error_check
            // This process simply runs some assertions at each 
            // new cycle, asserting error and ending the read if any assertion
            // fails
            forever @(test iff !resp) begin
                write_steady: assert(write) else begin
                    $display("PMEM Write Error: Write deasserted early\n");
                    error <= 1'b1;
                    disable f;
                    break;
                end
                no_read: assert(!read) else begin
                    $display("PMEM Write Error: Read asserted\n");
                    error <= 1'b1;
                    disable f;
                    break;
                end
                addr_write_steady: assert(address == addr) else begin
                    $display("PMEM Write Error: Address changed\n");
                    $display("Address %8x != addr %8x", address, addr);
                    error <= 1'b1;
                    disable f;
                    break;
                end
            end
        end
        begin : memwrite
            ##(duration);
            mem[lineno] <= line;
            resp <= 1'b1;
            ##1;
            resp <= 1'b0;
            disable f;
        end
    join
    ##1;
    state <= snone;
endtask : memwrite

always @(test iff ((read || write) && (state == snone))) begin
    if (read)
        memread(address);
    else if (write)
        memwrite(address, wdata);
end

endmodule : memory

