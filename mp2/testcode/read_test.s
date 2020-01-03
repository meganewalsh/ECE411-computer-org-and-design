.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # Note that one/two/eight are data labels

    la x1, line1
    la x2, line2
    la x3, line3
	 la x4, line4
	 la x5, line5
    nop
    nop
	 lw x6,  0(x1)
	 
	 sw x1, -8(x6)
	 sw x2, -4(x6)
    sw x3,  0(x6)
    sw x4,  4(x6)
	 sw x5,  8(x6)
	 
inf:
    jal x0, inf

	
.section .rodata
.balign 256
.zero 96
line1:       .word 0x11111111
line5:	    .word 0x11111111
line12:      .word 0x00000000
line13:	    .word 0x00000000
line14:	    .word 0x00000000
line15:	    .word 0x00000000
line16:	    .word 0x00000000
line17:	    .word 0x00000000
line18:	    .word 0x00000000
line19:	    .word 0x00000000
line1a:	    .word 0x00000000
line1b:	    .word 0x00000000
line1c:	    .word 0x00000000
line1d:	    .word 0x00000000
line1e:	    .word 0x00000000
line1f:	    .word 0x00000000
.balign 256
.zero 96
line2:       .word 0x22222222
line4:	    .word 0x11111111
line22:	    .word 0x00000000
line23:	    .word 0x00000000
line24:	    .word 0x00000000
line25:	    .word 0x00000000
line26:	    .word 0x00000000
line27:	    .word 0x00000000
line28:	    .word 0x00000000
line29:	    .word 0x00000000
line2a:	    .word 0x00000000
line2b:	    .word 0x00000000
line2c:	    .word 0x00000000
line2d:	    .word 0x00000000
line2e:	    .word 0x00000000
line2f:	    .word 0x00000000
.balign 256
.zero 96
line3:	    .word 0x33333333
line31:	    .word 0x00000000
line32:	    .word 0x00000000
line33:	    .word 0x00000000
line34:	    .word 0x00000000
line35:	    .word 0x00000000
line36:	    .word 0x00000000
line37:	    .word 0x00000000
line38:	    .word 0x00000000
line39:	    .word 0x00000000
line3a:	    .word 0x00000000
line3b:	    .word 0x00000000
line3c:	    .word 0x00000000
line3d:	    .word 0x00000000
line3e:	    .word 0x00000000
line3f:	    .word 0x00000000
