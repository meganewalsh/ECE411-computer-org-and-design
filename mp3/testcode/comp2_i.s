.align 4
.section .text
.globl _start

_start:
	li	sp,0x84000000
	addi	sp,sp,-704
	sw	ra,700(sp)
	sw	s0,696(sp)
	sw	s1,692(sp)
	sw	s2,688(sp)
	sw	s3,684(sp)
	sw	s4,680(sp)
	sw	s5,676(sp)
	addi	a1,sp,256
	li	a2,0
	li	a0,13
.L8:
	mv	a5,a2
	addi	a3,a2,-8
	mv	a4,a1
.L9:
	sw	a5,0(a4)
	addi	a5,a5,-1
	addi	a4,a4,4
	bne	a5,a3,.L9
	addi	a2,a2,1
	addi	a1,a1,32
	bne	a2,a0,.L8
	addi	a4,sp,160
	li	a5,0
	li	a2,8
.L10:
	sw	a5,0(a4)
	addi	a3,a5,1
	sw	a3,4(a4)
	addi	a5,a5,2
	sw	a5,8(a4)
	mv	a5,a3
	addi	a4,a4,12
	bne	a3,a2,.L10
	addi	s3,sp,4
	addi	s2,sp,256
	addi	s5,sp,160
	j	.L13
.L23:
	addi	s3,s3,12
	addi	s2,s2,32
	beq	s3,s5,.L22
.L13:
	addi	s4,s3,12
	addi	s1,sp,160
	mv	s0,s3
.L12:
	addi	s0,s0,4
	li	a3,3
	li	a2,8
	mv	a1,s1
	mv	a0,s2
	call	foo
	sw	a0,-4(s0)
	addi	s1,s1,4
	bne	s4,s0,.L12
	j	.L23
.L22:
.L14:
	j	.L14

foo:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	sw	s1,20(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	s4,8(sp)
	sw	s5,4(sp)
	beqz	a2,.L4
	mv	s1,a0
	mv	s2,a1
	addi	s0,a2,-1
	slli	s4,a3,2
	li	s3,0
	li	s5,-1
.L3:
	addi	s1,s1,4
	lw	a1,0(s2)
	lw	a0,-4(s1)
	call	__mulsi3
	add	s3,s3,a0
	add	s2,s2,s4
	addi	s0,s0,-1
	bne	s0,s5,.L3
.L1:
	mv	a0,s3
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s1,20(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
	lw	s5,4(sp)
	addi	sp,sp,32
	jr	ra
.L4:
	mv	s3,a2
	j	.L1

__mulsi3:
	mv	a5,a0
	beqz	a0,.L28
	li	a0,0
	j	.L27
.L26:
	srli	a5,a5,1
	slli	a1,a1,1
	beqz	a5,.L30
.L27:
	andi	a4,a5,1
	beqz	a4,.L26
	add	a0,a0,a1
	j	.L26
.L30:
	ret
.L28:
	ret

