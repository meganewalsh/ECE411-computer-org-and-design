#  mp3-cp1.s version 3.0
.align 4
.section .text
.globl _start
_start:
    lui x1, 1
    auipc x2, 2
    nop
    nop
    nop
    nop
    nop
    nop
    sll x4, x3, x3  # X4 = 2
    add x6, x5, x3  # ADD   X6 = 7
    or x11, x5, x0  # OR    X11 = 6
    addi x5, x5, 1   # ADDI again X5 = 7
    nop
    nop
    nop
    nop
    nop
    nop
    slli x4, x4, 3   #SLLI  X4 = 0x10 = 16
    and x1, x5, x5  #AND    X1 = 7
    andi x2, x0, 14  #ANDI  X2 = 0
    nop
    nop
    nop
    nop
    nop
    slt x1, x0, x1  #SLT    X1 = 1
    slti x1, x3, 0  #SLTI   X1 = 0
    sltu x1, x0, x11  #SLTU  X1 = 1
    sltiu x1, x0, 100  #SLTUI X1 = 1
    nop
    nop
    nop
    nop
    nop
    srai x1, x3, 2   # SRAI
    sra x1, x3, x3  # SRA
    srli x1, x3, 2   # SRLI
    srl x1, x3, x3  # SRL
    nop
    nop
    nop
    nop
    nop
    beq x0, x0, LOOP
    nop
    nop
    nop
    nop
    nop
    nop
    nop

.section .rodata
.balign 256
ONE:    .word 0x00000001
TWO:    .word 0x00000002
NEGTWO: .word 0xFFFFFFFE
TEMP1:  .word 0x00000001
GOOD:   .word 0x600D600D
BADD:   .word 0xBADDBADD

	
.section .text
.align 4
LOOP:
    add x3, x1, x2 # X3 <= X1 + X2
    and x5, x1, x4 # X5 <= X1 & X4
    not x6, x1     # X6 <= ~X1
    addi x9, x0, %lo(TEMP1) # X9 <= address of TEMP1
    nop
    nop
    nop
    nop
    nop
    nop
    sw x6, 0(x9)   # TEMP1 <= x6
    lw x7, %lo(TEMP1)(x0) # X7    <= TEMP1
    add x1, x1, x4 # X1    <= X1 + X4
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    blt x0, x1, DONEa
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    beq x0, x0, LOOP
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    lw x1, %lo(BADD)(x0)
HALT:	
    beq x0, x0, HALT
    nop
    nop
    nop
    nop
    nop
    nop
    nop
		
DONEa:
    lw x1, %lo(GOOD)(x0)
DONEb:	
    beq x0, x0, DONEb
    nop
    nop
    nop
    nop
    nop
    nop
    nop
	
