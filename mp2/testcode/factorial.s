factorial.s:
.align 4
.section .text
.globl _start

# MP1 CP1 requirement:
# Your program must be iterative. You must use load instructions to initialize registers.
# The factorial program should be flexible to calculate any other integer factorials like 4!, 6!, 7!, etc.
# by changing only one variable. It does not have to handle 0! or negative factorials (which are imaginary, anyway).
# Your code must end in an infinite loop. This will make simulation a lot easier.

_start:
	lw  x1, integer		# Factorial
	lw  x2, zero			# Accumulator/Result
	add x2, x2, 1
	lw  x3, zero
	
loop1:
	lw  x4, zero
	add x3, x3, x1
	
loop2:
	add x3, x3, -1
	add x4, x4, x2
	bne x0, x3, loop2
	
	add x1, x1, -1	
	lw  x2, zero
	add x2, x2, x4
	bne x0, x1, loop1
	
	# Store result
   la x10, result			# X10 <= Addr[result]
	sw x2, 0(x10)        # [Result] <= x2

halt:
	beq x0, x0, halt

.section .rodata

integer:	.word 0x00000100	# Variable that can be changed	
zero:	   .word 0x00000000
result:  .word 0x00000000
