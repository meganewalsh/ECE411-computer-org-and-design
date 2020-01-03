import rv32i_types::*;

module final_tb();

timeunit 100ps;
timeprecision 100ps;

bit clk;

logic pmem_resp;
logic [255:0] pmem_rdata;
logic pmem_read;
logic pmem_write;
logic [31:0] pmem_address;
logic [255:0] pmem_wdata;

riscy_top dut(.*);

memory mem(
    .clk(clk),
    .read(pmem_read),
    .write(pmem_write),
    .address(pmem_address),
    .wdata(pmem_wdata),
    .resp(pmem_resp),
    .error(),
    .rdata(pmem_rdata)
);

initial begin
    clk = '1;
end

always #70 clk = ~clk;   // 139

always @(posedge clk) begin
    if ((dut.cpu.EX.opcode == op_br || dut.cpu.EX.opcode == op_jal || dut.cpu.EX.opcode == op_jalr) & (dut.cpu.ID_EX.pc_out == dut.cpu.EX.pc_out)) begin // If half loop then end
		  if (dut.cpu.MEM.opcode == op_store || dut.cpu.MEM.opcode == op_load)
		      @(posedge clk iff dut.cpu.dcache_resp);
		  @(posedge clk);
		  @(posedge clk);				
		  $display("Halt Loop Reached");
        $finish;
    end
end

endmodule : final_tb
