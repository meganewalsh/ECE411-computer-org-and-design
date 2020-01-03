/* PLRU Array for 8-way Cache */
module riscy_plru_array_8 (
    input clk,
    input load,
    input [2:0] mru,
    output [2:0] out
);

logic [2:0] plru = '0;
logic [2:0] plru_in;

logic [6:0] tree = '0;
logic [6:0] tree_in;

assign out = plru;

always_comb begin
    plru_in = plru;
    tree_in = tree;

    // update logic
    if (load) begin
        // Tree Update Logic 
        unique case(mru)
            3'd0: begin
                tree_in[6] = 1'b0;
                tree_in[5] = 1'b0;
                tree_in[3] = 1'b0;
            end        
            3'd1: begin
                tree_in[6] = 1'b0;
                tree_in[5] = 1'b0;
                tree_in[3] = 1'b1;
            end        
            3'd2: begin
                tree_in[6] = 1'b0;
                tree_in[5] = 1'b0;
                tree_in[2] = 1'b0;
            end        
            3'd3: begin
                tree_in[6] = 1'b0;
                tree_in[5] = 1'b0;
                tree_in[2] = 1'b1;
            end        
            3'd4: begin
                tree_in[6] = 1'b1;
                tree_in[4] = 1'b0;
                tree_in[1] = 1'b0;
            end        
            3'd5: begin
                tree_in[6] = 1'b1;
                tree_in[4] = 1'b0;
                tree_in[1] = 1'b1;
            end        
            3'd6: begin
                tree_in[6] = 1'b1;
                tree_in[4] = 1'b1;
                tree_in[0] = 1'b0;
            end        
            3'd7: begin
                tree_in[6] = 1'b1;
                tree_in[4] = 1'b1;
                tree_in[0] = 1'b1;
            end        
            default: begin      // Default is 3'd0
                tree_in[6] = 1'b0;
                tree_in[5] = 1'b0;
                tree_in[3] = 1'b0;
            end
        endcase

        // PLRU update logic
        if (mru[2]) begin   // MRU is 4-7
            //PLRU is 0-3
            plru_in[2] = 1'b0;
            if (tree[5]) begin  // Prev MRU is 2-3
                //PLRU is 0-1
                plru_in[1] = 1'b0;
                plru_in[0] = ~tree[3];  //0-bit is not last MRU
            end else begin
                //PLRU is 2-3
                plru_in[1] = 1'b1;
                plru_in[0] = ~tree[2];  //0-bit is not last MRU
            end
        end else begin
            //PLRU is 4-7
            plru_in[2] = 1'b1;
            if (tree[4]) begin  // Prev MRU is 6-7
                //PLRU is 4-5
                plru_in[1] = 1'b0;
                plru_in[0] = ~tree[1];  //0-bit is not last MRU
            end else begin
                //PLRU is 6-7
                plru_in[1] = 1'b1;
                plru_in[0] = ~tree[0];  //0-bit is not last MRU
            end
        end 
    end
end

always_ff @(posedge clk) begin
    plru <= plru_in;
    tree <= tree_in;
end
endmodule : riscy_plru_array_8
