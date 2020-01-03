import rv32i_types::*;
	
module cmp
(
    input rv32i_word a, b,
    input branch_funct3_t cmpop,
    output logic out
);

always_comb begin
    unique case (cmpop)
        beq:		out = (a == b);
        bne:		out = (a != b);
        blt:		out = ($signed(a) < $signed(b));
        bltu:		out = (a < b);
        bge:		out = ($signed(a) > $signed(b) || $signed(a) == $signed(b));
        bgeu:		out = (a > b || a == b);
		  default:	;
    endcase
end

endmodule : cmp
