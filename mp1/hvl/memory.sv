/*
 * memory
 */
module memory
(
    input clk,

    /* Port A */
    input read,
    input write,
    input logic [3:0] wmask,
    input logic [31:0] address,
    input logic [31:0] wdata,
    output logic resp,
    output logic [31:0] rdata
);

timeunit 1ns;
timeprecision 1ns;

parameter DELAY_MEM = 200;

logic [7:0] mem [2**(27)]; //only get fraction of 4GB addressable space due to modelsim limits
logic [26:0] internal_address;
logic [3:0] internal_wmask;
logic internal_read, internal_write;
logic [31:0] internal_wdata;
logic ready;

/* Initialize memory contents from memory.lst file */
initial
begin
    $readmemh("memory.lst", mem);
end

enum int unsigned {
    idle,
    busy,
    fail,
    respond
} state, next_state;

always @(posedge clk)
begin
    /* Default */
    resp = 1'b0;
    rdata = 32'bX;

    next_state = state;

    case(state)
        idle: begin
            if (read | write) begin
                internal_address = {address[26:2], 2'b0};
                internal_wmask = wmask;
                internal_read = read;
                internal_write = write;
                internal_wdata = wdata;
                next_state = busy;
                ready <= #DELAY_MEM 1;
            end
        end

        busy: begin
            if ((internal_address[26:2] != address[26:2]) || (internal_read != read) || (internal_write != write) || (internal_write && ((internal_wmask != wmask) || (internal_wdata != wdata)))) begin
                $display("Invalid input: Change in input value");
                next_state = fail;
            end

            else if (ready == 1) begin
                    if (write)
                    begin
                       if (wmask[3])
                           mem[internal_address+3] <= wdata[31:24];

                       if (wmask[2])
                           mem[internal_address+2] <= wdata[23:16];

                       if (wmask[1])
                           mem[internal_address+1] <= wdata[15:8];

                       if (wmask[0])
                           mem[internal_address] <= wdata[7:0];
                    end

                rdata = {mem[internal_address+3], mem[internal_address+2], mem[internal_address+1], mem[internal_address]};
                resp = 1;

                next_state = respond;
            end
        end

        fail: begin
            if (ready == 1) begin
                next_state = respond;
            end
        end

        respond: begin
            ready <= 0;
            next_state = idle;
        end

        default: next_state = idle;
    endcase
end

always_ff @(posedge clk)
begin : next_state_assignment
    state <= next_state;
end

endmodule : memory
