
module zext
(
    input logic in,
    output logic [31:0] out 
);

assign out = {31'b0, in};

endmodule : zext
