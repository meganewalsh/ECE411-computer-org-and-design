package datamux;
typedef enum bit {
    data_arr0_out  = 1'b0,
	 data_arr1_out  = 1'b1
} datamux_sel_t;
endpackage

package dinmux;
typedef enum bit {
    pmem_rdata	    = 1'b0,
	 mem_wdata256	 = 1'b1
} dinmux_sel_t;
endpackage

package mbe0mux;
typedef enum bit {
    zero	    	 	 = 1'b0,
	 mbe256  		 = 1'b1
} mbe0mux_sel_t;
endpackage

package mbe1mux;
typedef enum bit {
    zero    	    = 1'b0,
	 mbe256  		 = 1'b1
} mbe1mux_sel_t;
endpackage

package lrumux;
typedef enum bit [1:0] {
    both_invalid	 = 2'b00,
	 invalid0		 = 2'b01,
	 invalid1		 = 2'b10,
	 both_valid		 = 2'b11
} lrumux_sel_t;
endpackage
