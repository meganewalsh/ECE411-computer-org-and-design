
interface piso_itf;
import piso_types::*;

bit clk, reset_n, valid_i, valid_o, rdy, ack, nack, serial, last;
bit [31:0] par;
bit [1:0] byte_en;

// Generate clk and clocking
initial begin
    clk = 1'b0;
    forever begin
        #5;
        clk = ~clk;
    end
end

endinterface : piso_itf
