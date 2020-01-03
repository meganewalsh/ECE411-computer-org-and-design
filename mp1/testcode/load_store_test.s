factorial.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Test LW
    lw x1, nonzero    # X1 <- 0xdeadb00b
    lw x2, result     # X2 <- 0x99999999
    
    # Test SW
    la x10, other     # Load other ptr to x10
    sw x1, 0(x10)     # Save X1 into buffer
    xor x1, x1, x1    # X1 <- 0
    lw x1, other      # X1 <- 0xdeadb00b (should be if stored correctly)
    
    # Test LB/LBU byte-aligned  
    la x11, lol
    lb x1, 0(x11)           # X1 <- 0xFFFFFFF4
    xor x1, x1, x1          # X1 <- 0
    lb x1, 1(x11)           # X1 <- 0xFFFFFFF3
    xor x1, x1, x1          # X1 <- 0
    lb x1, 2(x11)           # X1 <- 0xFFFFFFF2
    xor x1, x1, x1          # X1 <- 0
    lb x1, 3(x11)           # X1 <- 0xFFFFFFF1
    xor x1, x1, x1          # X1 <- 0
    lbu x1, 0(x11)          # X1 <- 0x000000F4
    xor x1, x1, x1          # X1 <- 0
    lbu x1, 1(x11)          # X1 <- 0x000000F3
    xor x1, x1, x1          # X1 <- 0
    lbu x1, 2(x11)          # X1 <- 0x000000F2
    xor x1, x1, x1          # X1 <- 0
    lbu x1, 3(x11)          # X1 <- 0x000000F1
	 
    # Test SB
    addi x1, x0, 15 # X1 <- 0x0F
    sb x1, 0(x11)
    lw x3, 0(x11)   # X3 should be 0x0F + other
    addi x1, x0, 14
    sb x1, 1(x11)
    lw x3, 0(x11)   # X3 should be  0x0F + 0x0E + other
    addi x1, x0, 13
    sb x1, 2(x11)
    lw x3, 0(x11)   # X3 should be  0x0F + 0x0E + 0x0D + other
    addi x1, x0, 12
    sb x1, 3(x11)
    lw x3, 0(x11)   # X3 should be  0x0F + 0x0E + 0x0D + 0x0C

    # Test SH
    addi x1, x0, 1  # X1 <- 1
    sh x1, 0(x11)
    lw x3, 0(x11)   # X3 <- 0xf1f20001
    addi x1, x0, 2
    sh x1, 2(x11)
    lw x3, 0(x11)   # X3 <- 0x00020001

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

.section .rodata

nonzero:      .word 0xdeadb99b
other:        .word 0x88888888
result:       .word 0x99999999
lol:          .word 0xf1f2f3f4
