`define LOG $error("%s", s); $fdisplay(fd, "%s", s); $fdisplay(lfd, "%s", s)
import piso_types::*;
module testbench;

piso_itf itf();

piso_converter dut (
    .clk_i     (itf.clk),
    .reset_n_i (itf.reset_n),
    
    .p_i       (itf.par),
    .valid_i   (itf.valid_i),
    .byte_en_i (itf.byte_en),
    .rdy_o     (itf.rdy),
    
    .s_o       (itf.serial),
    .valid_o   (itf.valid_o),
    .last_o    (itf.last),
    .ack_i     (itf.ack),
    .nack_i    (itf.nack)
);

/******************* Error Logging **********************/
int fd, lfd;
string s;
initial begin
    fd = $fopen("./student_log.txt", "w");
    lfd = $fopen("./log.txt", "w");
    if (fd == 0 || lfd == 0) begin
        $error("%s %0d: Unable to open log file(s)",
                    `__FILE__, `__LINE__);
        $exit;
    end
end

final begin
    $fclose(fd);
    $fclose(lfd);
end
/*******************************************************/

default clocking clk @(negedge itf.clk); endclocking

logic [35:0] sout;
int sout_ptr;

// Log serial output
initial forever begin
    @(clk);
    if (itf.valid_o) begin
        sout[sout_ptr] = itf.serial;
        sout_ptr++;
    end
    else begin
        sout_ptr = 0;
    end
end

task reset();
    itf.reset_n <= 1'b0;
    repeat (10) @(clk);
    itf.reset_n <= 1'b1;
    repeat (10) @(clk);
endtask

function logic [35:0] serialize(input logic [31:0] par);
    serialize[7:0] = par[7:0];
    serialize[8] = ^par[7:0];
    serialize[16:9] = par[15:8];
    serialize[17] = ^par[15:8];
    serialize[25:18] = par[23:16];
    serialize[26] = ^par[23:16];
    serialize[34:27] = par[31:24];
    serialize[35] = ^par[31:24];
endfunction

// Tests to see that the PISO converter is properly
// registering the input data from the parallel input
task test_parallel_load;
    logic [31:0] data;
    logic [1:0] en;
    reset();
    data = $urandom;
    en = $urandom;
    //$display("%0t TB: Testing Parallel Load: Data: %0d, En: %0d", $time, data, en[1:0]);
    itf.valid_i <= 1'b1;
    itf.par <= data;
    itf.byte_en <= en;
    @(clk);
    itf.valid_i <= 1'b0;
    assert (data == dut.par_r) else begin
        $sformat(s, "@%0t TB: dut.par_r == %0d, expected %0d",
                    $time, dut.par_r, data);
        `LOG;
    end
    assert (en[1:0] == dut.en_r);
    reset();
endtask

task serialize_word_test(logic [1:0] en);
    parameter string strs [4] = '{"Byte", "Half-Word", "Three Byte", "Word"};
    logic [31:0] data;
    logic [35:0] expected;

    reset();
    data = $urandom;
    expected = serialize(data);

    itf.valid_i <= 1'b1;
    fork ##1 itf.valid_i <= 1'b0; join_none

    itf.par <= data;
    itf.byte_en <= en;

    //$display("%0t TB: Testing Serialize %s with data = %b", $time,
    //        strs[en], data);
    @(clk iff itf.valid_o);
    for (int i = 0; i < 9 * (en+1); ++i) begin
        assert(itf.valid_o);
        @(clk);
    end

    unique case (en)
        2'b00: 
            assert (sout[8:0]  == expected[8:0]) else begin
                $sformat(s, "%0t TB: serial_out = %9b, expected %9b",
                            $time, sout[8:0], expected[8:0]);
                `LOG;
            end
        2'b01:
            assert (sout[17:0]  == expected[17:0]) else begin
                $sformat(s, "%0t TB: serial_out = %h, expected %h",
                        $time, sout[17:0], expected[17:0]);
                `LOG;
            end
        2'b10:
            assert (sout[26:0]  == expected[26:0]) else begin
                $sformat(s, "%0t TB: serial_out = %h, expected %h",
                        $time, sout[26:0], expected[26:0]);
                `LOG;
            end
        2'b11:
            assert (sout[35:0]  == expected[35:0]) else begin
                $sformat(s, "%0t TB: serial_out = %h, expected %h",
                            $time, sout, expected);
                `LOG;
            end
    endcase
    reset();
endtask

task test_ack(int delay);
    enum { TO_HANDLED, TO_NOTHANDLED, NO_TO } to;
    logic [31:0] data;
    logic [35:0] expected;
    logic [1:0] en;
    reset();
    data = $urandom;
    expected = serialize(data);
    en = '1;

    itf.valid_i <= 1'b1;
    itf.par <= data;
    fork
        ##1 itf.valid_i <= 1'b0;
        ##1 itf.par <= $urandom;
    join_none
    itf.byte_en <= en;

    $display("%0t: TB: ACK_TEST Send Parallel Delay: %0d", $time, delay);
    @(clk iff itf.last);
    $display("%0t: TB: ACK_TEST Last Serial Out", $time);

    fork : f
        begin
            // Send ACK
            repeat (delay) @(clk iff !itf.valid_o);
            itf.ack <= 1'b1;
            to = NO_TO;
            $display("%0t: Sent ACK", $time);
            disable f;
        end
        begin
            // Listen for retransmission
            @(clk iff itf.valid_o);
            to = TO_HANDLED;
            $display("%0t: Got Retransmission", $time);
            disable f;
        end
        begin
            @(clk);
            repeat (timeout_delay_p) @(clk iff !itf.valid_o);
            to = TO_NOTHANDLED;
            $display("%0t: No Retransmission", $time);
            disable f; end
    join
    @(clk);
    itf.ack <= 1'b0;
    case (to)
        NO_TO: assert (delay <= timeout_delay_p) else begin
            $sformat(s, "%0t TB: No Timeout Generated despite Delay of %0d",
                        $time, delay);
            `LOG;
        end
        TO_HANDLED: begin
            assert (delay > timeout_delay_p) else begin
                $sformat(s, "%0t TB: Timoute Generated on delay of %0d",
                            $time, delay);
                `LOG;
            end
            // Wait for retransmission to complete
            @(clk iff itf.last);
            @(clk);
            assert(expected == sout) else begin
                $sformat(s, "%0t TB: Retrnasmitted Incorrect Serialization",
                        $time);
                `LOG;
            end

            end
        TO_NOTHANDLED: begin
            assert (delay > timeout_delay_p)
                $sformat(s, "%0t TB: Delay of %0d did not generate a timeout", $time, delay);
            else $sformat(s, "%0t TB: Timoute Generated on delay of %0d", $time, delay);
            `LOG;
        end
        default: $display("%0t: TB: Unknown error at %s line %0d", 
                                $time, `__FILE__, `__LINE__);
    endcase
endtask : test_ack

task test_nack;
    logic [31:0] data;
    logic [35:0] expected;
    logic [1:0] en;

    data = $urandom;
    expected = serialize(data);
    en = '1;

    itf.valid_i <= 1'b1;
    itf.par <= data;
    fork
        ##1 itf.valid_i <= 1'b0;
        ##1 itf.par <= $urandom;
    join_none

    itf.byte_en <= en;

    @(clk iff itf.last);
    @(clk); @(clk);
    itf.nack <= 1'b1;
    fork ##1 itf.nack <= 1'b0; join_none

    fork : f
        begin
            @(clk iff itf.last);
            @(clk);
            @(clk);
            assert(expected == sout) else begin
                $sformat(s, "%0t TB: Retransmitted Incorrect Serialization on NACK Expected %h, received %h",
                    $time, expected, sout);
                `LOG;
            end
            itf.ack <= 1'b1;
            @(clk); @(clk);
            itf.ack <= 1'b0;
            @(clk); @(clk);

            disable f;
        end
        begin
            // Check timeout
            repeat (100) @(clk);
            $sformat(s, "%0t: TB: NACK Test Time Out", $time);
            `LOG;
            disable f;
        end
    join

endtask

// After running the testbench, the file `transcript' contains a copy of the
// output generated by modelsims
initial begin
    reset();

    $display("TB BEGIN: Parallel Loads Tests");
    repeat (100) test_parallel_load();
    $display("TB END: Parallel Loads Tests");

    $display("TB BEGIN: Serialize Byte Tests");
    repeat (100) serialize_word_test(2'b00);
    $display("TB END: Serialize Byte Tests");

    $display("TB BEGIN: Serialize Half-Word Tests");
    repeat (100) serialize_word_test(2'b01);
    $display("TB END: Serialize Half-Word Tests");

    $display("TB BEGIN: Serialize Three-Byte Tests");
    repeat (100) serialize_word_test(2'b01);
    $display("TB END: Serialize Three-Byte Tests");

    $display("TB BEGIN: Serialize Word Tests");
    repeat (100) serialize_word_test(2'b11);
    $display("TB END: Serialize Word Tests");

    $display("TB: Begin: ACK Test");
    for (int i = 0; i < 16; ++i)
        test_ack(i);
    $display("TB END: ACK Tests");
    reset();

    $display("TB: Begin: NACK Test");
    repeat (100) test_nack();
    $display("TB: End: NACK Test");

    repeat (200) @(clk);
    $finish;
end

initial begin : timeout
    repeat (500000) @(clk);
    $error("Timing Out");
    $finish;
end



endmodule : testbench


