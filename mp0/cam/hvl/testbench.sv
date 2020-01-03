import cam_types::*;

module testbench(cam_itf itf);

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

//initial $monitor($time, "	value: %s", value, "		itf.key_i: %s", itf.key, "		itf.val_i: %s", itf.val_i, "	valid_o: %1b", itf.valid_o, "	val_o: %s", itf.val_o);
//initial $monitor($time, "	value: %s", value, "		itf.val_i: %s", itf.val_i, "		val_o: %s", itf.val_o);
val_t value;

task write(input key_t key, input val_t val);
	itf.key <= key;
	itf.val_i <= val;
	itf.rw_n <= 1'b0;
	itf.valid_i <= 1'b1;
	@(tb_clk);
	itf.valid_i <= 1'b0;
endtask

task read(input key_t key, output val_t val);
	itf.key <= key;
	itf.rw_n <= 1'b1;
	itf.valid_i <= 1'b1;
	@(tb_clk);
	itf.valid_i <= 1'b0;
	assert (itf.valid_o) else begin
		itf.tb_report_dut_error(READ_ERROR);
		$error("%0t TB: Read %0d, expected %0d", $time, itf.valid_o, "1");
	end
	val = itf.val_o;
		
endtask

task initializeCAM(input int iter);
	/* Fill all indices */
	for (int i = 1; i <= 8; ++i) begin
		if (i == iter)
			write(i, "x");
		else
			write(i, "o");
	end
	/* Read all indices but iter to prepare for LRU */
	for (int i = 1; i <= 8; ++i) begin
		if (i != iter) begin
			read(i, value);
		end
	end
	
endtask

task checkLRU(input int iter);
/* Should check that all values are "o" */
	for (int i = 1; i <= 9; ++i) begin
		if (i == iter)
			continue;
		read(i, value);
		// Error Reporting 1. Assert a read error when the value read from the CAM is incorrect
		assert (value == "o") else begin
			itf.tb_report_dut_error(READ_ERROR);
			$error("%0t TB: Read %0d, expected %0d", $time, value, "o");
		end
	end
endtask

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv
		 
	 // Coverage 1. The CAM must evict a key-value pair from each of its eight indices
	 // Coverage 2. The CAM must record a "read-hit" from each of its eight indices
	 for (int i = 1; i <= 8; ++i) begin
		reset();
		initializeCAM(i);
		write(9, "o");
		checkLRU(i);
	end
	 	 
	 // Coverage 3. You must perform writes to the same key on consecutive clock cycles
	 write(4, "a");
 	 write(4, "b");
	 read(4, value);
	 assert (value == "b") else begin
			itf.tb_report_dut_error(READ_ERROR);
			$error("%0t TB: Read %0d, expected %0d", $time, value, "b");
	 end
	 
	 // Coverage 4. You must perform a write then a read to the same key on consecutive clock cycles
	 write(4, "c");
 	 read(4, value);
	 assert (value == "c") else begin
			itf.tb_report_dut_error(READ_ERROR);
			$error("%0t TB: Read %0d, expected %0d", $time, value, "c");
	 end
	 
    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
