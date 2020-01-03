/**
 * `magic_memory` loads a binary into memory, and uses this to drive
 * the DUT.
**/
module source_tb(
    tb_itf.tb itf,
    tb_itf.mem mem_itf
);

logic [31:0] write_data;
logic [31:0] write_address;
logic write;

always @(posedge itf.clk)
begin
    if (itf.mem_write & itf.mem_resp) begin
        write_address = itf.mem_address;
        write_data = itf.mem_wdata;
        write = 1;
    end else begin
        write_address = 32'hx;
        write_data = 32'hx;
        write = 0;
    end
end


endmodule : source_tb