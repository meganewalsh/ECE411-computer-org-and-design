import mult_types::*;

`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
//initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);
//initial $monitor($time, " done_o: %1b", dut.done_o, "		product_o: %8b", dut.product_o, "		reset__n_i: %1b", dut.reset_n_i, "		start_i: %1b", dut.start_i, "		ready_o: %1b", dut.ready_o );
//initial $monitor($time, "		reset__n_i: %1b", dut.reset_n_i, "		op: %s", dut.ms.op.name, "		start: %1b", dut.start_i);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error


initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
			/* Coverage 1. From a ready state, assert start_i with every possible combination of multiplicand and multiplier, and without
	       any resets until the multiplier enters a done state (resets while the device is in a done state are acceptable) */
			for (int x = 0; x <= 8'b11111111; ++x) begin
					for (int y = 0; y <= 8'b11111111; ++y) begin
					
						// Error Reporting 2. If the ready_o signal is not asserted after a reset
						assert (itf.rdy)
							else begin
								$error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
								report_error (NOT_READY);
							end
						
						@(tb_clk iff itf.rdy);
						itf.start = 1'b1;
						
						itf.multiplicand <= x;
						itf.multiplier <= y;
						
						@(tb_clk);
						itf.start = 1'b0;

						// Error Reporting 1. Upon entering the done state, the output signal product_o holds an incorrect product
						@(tb_clk iff itf.done);
						assert (itf.product == itf.multiplicand*itf.multiplier)
							else begin
								$error ("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
								report_error (BAD_PRODUCT);
							end
		 
						// Error Reporting 3. If the ready_o signal is not asserted upon completion of a multiplication */
						assert (itf.rdy == 1'b1)
							else begin
								$error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
								report_error (NOT_READY);
							end
						
						/* changed after checking in "done" state, rather than at start of multiplication */
						reset();
						
					end
			end
	 
	 		// Coverage 2. For each run state s, assert the start_i signal while the multiplier is in state s
			/* (START) Run state: SHIFT */			
			reset();
			@(tb_clk iff itf.rdy);
			itf.start = 1'b1;
			itf.multiplicand <= 10;
			itf.multiplier <= 10;		
			@(tb_clk);
			itf.start = 1'b0;
		
			@(tb_clk iff itf.mult_op == SHIFT)
			itf.start = 1'b1;
			@(tb_clk);
			itf.start = 1'b0;
			@(tb_clk iff itf.done);		// unsure how necessary this is

			/* (START) Run state: ADD*/
			reset();
			@(tb_clk iff itf.rdy);
			itf.start = 1'b1;
			itf.multiplicand <= 10;
			itf.multiplier <= 10;		
			@(tb_clk);
			itf.start = 1'b0;
			
			@(tb_clk iff itf.mult_op == ADD)
			itf.start = 1'b1;
			@(tb_clk);
			itf.start = 1'b0;
			@(tb_clk iff itf.done);		// unsure how necessary this is
			
			// Coverage 3. For each run state s, assert the active-low reset_n_i signal while the multiplier is in state s
			/* (RESET) Run state: SHIFT */			
			reset();
			@(tb_clk iff itf.rdy);
			itf.start = 1'b1;
			itf.multiplicand <= 10;
			itf.multiplier <= 10;		
			@(tb_clk);
			itf.start = 1'b0;
			
			@(tb_clk iff itf.mult_op == SHIFT)
			reset();

			/* (RESET) Run state: ADD */			
			@(tb_clk iff itf.rdy);
			itf.start = 1'b1;
			itf.multiplicand <= 8;
			itf.multiplier <= 8;		
			@(tb_clk);
			itf.start = 1'b0;

			@(tb_clk iff itf.mult_op == ADD)
			reset();
	 
    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
