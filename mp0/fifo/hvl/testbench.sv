`ifndef testbench
`define testbench

import fifo_types::*;

module testbench(fifo_itf itf);

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

//initial $monitor($time, "		check: %8b", check, "	itf.valid_i: %1b", itf.valid_i,   "		itf.rdy: %1b", itf.rdy, "		itf.data_i: %d", itf.data_i, "		itf.valid_o: %1b", itf.valid_o, " 	itf.yumi: %1b", itf.yumi, "		itf.data_o: %d", itf.data_o);
//initial $monitor($time, "	data_i: %d", itf.data_i, "	data_o: %d", itf.data_o, "		itf.rdy: %d", itf.rdy);

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE
static int check = 0;
static int i;
initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.

	 // Error Reporting 1. Asserting reset_n_i at @(tb_clk) should result in ready_o being high at @(posedge clk_i)
	 @(tb_clk iff itf.reset_n);
	 assert (itf.rdy)
		else begin
			$error ("%0d: %0t: %s error detected", `__LINE__, $time, RESET_DOES_NOT_CAUSE_READY_O);
			report_error (RESET_DOES_NOT_CAUSE_READY_O);
		end
		
	 // Coverage 3. You must simultaneously enqueue and dequeue while the FIFO has size in [1, cap_p-1] */
	 @(tb_clk iff itf.rdy);
	 for (i = 0; itf.rdy == 1'b1; i=i+2) begin
			// Coverage 1. You must enqueue words while the FIFO has size in [0, cap_p-1]
			@(tb_clk iff itf.rdy);
			itf.data_i <= i;
			itf.valid_i <= 1'b1;
			@(tb_clk);
			itf.valid_i <= 1'b0;

			// Error Reporting 2. When asserting yumi_i at @(tb_clk) when data is ready, the value on data_o is the CORRECT value. Recall that asserting yumi_i when the FIFO is empty results in undefined	behavior, so avoid doing this.
			@(tb_clk iff itf.valid_o);
			/* Having to break out for last cell */
			if (!itf.rdy) break;

			assert (itf.data_o == check)
			else begin
				$error ("%0d: %0t: %s error detected", `__LINE__, $time, INCORRECT_DATA_O_ON_YUMI_I);
				report_error (INCORRECT_DATA_O_ON_YUMI_I);
			end
			
			/* These must be SIMULTANEOUS (in same tb_clk cycle) */
			// Coverage 2. You must dequeue words while the FIFO has size in [1, cap_p]
			@(tb_clk);
			itf.yumi <= 1'b1;
			check <= check + 1;
			itf.data_i <= i+1;
			itf.valid_i <= 1'b1;
						
			@(tb_clk);
			itf.yumi <= 1'b0;
			itf.valid_i <= 1'b0;
			@(tb_clk);
	end	
	
	/* Edge case dequeue+enqueue */
	assert (itf.data_o == check)
	else begin
		$error ("%0d: %0t: %s error detected", `__LINE__, $time, INCORRECT_DATA_O_ON_YUMI_I);
		report_error (INCORRECT_DATA_O_ON_YUMI_I);
	end
			
	@(tb_clk);
	itf.yumi <= 1'b1;
	itf.data_i <= i+1;
	itf.valid_i <= 1'b1;

	@(tb_clk);
	itf.yumi <= 1'b0;
	itf.valid_i <= 1'b0;
	@(tb_clk);
			
	/* Dequeue all */
	for (int i = 0; i < cap_p; ++i) begin
//		$display("dequeue %d", itf.data_o);
		@(tb_clk);
		itf.yumi <= 1'b1;
		@(tb_clk);
		itf.yumi <= 1'b0;
	end
	 
    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

