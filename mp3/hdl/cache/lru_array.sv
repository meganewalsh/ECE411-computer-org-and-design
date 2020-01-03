/* LRU Array for 16-way Cache */
module riscy_lru_array_16 (
    input clk,
    input load,
    input [3:0] mru,
    output [3:0] out
);

parameter way_bits = 4;         // Bits needed to encode number of ways Don't change me
parameter ways = 2**way_bits;    // Number of ways to keep track of

logic [way_bits-1:0] queue [ways-1:0] = '{15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0};// Queue Shift Reg

logic [way_bits-1:0] queue_in [ways-1:0];   // Queue Shift Reg Input
logic [ways-1:0] shift;                     // Whether to take input from next in queue or keep same value

assign out = queue[0];

always_comb begin
    queue_in = queue;
    if (load) begin
        for (int i = ways-1; i > 0; i--) begin
            if (shift[i-1]) begin
                queue_in[i-1] = queue[i];
            end
        end
        queue_in[ways-1] = mru;            
    end 
end

always_comb begin : shift_logic
    shift = 'd0;
    if (queue[0] == mru) begin
        shift[0] = 1'b1;
    end 
    for (int i = 1; i < ways; i++) begin
        if ((queue[i] == mru) || shift[i-1]) begin
            shift[i] = 1'b1;
        end 
    end
end : shift_logic

always_ff @(posedge clk) begin
    queue <= queue_in;
end
endmodule : riscy_lru_array_16

/* LRU Array for 8-way Cache */
module riscy_lru_array_8 (
    input clk,
    input load,
    input [2:0] mru,
    output [2:0] out
);

parameter way_bits = 3;         // Bits needed to encode number of ways Don't change me
parameter ways = 2**way_bits;    // Number of ways to keep track of

logic [way_bits-1:0] queue [ways-1:0] = '{7, 6, 5, 4, 3, 2, 1, 0};// Queue Shift Reg

logic [way_bits-1:0] queue_in [ways-1:0];   // Queue Shift Reg Input
logic [ways-1:0] shift;                     // Whether to take input from next in queue or keep same value

assign out = queue[0];

always_comb begin
    queue_in = queue;
    if (load) begin
        for (int i = ways-1; i > 0; i--) begin
            if (shift[i-1]) begin
                queue_in[i-1] = queue[i];
            end
        end
        queue_in[ways-1] = mru;            
    end 
end

always_comb begin : shift_logic
    shift = 'd0;
    if (queue[0] == mru) begin
        shift[0] = 1'b1;
    end 
    for (int i = 1; i < ways; i++) begin
        if ((queue[i] == mru) || shift[i-1]) begin
            shift[i] = 1'b1;
        end 
    end
end : shift_logic

always_ff @(posedge clk) begin
    queue <= queue_in;
end
endmodule : riscy_lru_array_8

/* LRU Array for 4-way Cache */
module riscy_lru_array_4 (
    input clk,
    input load,
    input [1:0] mru,
    output [1:0] out
);

parameter way_bits = 2;         // Bits needed to encode number of ways Don't change me
parameter ways = 2**way_bits;    // Number of ways to keep track of

logic [way_bits-1:0] queue [ways-1:0] = '{3, 2, 1, 0};// Queue Shift Reg

logic [way_bits-1:0] queue_in [ways-1:0];   // Queue Shift Reg Input
logic [ways-1:0] shift;                     // Whether to take input from next in queue or keep same value

assign out = queue[0];

always_comb begin
    queue_in = queue;
    if (load) begin
        for (int i = ways-1; i > 0; i--) begin
            if (shift[i-1]) begin
                queue_in[i-1] = queue[i];
            end
        end
        queue_in[ways-1] = mru;            
    end 
end

always_comb begin : shift_logic
    shift = 'd0;
    if (queue[0] == mru) begin
        shift[0] = 1'b1;
    end 
    for (int i = 1; i < ways; i++) begin
        if ((queue[i] == mru) || shift[i-1]) begin
            shift[i] = 1'b1;
        end 
    end
end : shift_logic

always_ff @(posedge clk) begin
    queue <= queue_in;
end
endmodule : riscy_lru_array_4
