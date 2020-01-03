#  mp3-cp3.s version 1.0
.align 4
.section .text
.globl _start
_start:

load_lines:
    # DCache LRU Queue 7, 6, 5, 4, 3, 2, 1, 0
	lw  x1, ONE    # 0, 7, 6, 5, 4, 3, 2, 1
	lw  x2, TWO    # 1, 0, 7, 6, 5, 4, 3, 2
	lw  x3, THREE  # 2, 1, 0, 7, 6, 5, 4, 3
	lw  x4, FOUR   # 3, 2, 1, 0, 7, 6, 5, 4
	lw  x5, FIVE   # 4, 3, 2, 1, 0, 7, 6, 5
	lw  x6, SIX    # 5, 4, 3, 2, 1, 0, 7, 6
	lw  x7, SEVEN  # 6, 5, 4, 3, 2, 1, 0, 7
	lw  x8, EIGHT  # 7, 6, 5, 4, 3, 2, 1, 0
	lw  x9, ONE    # 0, 7, 6, 5, 4, 3, 2, 1
	lw  x10, NINE  # 1, 0, 7, 6, 5, 4, 3, 2
	lw  x10, FOUR  # 3, 1, 0, 7, 6, 5, 4, 2
	lw  x11, TEN   # 2, 3, 1, 0, 7, 6, 5, 4

halt:
	beq x0, x0, halt

.section .rodata
.balign 256
ONE:    .word 0x00000001
ONE_B:	.word 0xFFFFFFF1
ONE_C:	.word 0xFFFFFFF1
ONE_D:	.word 0xFFFFFFF1
ONE_E:	.word 0xFFFFFFF1
ONE_F:	.word 0xFFFFFFF1
ONE_G:	.word 0xFFFFFFF1
ONE_H:	.word 0xFFFFFFF1
# Cache Line Boundary
TWO:    .word 0x00000002
TWO_B:	.word 0xFFFFFFF2
TWO_C:	.word 0xFFFFFFF2
TWO_D:	.word 0xFFFFFFF2
TWO_E:	.word 0xFFFFFFF2
TWO_F:	.word 0xFFFFFFF2
TWO_G:	.word 0xFFFFFFF2
TWO_H:	.word 0xFFFFFFF2
# Cache Line Boundary
THREE:    .word 0x00000003
THREE_B:	.word 0xFFFFFFF3
THREE_C:	.word 0xFFFFFFF3
THREE_D:	.word 0xFFFFFFF3
THREE_E:	.word 0xFFFFFFF3
THREE_F:	.word 0xFFFFFFF3
THREE_G:	.word 0xFFFFFFF3
THREE_H:	.word 0xFFFFFFF3
# Cache Line Boundary
FOUR:    .word 0x00000004
FOUR_B:	.word 0xFFFFFFF4
FOUR_C:	.word 0xFFFFFFF4
FOUR_D:	.word 0xFFFFFFF4
FOUR_E:	.word 0xFFFFFFF4
FOUR_F:	.word 0xFFFFFFF4
FOUR_G:	.word 0xFFFFFFF4
FOUR_H:	.word 0xFFFFFFF4
# Cache Line Boundary
FIVE:    .word 0x00000005
FIVE_B:	.word 0xFFFFFFF5
FIVE_C:	.word 0xFFFFFFF5
FIVE_D:	.word 0xFFFFFFF5
FIVE_E:	.word 0xFFFFFFF5
FIVE_F:	.word 0xFFFFFFF5
FIVE_G:	.word 0xFFFFFFF5
FIVE_H:	.word 0xFFFFFFF5
# Cache Line Boundary
SIX:    .word 0x00000006
SIX_B:	.word 0xFFFFFFF6
SIX_C:	.word 0xFFFFFFF6
SIX_D:	.word 0xFFFFFFF6
SIX_E:	.word 0xFFFFFFF6
SIX_F:	.word 0xFFFFFFF6
SIX_G:	.word 0xFFFFFFF6
SIX_H:	.word 0xFFFFFFF6
# Cache Line Boundary
SEVEN:    .word 0x00000007
SEVEN_B:	.word 0xFFFFFFF7
SEVEN_C:	.word 0xFFFFFFF7
SEVEN_D:	.word 0xFFFFFFF7
SEVEN_E:	.word 0xFFFFFFF7
SEVEN_F:	.word 0xFFFFFFF7
SEVEN_G:	.word 0xFFFFFFF7
SEVEN_H:	.word 0xFFFFFFF7
# Cache Line Boundary
EIGHT:    .word 0x00000008
EIGHT_B:	.word 0xFFFFFFF8
EIGHT_C:	.word 0xFFFFFFF8
EIGHT_D:	.word 0xFFFFFFF8
EIGHT_E:	.word 0xFFFFFFF8
EIGHT_F:	.word 0xFFFFFFF8
EIGHT_G:	.word 0xFFFFFFF8
EIGHT_H:	.word 0xFFFFFFF8
# Cache Line Boundary
NINE:    .word 0x00000009
NINE_B:	.word 0xFFFFFFF9
NINE_C:	.word 0xFFFFFFF9
NINE_D:	.word 0xFFFFFFF9
NINE_E:	.word 0xFFFFFFF9
NINE_F:	.word 0xFFFFFFF9
NINE_G:	.word 0xFFFFFFF9
NINE_H:	.word 0xFFFFFFF9
# Cache Line Boundary
TEN:    .word 0x0000000a
TEN_B:	.word 0xFFFFFFFa
TEN_C:	.word 0xFFFFFFFa
TEN_D:	.word 0xFFFFFFFa
TEN_E:	.word 0xFFFFFFFa
TEN_F:	.word 0xFFFFFFFa
TEN_G:	.word 0xFFFFFFFa
TEN_H:	.word 0xFFFFFFFa
