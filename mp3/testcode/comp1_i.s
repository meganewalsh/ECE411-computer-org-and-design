	.file	"comp1.c"
	.option nopic
	.globl	__mulsi3
	.text
	.align	4
	.globl	_start
	.hidden	_start
	.type	_start, @function
_start:
	li	sp,0x84000000
	addi	sp,sp,-288
	sw	ra,284(sp)
	sw	s0,280(sp)
	addi	s0,sp,288
	addi	a5,s0,-280
	sw	a5,-24(s0)
	sw	zero,-20(s0)
	j	.L2
.L5:
	lw	a5,-20(s0)
	addi	a5,a5,1
	addi	a4,s0,-280
	slli	a5,a5,3
	add	a4,a4,a5
	lw	a5,-20(s0)
	slli	a5,a5,3
	addi	a3,s0,-16
	add	a5,a3,a5
	sw	a4,-260(a5)
	lw	a5,-20(s0)
	andi	a5,a5,1
	beqz	a5,.L3
	li	a5,-1
	j	.L4
.L3:
	li	a5,1
.L4:
	lw	a1,-20(s0)
	mv	a0,a5
	call	__mulsi3
	mv	a5,a0
	mv	a4,a5
	lw	a5,-20(s0)
	slli	a5,a5,3
	addi	a3,s0,-16
	add	a5,a3,a5
	sw	a4,-264(a5)
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L2:
	lw	a4,-20(s0)
	li	a5,30
	ble	a4,a5,.L5
	sw	zero,-28(s0)
	sw	zero,-32(s0)
	lw	a0,-24(s0)
	call	foo
.L6:
	j	.L6
	.size	_start, .-_start
	.align	4
	.globl	foo
	.hidden	foo
	.type	foo, @function
foo:
	addi	sp,sp,-48
	sw	s0,44(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	zero,-20(s0)
	sw	zero,-28(s0)
	j	.L8
.L12:
	li	a5,1
	sw	a5,-20(s0)
	lw	a5,-36(s0)
	sw	a5,-24(s0)
	j	.L9
.L11:
	lw	a5,-24(s0)
	lw	a4,0(a5)
	lw	a5,-24(s0)
	lw	a5,4(a5)
	lw	a5,0(a5)
	ble	a4,a5,.L10
	lw	a5,-24(s0)
	lw	a5,0(a5)
	sw	a5,-32(s0)
	lw	a5,-24(s0)
	lw	a5,4(a5)
	lw	a4,0(a5)
	lw	a5,-24(s0)
	sw	a4,0(a5)
	lw	a5,-24(s0)
	lw	a5,4(a5)
	lw	a4,-32(s0)
	sw	a4,0(a5)
	sw	zero,-20(s0)
.L10:
	lw	a5,-24(s0)
	lw	a5,4(a5)
	sw	a5,-24(s0)
.L9:
	lw	a5,-24(s0)
	lw	a5,4(a5)
	lw	a4,-28(s0)
	bne	a4,a5,.L11
	lw	a5,-24(s0)
	sw	a5,-28(s0)
.L8:
	lw	a5,-20(s0)
	beqz	a5,.L12
	nop
	lw	s0,44(sp)
	addi	sp,sp,48
	jr	ra
	.size	foo, .-foo
	.align	4
	.globl	__mulsi3
	.hidden	__mulsi3
	.type	__mulsi3, @function
__mulsi3:
	addi	sp,sp,-48
	sw	s0,44(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	zero,-20(s0)
	j	.L14
.L16:
	lw	a5,-36(s0)
	andi	a5,a5,1
	beqz	a5,.L15
	lw	a4,-20(s0)
	lw	a5,-40(s0)
	add	a5,a4,a5
	sw	a5,-20(s0)
.L15:
	lw	a5,-36(s0)
	srli	a5,a5,1
	sw	a5,-36(s0)
	lw	a5,-40(s0)
	slli	a5,a5,1
	sw	a5,-40(s0)
.L14:
	lw	a5,-36(s0)
	bnez	a5,.L16
	lw	a5,-20(s0)
	mv	a0,a5
	lw	s0,44(sp)
	addi	sp,sp,48
	jr	ra
	.size	__mulsi3, .-__mulsi3
	.ident	"GCC: (GNU) 7.2.0"
