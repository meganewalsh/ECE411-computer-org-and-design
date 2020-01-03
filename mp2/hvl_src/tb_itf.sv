/**
 * Interface used by testbenches to communicate with memory and
 * the DUT.
**/
interface tb_itf;

timeunit 1ns;
timeprecision 1ns;

bit clk;
bit mon_rst;
logic mem_resp;
logic pmem_resp;
logic mem_read;
logic pmem_read;
logic mem_write;
logic pmem_write;
logic [3:0] mem_byte_enable;
logic [15:0] errcode;
logic [31:0] mem_address;
logic [31:0] pmem_address;
logic [31:0] mem_rdata;
logic [31:0] mem_wdata;
logic [255:0] pmem_rdata;
logic [255:0] pmem_wdata;
logic halt;
logic [31:0] write_data;
logic [31:0] registers [32];
logic sm_error;
logic pm_error;

// The monitor has a reset signal, which it needs, but
// you use initial blocks in your DUT, so we generate two clocks
initial begin
    mon_rst = '1;
    clk = '0;
    #40;
    mon_rst = '0;
end

always #5 clk = ~clk; 

modport tb(
    input clk, mem_byte_enable, mem_address, mem_read, mem_write, mem_wdata,
    output mem_resp, mem_rdata
);

modport mem(
    input clk, pmem_read, pmem_write, pmem_address, pmem_wdata,
    output pmem_resp, pm_error, pmem_rdata
);

endinterface : tb_itf
