import piso_types::*;

module piso_converter(
    input logic clk_i,
    input logic reset_n_i,

    // Parallel Side protocol
    input  logic [31:0] p_i,			// parallel input
    input  logic valid_i,				// input is valid
    input  logic [1:0] byte_en_i,	// how many bytes of input are valid
    output logic rdy_o,					// ready for new input

    // Serial Logic
    output logic s_o,					// serial output
    output logic valid_o,				// ouput is valid
    output logic last_o,				// whether curr value on s_o is last value in serial vector
    input  logic ack_i,					/* assert when connected serial-side device gets the "last" bit of the
													serialized output, performs some checks (to be described later), and
													decides that it has received a valid sequence of bits. */
    input  logic nack_i					/* used when the device determines it has receieved an invalid sequence.
													If the PISO receieves a nack, or it receieves neither an ack nor a
													nack for a certain number of cycles, the PISO should resend the data on the SSP. */
);

logic [31:0] par_r;
logic [1:0] en_r;
static int ack_ctr;

/* Identifies whether SER is fully loaded */
logic shiftFlag;
/* Holds serialized, validated result */
static logic [35:0] SER;
static logic [35:0] origSER;
static int shifted;

//initial $monitor("	ctr %d", ack_ctr);

function logic [35:0] serialize(input logic [31:0] par);
    SER[7:0] = par[7:0];
    SER[8] = ^par[7:0];
    SER[16:9] = par[15:8];
    SER[17] = ^par[15:8];
    SER[25:18] = par[23:16];
    SER[26] = ^par[23:16];
    SER[34:27] = par[31:24];
    SER[35] = ^par[31:24];
endfunction


/* Reset */
function reset();
	par_r[31:0] <= 32'b0;
	en_r[1:0] <= 2'b0;
	SER <= 36'b0;
	shiftFlag <= 0;
	shifted <= 0;
	ack_ctr <= 0;
	
	/* Initialize some outputs */
	valid_o <= 1'b0;
	last_o <= 1'b0;
	rdy_o <= 1'b1;
endfunction


/* Parallel load and Serialize */
always_ff @(posedge valid_i) begin
	par_r[31:0] <= p_i[31:0];
	en_r[1:0] <= byte_en_i[1:0];
	serialize(p_i);
	origSER = SER;
	checkValidity();
	shiftFlag <= 1;
end


/* Uses byte_en_i to determine valid bytes of input */
function checkValidity();
	case (byte_en_i)
		2'b00:
			SER[8:0]  = SER[8:0];
      2'b01:
			SER[17:0] = SER[17:0];
      2'b10:
			SER[26:0] = SER[26:0];
      2'b11:
			SER[35:0] = SER[35:0];	
	endcase
endfunction


function checkDone();
	case (byte_en_i)
		2'b00: begin
			if (shifted == 9) begin
				last_o = 1'b1;
						valid_o <= 1'b0;
		shiftFlag <= 0;
			end
      end 2'b01: begin
			if (shifted == 18) begin
				last_o = 1'b1;
						valid_o <= 1'b0;
		shiftFlag <= 0;
			end
      end 2'b10: begin
			if (shifted == 27) begin
				last_o = 1'b1;
						valid_o <= 1'b0;
		shiftFlag <= 0;
			end
      end 2'b11: begin
			if (shifted == 36) begin
				last_o = 1'b1;
						valid_o <= 1'b0;
		shiftFlag <= 0;
			end
		end
	endcase

endfunction

/* General process */
always_ff @ (posedge clk_i) begin
	if (last_o)
		ack_ctr = ack_ctr + 1;
	
	if (~reset_n_i) begin
		reset();
	end
		
	if (ack_i)	begin
		reset();
	end else if (last_o && (nack_i || (ack_ctr > timeout_delay_p-1))) begin
		shiftFlag = 1'b1;
		last_o = 1'b0;
		ack_ctr = 0;
		shifted = 0;
		SER = origSER;
	end

	else if (shiftFlag) begin
		/* Transmit to s_o */
		s_o <= SER[0];
		valid_o <= 1'b1;
		SER <= (SER >> 1'b1);
		shifted <= shifted + 1;
	end
		
	checkDone();

end

endmodule : piso_converter
