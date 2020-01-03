mp2_same_cache:
.align 4
.section .text
.globl _start
_start:

    # Way 1
    nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	#Way 2
	nop
	nop
	nop
	nop
	nop
	nop
	nop

    # Halt by spinning
HALT:
    beq x0, x0, HALT

