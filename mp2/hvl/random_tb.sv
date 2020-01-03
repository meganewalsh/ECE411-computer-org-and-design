import rv32i_types::*;

module random_tb(
    tb_itf.tb itf,
    tb_itf.mem mem_itf
);

//input logic [3:0] mem_byte_enable;
//input logic [31:0] mem_address;
//input logic [31:0] mem_wdata;
//input logic mem_read;
//input logic mem_write;

initial begin

	 @(itf.clk & ~itf.mon_rst);
	 
	 itf.mem_address = 32'ha1111120;
	 itf.mem_write = 1;
	 repeat (5) @(itf.clk);
	 itf.mem_write = 0;
	 @(negedge itf.mem_resp);

	 itf.mem_address = 32'ha2222280;
	 itf.mem_write = 1;
	 repeat (5) @(itf.clk);
	 itf.mem_write = 0;
	 @(negedge itf.mem_resp);
	 
	 itf.mem_address = 32'ha33333c0;
	 itf.mem_write = 1;
	 repeat (5) @(itf.clk);
	 itf.mem_write = 0;
	 @(negedge itf.mem_resp);
	 
	 itf.mem_address = 32'ha4444400;
	 itf.mem_write = 1;
	 repeat (5) @(itf.clk);
	 itf.mem_write = 0;
	 @(negedge itf.mem_resp);

//	 @(itf.clk & ~itf.mon_rst);
//	 itf.mem_byte_enable = 4'b1111;
//	 itf.mem_address = 32'ha00000c0;
//	 itf.mem_wdata = 32'hdeadbeef;
//	 itf.mem_write = 1;
//	 @(posedge itf.clk)
//	 itf.mem_write = 0;
//	 @(negedge itf.mem_resp);
//	 
//	 itf.mem_byte_enable = 4'b1111;
//	 itf.mem_address = 32'hffffff20;
//	 itf.mem_wdata = 32'hd00db00f;
//	 itf.mem_write = 1;
//	 @(posedge itf.clk);
//	 itf.mem_write = 0;
//	 @(negedge itf.mem_resp);
//
//	 
//	 itf.mem_byte_enable = 4'b1111;
//	 itf.mem_address = 32'ha2222240;
//	 itf.mem_wdata = 32'h22222222;
//	 itf.mem_write = 1;
//	 @(posedge itf.clk);
//	 itf.mem_write = 0;
//	 @(negedge itf.mem_resp);
//
//	 
//	 itf.mem_byte_enable = 4'b1111;
//	 itf.mem_address = 32'ha1111120;
//	 itf.mem_wdata = 32'h11111111;
//	 itf.mem_write = 1;
//	 @(posedge itf.clk);
//	 itf.mem_write = 0; 
//	 @(negedge itf.mem_resp);
//
//	 
//	 itf.mem_address = 32'h2a3333360;
//	 itf.mem_wdata = 32'h22222222;
//	 itf.mem_write = 1;
//	 @(posedge itf.clk);
//	 itf.mem_write = 0;
//	 @(negedge itf.mem_resp);
//
//	 
//	 itf.mem_byte_enable = 4'b1111;
//	 itf.mem_address = 32'hffffff20;
//	 itf.mem_wdata = 32'hfadecabe;
//	 itf.mem_write = 1;
//	 @(posedge itf.clk);
//	 itf.mem_write = 0;
//	 @(negedge itf.mem_resp);
//
//	 
//	 itf.mem_byte_enable = 4'b1111;
//	 itf.mem_address = 32'hffffff20;
//	 itf.mem_wdata = 32'hfeedbe11;
//	 itf.mem_write = 1;
//	 @(posedge itf.clk);
//	 itf.mem_write = 0;
//	 @(negedge itf.mem_resp);
//
//	 
//	 itf.mem_byte_enable = 4'b1111;
//	 itf.mem_address = 32'hffffff20;
//	 itf.mem_wdata = 32'hbacabeed;
//	 itf.mem_write = 1;
//	 @(posedge itf.clk);
//	 itf.mem_write = 0;
//	 @(posedge itf.mem_resp);
//
//	 
//	 itf.mem_address = 32'ha0000020;
//	 itf.mem_read = 1;
//	 @(posedge itf.clk);
//	 itf.mem_read = 0;
//	 @(negedge itf.mem_resp);
//
//	 
//	 itf.mem_byte_enable = 4'b1111;
//	 itf.mem_address = 32'h2a4444480;
//	 itf.mem_wdata = 32'h44444444;
//	 itf.mem_write = 1;
//	 @(posedge itf.clk);
//	 itf.mem_write = 0;
//	 @(negedge itf.mem_resp);
	 
end

endmodule : random_tb


