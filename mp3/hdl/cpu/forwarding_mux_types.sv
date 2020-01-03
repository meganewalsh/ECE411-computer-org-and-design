package rs1_types;
typedef enum bit [1:0] {
    EX_rs1_out			= 2'b00,
    MEM_rs1_out    	= 2'b01,
    WB_rd_out   	 	= 2'b10,
    regfile_rs1_out = 2'b11
} fwd_rs1mux_sel_t;
endpackage

package rs2_types;
typedef enum bit [1:0] {
    EX_rs2_out			= 2'b00,
    MEM_rs2_out    	= 2'b01,
    WB_rd_out    		= 2'b10,
    regfile_rs2_out 	= 2'b11
} fwd_rs2mux_sel_t;
endpackage
