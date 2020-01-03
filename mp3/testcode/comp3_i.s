	.file	"strides.c"
	.option nopic
	.text
	.align	4
	.globl	_start
	.hidden	_start
	.type	_start, @function
_start:
	li	sp,0x84000000
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	sw	s10,36(sp)
	addi	s0,sp,48
	li	a5,-553656320
	addi	s10,a5,-257
	sw	zero,-20(s0)
	j	.L7
.L10:
	sw	zero,-24(s0)
	j	.L8
.L9:
	call	xorwow
	mv	a5,a0
	andi	a3,a5,0xff
	lla	a2,array
	lw	a4,-20(s0)
	mv	a5,a4
	slli	a5,a5,1
	add	a5,a5,a4
	slli	a5,a5,2
	add	a4,a2,a5
	lw	a5,-24(s0)
	add	a5,a4,a5
	sb	a3,0(a5)
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L8:
	lw	a4,-24(s0)
	li	a5,32
	bne	a4,a5,.L9
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L7:
	lw	a4,-20(s0)
	li	a5,12
	bne	a4,a5,.L10
	sw	zero,-28(s0)
	j	.L11
.L12:
	lw	a4,-28(s0)
	mv	a5,a4
	slli	a5,a5,1
	add	a5,a5,a4
	slli	a5,a5,2
	lla	a4,array
	add	a5,a5,a4
	li	a1,32
	mv	a0,a5
	call	crc
	mv	a3,a0
	lla	a4,checksums
	lw	a5,-28(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	sw	a3,0(a5)
	lw	a5,-28(s0)
	addi	a5,a5,1
	sw	a5,-28(s0)
.L11:
	lw	a4,-28(s0)
	li	a5,12
	bne	a4,a5,.L12
	sw	zero,-32(s0)
	j	.L13
.L16:
	lw	a4,-32(s0)
	mv	a5,a4
	slli	a5,a5,1
	add	a5,a5,a4
	slli	a5,a5,2
	lla	a4,array
	add	a5,a5,a4
	li	a1,32
	mv	a0,a5
	call	crc
	sw	a0,-36(s0)
	lla	a4,checksums
	lw	a5,-32(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a5,0(a5)
	lw	a4,-36(s0)
	beq	a4,a5,.L14
	li	a5,-1163018240
	addi	s10,a5,-273
	j	.L15
.L14:
	lw	a5,-32(s0)
	addi	a5,a5,1
	sw	a5,-32(s0)
.L13:
	lw	a4,-32(s0)
	li	a5,12
	bne	a4,a5,.L16
	li	a5,1611489280
	addi	s10,a5,13
.L15:
.L17:
	j	.L17
	.size	_start, .-_start
	.align	4
	.globl	crc
	.hidden	crc
	.type	crc, @function
crc:
	addi	sp,sp,-48
	sw	s0,44(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	zero,-20(s0)
	sw	zero,-24(s0)
	j	.L2
.L3:
	lw	a4,-36(s0)
	lw	a5,-24(s0)
	add	a5,a4,a5
	lbu	a5,0(a5)
	andi	a5,a5,0xff
	mv	a4,a5
	lw	a5,-20(s0)
	add	a5,a5,a4
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L2:
	lw	a5,-40(s0)
	lw	a4,-24(s0)
	bltu	a4,a5,.L3
	nop
	mv	a0,a5
	lw	s0,44(sp)
	addi	sp,sp,48
	jr	ra
	.size	crc, .-crc
	.align	4
	.globl	xorwow
	.hidden	xorwow
	.type	xorwow, @function
xorwow:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	lla	a5,a.1386
	lw	a5,12(a5)
	sw	a5,-20(s0)
	lla	a5,a.1386
	lw	a5,0(a5)
	sw	a5,-24(s0)
	lla	a5,a.1386
	lw	a4,8(a5)
	lla	a5,a.1386
	sw	a4,12(a5)
	lla	a5,a.1386
	lw	a4,4(a5)
	lla	a5,a.1386
	sw	a4,8(a5)
	lla	a5,a.1386
	lw	a4,-24(s0)
	sw	a4,4(a5)
	lw	a5,-20(s0)
	srli	a5,a5,2
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	slli	a5,a5,1
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	slli	a4,a5,4
	lw	a5,-24(s0)
	xor	a5,a4,a5
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lla	a5,a.1386
	lw	a4,-20(s0)
	sw	a4,0(a5)
	lla	a5,counter.1387
	lw	a4,0(a5)
	li	a5,360448
	addi	a5,a5,1989
	add	a4,a4,a5
	lla	a5,counter.1387
	sw	a4,0(a5)
	lla	a5,counter.1387
	lw	a4,0(a5)
	lw	a5,-20(s0)
	add	a5,a4,a5
	mv	a0,a5
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	xorwow, .-xorwow
	.hidden	array
	.comm	array,12582912,4
	.hidden	checksums
	.comm	checksums,48,4
	.data
	.align	4
	.type	a.1386, @object
	.size	a.1386, 16
a.1386:
	.word	-1515870811
	.word	-1163018513
	.word	1343934162
	.word	-518918438
	.local	counter.1387
	.comm	counter.1387,4,4
	.ident	"GCC: (GNU) 7.2.0"
