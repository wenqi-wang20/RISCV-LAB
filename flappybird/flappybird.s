	.file	"flappybird.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	sw	s0,44(sp)
	sw	s1,40(sp)
	sw	s2,36(sp)
	sw	s3,32(sp)
	sw	s4,28(sp)
	sw	s5,24(sp)
	sw	s6,20(sp)
	sw	s7,16(sp)
	sw	s8,12(sp)
	sw	s9,8(sp)
	li	a4,-2080374784
	j	.L2
.L3:
	li	a5,87
	sb	a5,0(a4)
	addi	a4,a4,1
.L2:
	li	a5,-2080346112
	addi	a5,a5,1327
	bleu	a4,a5,.L3
	li	a5,-2046820352
	li	a4,1
	sw	a4,4(a5)
	li	a4,2
	sw	a4,0(a5)
	li	a4,0
.L4:
	li	a5,28672
	addi	a5,a5,1328
	beq	a4,a5,.L170
	li	a5,-2130706432
	add	a5,a5,a4
	li	a3,87
	sb	a3,0(a5)
	addi	a4,a4,1
	j	.L4
.L170:
	li	a2,0
	li	a3,0
	li	a0,0
.L6:
	li	a5,4096
	addi	a5,a5,1504
	beq	a2,a5,.L171
	li	a1,-2094006272
	add	a1,a1,a2
	slli	a5,a0,1
	add	a5,a5,a0
	slli	a4,a5,3
	add	a4,a4,a0
	slli	a5,a4,3
	add	a5,a3,a5
	li	a4,-2130706432
	addi	a4,a4,2030
	add	a5,a5,a4
	lbu	a4,0(a1)
	sb	a4,0(a5)
	addi	a2,a2,1
	addi	a3,a3,1
	li	a5,140
	bne	a3,a5,.L6
	addi	a0,a0,1
	li	a3,0
	j	.L6
.L171:
	li	a1,0
	li	a2,0
	li	a0,0
.L9:
	li	a5,4096
	addi	a5,a5,904
	beq	a1,a5,.L172
	li	a4,-2094002176
	addi	a4,a4,1504
	add	a4,a1,a4
	slli	a5,a0,1
	add	a5,a5,a0
	slli	a3,a5,3
	add	a3,a3,a0
	slli	a5,a3,3
	add	a5,a2,a5
	li	a3,-2130681856
	addi	a3,a3,424
	add	a5,a5,a3
	lbu	a4,0(a4)
	sb	a4,0(a5)
	addi	a1,a1,1
	addi	a2,a2,1
	li	a5,200
	bne	a2,a5,.L9
	addi	a0,a0,1
	li	a2,0
	j	.L9
.L172:
	li	a1,0
	li	a2,0
	li	a0,0
.L12:
	li	a5,900
	beq	a1,a5,.L15
	li	a4,-2093993984
	addi	a4,a4,-1688
	add	a4,a1,a4
	slli	a5,a0,1
	add	a5,a5,a0
	slli	a3,a5,3
	add	a3,a3,a0
	slli	a5,a3,3
	add	a5,a2,a5
	li	a3,-2130694144
	addi	a3,a3,-1206
	add	a5,a5,a3
	lbu	a4,0(a4)
	sb	a4,0(a5)
	addi	a1,a1,1
	addi	a2,a2,1
	li	a5,36
	bne	a2,a5,.L12
	addi	a0,a0,1
	li	a2,0
	j	.L12
.L15:
	li	a5,-2063597568
	lw	a0,4(a5)
	andi	a0,a0,1
	beq	a0,zero,.L15
	li	a5,-2046820352
	sw	zero,4(a5)
	li	a4,2
	sw	a4,0(a5)
	li	a4,0
	j	.L16
.L17:
	li	a5,-2080374784
	add	a5,a5,a4
	li	a3,87
	sb	a3,0(a5)
	addi	a4,a4,1
.L16:
	li	a5,28672
	addi	a5,a5,1328
	bne	a4,a5,.L17
	li	a2,0
	li	a3,0
	li	a6,0
.L18:
	li	a5,4096
	addi	a5,a5,1504
	beq	a2,a5,.L173
	li	a1,-2094006272
	add	a1,a1,a2
	slli	a5,a6,1
	add	a5,a5,a6
	slli	a4,a5,3
	add	a4,a4,a6
	slli	a5,a4,3
	add	a5,a3,a5
	li	a4,-2080374784
	addi	a4,a4,2030
	add	a5,a5,a4
	lbu	a4,0(a1)
	sb	a4,0(a5)
	addi	a2,a2,1
	addi	a3,a3,1
	li	a5,140
	bne	a3,a5,.L18
	addi	a6,a6,1
	li	a3,0
	j	.L18
.L173:
	li	a1,0
	li	a2,0
	li	a6,0
.L21:
	li	a5,4096
	addi	a5,a5,904
	beq	a1,a5,.L174
	li	a4,-2094002176
	addi	a4,a4,1504
	add	a4,a1,a4
	slli	a5,a6,1
	add	a5,a5,a6
	slli	a3,a5,3
	add	a3,a3,a6
	slli	a5,a3,3
	add	a5,a2,a5
	li	a3,-2080350208
	addi	a3,a3,424
	add	a5,a5,a3
	lbu	a4,0(a4)
	sb	a4,0(a5)
	addi	a1,a1,1
	addi	a2,a2,1
	li	a5,200
	bne	a2,a5,.L21
	addi	a6,a6,1
	li	a2,0
	j	.L21
.L174:
	li	a1,0
	li	a2,0
	li	a6,0
.L24:
	li	a5,900
	beq	a1,a5,.L175
	li	a4,-2093993984
	addi	a4,a4,-788
	add	a4,a1,a4
	slli	a5,a6,1
	add	a5,a5,a6
	slli	a3,a5,3
	add	a3,a3,a6
	slli	a5,a3,3
	add	a5,a2,a5
	li	a3,-2080362496
	addi	a3,a3,-606
	add	a5,a5,a3
	lbu	a4,0(a4)
	sb	a4,0(a5)
	addi	a1,a1,1
	addi	a2,a2,1
	li	a5,36
	bne	a2,a5,.L24
	addi	a6,a6,1
	li	a2,0
	j	.L24
.L175:
	li	a4,0
.L27:
	li	a5,49152
	addi	a5,a5,848
	beq	a4,a5,.L176
	addi	a4,a4,1
	j	.L27
.L176:
	li	a5,-2046820352
	sw	zero,4(a5)
	mv	a7,a0
	li	a1,0
	li	a6,0
	li	t4,0
	li	t3,0
	li	t5,0
	li	a3,0
	j	.L59
.L195:
	li	t0,-2130698240
	addi	t0,t0,1890
	j	.L29
.L196:
	li	a5,1
	beq	t3,a5,.L177
.L33:
	srai	a5,a7,31
	srli	a4,a5,30
	add	a5,a7,a4
	andi	a5,a5,3
	sub	a5,a5,a4
	li	a4,1
	beq	a5,a4,.L44
	li	a4,3
	beq	a5,a4,.L44
	li	a4,2
	beq	a5,a4,.L178
	li	a5,1
	beq	a3,a5,.L179
	li	t2,-2080362496
	addi	t2,t2,-606
.L51:
	li	a5,1
	beq	a3,a5,.L180
	li	t1,58
	li	a1,12288
	addi	a1,a1,-606
	li	s0,-2093993984
	addi	s0,s0,-788
	j	.L48
.L177:
	li	a5,3
	ble	t4,a5,.L34
	li	a5,1
	beq	a3,a5,.L35
	li	t0,-2080374784
	addi	t0,t0,2030
.L36:
	li	t2,0
	li	t1,0
	li	t6,0
.L42:
	srai	a5,t4,31
	srli	a4,a5,30
	add	a5,t4,a4
	andi	a5,a5,3
	sub	a5,a5,a4
	addi	a5,a5,1
	slli	a4,a5,1
	add	a4,a4,a5
	slli	a2,a4,2
	sub	a2,a2,a5
	slli	a4,a2,4
	sub	a5,a4,a5
	slli	a4,a5,3
	beq	a4,t2,.L181
	slli	a5,t6,1
	add	a5,a5,t6
	slli	a4,a5,3
	add	a4,a4,t6
	slli	a5,a4,3
	add	a5,t1,a5
	add	a5,t0,a5
	li	a4,87
	sb	a4,0(a5)
	addi	t2,t2,1
	addi	t1,t1,1
	li	a5,140
	bne	t1,a5,.L42
	addi	t6,t6,1
	li	t1,0
	j	.L42
.L34:
	andi	a5,t4,3
	bne	a5,zero,.L37
	li	a5,1
	beq	a3,a5,.L182
	li	t0,-2080366592
	addi	t0,t0,-162
	j	.L36
.L182:
	li	t0,-2130698240
	addi	t0,t0,-162
	j	.L36
.L37:
	li	a5,-2147483648
	addi	a5,a5,3
	and	a5,t4,a5
	blt	a5,zero,.L183
.L38:
	li	a4,1
	beq	a5,a4,.L184
	li	a4,2
	beq	a5,a4,.L185
	li	a5,1
	beq	a3,a5,.L186
	li	t0,-2080374784
	addi	t0,t0,2030
	j	.L36
.L183:
	addi	a5,a5,-1
	ori	a5,a5,-4
	addi	a5,a5,1
	j	.L38
.L184:
	li	a5,1
	beq	a3,a5,.L187
	li	t0,-2080370688
	addi	t0,t0,1934
	j	.L36
.L187:
	li	t0,-2130702336
	addi	t0,t0,1934
	j	.L36
.L185:
	li	a5,1
	beq	a3,a5,.L188
	li	t0,-2080370688
	addi	t0,t0,-66
	j	.L36
.L188:
	li	t0,-2130702336
	addi	t0,t0,-66
	j	.L36
.L186:
	li	t0,-2130706432
	addi	t0,t0,2030
	j	.L36
.L35:
	li	t0,-2130706432
	addi	t0,t0,2030
	j	.L36
.L181:
	addi	t4,t4,1
	j	.L33
.L44:
	li	a5,1
	beq	a3,a5,.L189
	li	t2,-2080362496
	addi	t2,t2,-1206
.L46:
	li	a5,1
	beq	a3,a5,.L47
	li	t1,55
	li	a1,12288
	addi	a1,a1,-1206
	li	s0,-2093993984
	addi	s0,s0,-1688
.L48:
	li	a2,0
	li	a3,0
	li	t6,0
.L53:
	li	a5,900
	beq	a2,a5,.L190
	add	t0,s0,a2
	slli	a5,t6,1
	add	a5,a5,t6
	slli	a4,a5,3
	add	a4,a4,t6
	slli	a5,a4,3
	add	a5,a3,a5
	add	a5,t2,a5
	lbu	a4,0(t0)
	sb	a4,0(a5)
	addi	a2,a2,1
	addi	a3,a3,1
	li	a5,36
	bne	a3,a5,.L53
	addi	t6,t6,1
	li	a3,0
	j	.L53
.L189:
	li	t2,-2130694144
	addi	t2,t2,-1206
	j	.L46
.L178:
	li	a5,1
	beq	a3,a5,.L191
	li	t2,-2080362496
	addi	t2,t2,-1806
.L50:
	li	a5,1
	beq	a3,a5,.L192
	li	t1,52
	li	a1,12288
	addi	a1,a1,-1806
	li	s0,-2093993984
	addi	s0,s0,112
	j	.L48
.L191:
	li	t2,-2130694144
	addi	t2,t2,-1806
	j	.L50
.L192:
	li	t1,52
	li	a6,12288
	addi	a6,a6,-1806
	li	s0,-2093993984
	addi	s0,s0,112
	j	.L48
.L179:
	li	t2,-2130694144
	addi	t2,t2,-606
	j	.L51
.L180:
	li	t1,58
	li	a6,12288
	addi	a6,a6,-606
	li	s0,-2093993984
	addi	s0,s0,-788
	j	.L48
.L47:
	li	t1,55
	li	a6,12288
	addi	a6,a6,-1206
	li	s0,-2093993984
	addi	s0,s0,-1688
	j	.L48
.L190:
	addi	a7,a7,1
	srli	a3,a7,31
	add	a5,a7,a3
	andi	a5,a5,1
	sub	a5,a5,a3
	li	a3,1
	sub	a3,a3,a5
	li	a5,-2046820352
	sw	a3,4(a5)
	li	a4,0
.L55:
	li	a5,40960
	addi	a5,a5,-960
	beq	a4,a5,.L193
	addi	a4,a4,1
	j	.L55
.L193:
	li	a5,-2063597568
	lw	a5,4(a5)
	andi	a5,a5,1
	beq	a5,zero,.L57
	bne	t5,zero,.L57
	addi	t3,t3,1
	mv	t5,a5
.L58:
	li	a5,2
	beq	t3,a5,.L194
.L59:
	li	a5,1
	beq	a3,a5,.L195
	li	t0,-2080366592
	addi	t0,t0,1890
.L29:
	li	t6,0
	li	a2,0
	li	t1,0
.L30:
	li	a5,1260
	beq	t6,a5,.L196
	slli	a5,t1,1
	add	a5,a5,t1
	slli	a4,a5,3
	add	a4,a4,t1
	slli	a5,a4,3
	add	a5,a2,a5
	add	a5,t0,a5
	li	a4,87
	sb	a4,0(a5)
	addi	t6,t6,1
	addi	a2,a2,1
	li	a5,36
	bne	a2,a5,.L30
	addi	t1,t1,1
	li	a2,0
	j	.L30
.L57:
	bne	a5,zero,.L58
	beq	t5,zero,.L58
	mv	t5,a5
	j	.L58
.L194:
	li	t6,0
	li	t2,0
	li	t4,200
	li	a7,0
	li	t5,20480
	addi	t5,t5,-1280
	mv	s0,t5
	li	t0,400
	li	s1,400
	li	a2,0
	li	s2,0
	j	.L134
.L146:
	mv	t2,a5
	mv	s2,a5
.L61:
	li	a5,1
	beq	a3,a5,.L197
	li	a4,-2080374784
.L62:
	li	a5,1
	beq	a3,a5,.L198
	mv	s7,a1
.L64:
	li	s6,0
	li	s4,0
	li	s5,0
.L65:
	li	a5,900
	beq	s6,a5,.L199
	slli	a5,s5,1
	add	a5,a5,s5
	slli	s3,a5,3
	add	s3,s3,s5
	slli	a5,s3,3
	add	a5,s4,a5
	add	a5,a5,s7
	add	a5,a4,a5
	li	s3,87
	sb	s3,0(a5)
	addi	s6,s6,1
	addi	s4,s4,1
	li	a5,36
	bne	s4,a5,.L65
	addi	s5,s5,1
	li	s4,0
	j	.L65
.L197:
	li	a4,-2130706432
	j	.L62
.L198:
	mv	s7,a6
	j	.L64
.L199:
	ble	t2,zero,.L68
	addi	t2,t2,-1
	li	a5,1
	beq	a3,a5,.L200
	li	s8,-4096
	addi	s8,s8,496
	add	s8,a6,s8
.L70:
	add	s8,a4,s8
	addi	t1,t1,-18
	li	a5,1
	beq	a3,a5,.L201
	li	a1,-4096
	addi	a1,a1,496
	add	a1,a6,a1
.L72:
	srai	a5,a2,31
	srli	s3,a5,30
	add	a5,a2,s3
	andi	a5,a5,3
	sub	a5,a5,s3
	li	s3,1
	beq	a5,s3,.L149
	li	s3,3
	beq	a5,s3,.L150
	li	s3,2
	beq	a5,s3,.L202
	li	s9,-2093993984
	addi	s9,s9,-788
	j	.L76
.L200:
	li	s8,-4096
	addi	s8,s8,496
	add	s8,a1,s8
	j	.L70
.L201:
	li	a6,-4096
	addi	a6,a6,496
	add	a6,a1,a6
	j	.L72
.L68:
	li	a5,1
	beq	a3,a5,.L203
	addi	s8,a6,600
.L74:
	add	s8,a4,s8
	addi	t1,t1,3
	li	a5,1
	beq	a3,a5,.L204
	addi	a1,a6,600
	j	.L72
.L203:
	addi	s8,a1,600
	j	.L74
.L204:
	addi	a6,a1,600
	j	.L72
.L202:
	li	s9,-2093993984
	addi	s9,s9,112
	j	.L76
.L149:
	li	s9,-2093993984
	addi	s9,s9,-1688
.L76:
	li	a5,1
	beq	a3,a5,.L205
.L77:
	li	a5,1
	beq	a3,a5,.L206
.L79:
	bne	a3,zero,.L80
	li	a5,20480
	addi	a5,a5,-398
	bgt	a1,a5,.L154
.L80:
	bne	a3,zero,.L78
	li	a5,681
	bgt	a6,a5,.L78
	mv	t6,a0
	li	a1,682
	li	s8,-2080374784
	addi	s8,s8,682
	j	.L78
.L150:
	li	s9,-2093993984
	addi	s9,s9,-1688
	j	.L76
.L205:
	li	a5,20480
	addi	a5,a5,-398
	ble	a6,a5,.L77
	mv	t6,a3
	li	a6,20480
	addi	a6,a6,-398
	li	s8,-2130685952
	addi	s8,s8,-398
	j	.L78
.L206:
	li	a5,681
	bgt	a6,a5,.L79
	mv	t6,a3
	li	a6,682
	li	s8,-2130706432
	addi	s8,s8,682
	j	.L78
.L154:
	mv	t6,a0
	li	a1,20480
	addi	a1,a1,-398
	li	s8,-2080354304
	addi	s8,s8,-398
.L78:
	li	s5,0
	li	s4,0
	li	s6,0
.L82:
	li	a5,900
	beq	s5,a5,.L207
	add	s7,s9,s5
	slli	a5,s6,1
	add	a5,a5,s6
	slli	s3,a5,3
	add	s3,s3,s6
	slli	a5,s3,3
	add	a5,s4,a5
	add	a5,s8,a5
	lbu	s3,0(s7)
	sb	s3,0(a5)
	addi	s5,s5,1
	addi	s4,s4,1
	li	a5,36
	bne	s4,a5,.L82
	addi	s6,s6,1
	li	s4,0
	j	.L82
.L207:
	li	a5,1
	beq	a3,a5,.L208
	mv	s7,t0
.L85:
	li	s6,0
	li	s4,0
	li	s5,0
.L86:
	li	a5,1950
	beq	s6,a5,.L209
	slli	a5,s5,1
	add	a5,a5,s5
	slli	s3,a5,3
	add	s3,s3,s5
	slli	a5,s3,3
	add	a5,s4,a5
	add	a5,a5,s7
	add	a5,a4,a5
	li	s3,87
	sb	s3,0(a5)
	addi	s6,s6,1
	addi	s4,s4,1
	li	a5,50
	bne	s4,a5,.L86
	addi	s5,s5,1
	li	s4,0
	j	.L86
.L208:
	mv	s7,s1
	j	.L85
.L209:
	li	a5,1
	beq	a3,a5,.L210
	mv	s7,t5
.L90:
	li	s6,0
	li	s4,0
	li	s5,0
.L91:
	li	a5,1550
	beq	s6,a5,.L211
	slli	a5,s5,1
	add	a5,a5,s5
	slli	s3,a5,3
	add	s3,s3,s5
	slli	a5,s3,3
	add	a5,s4,a5
	add	a5,a5,s7
	add	a5,a4,a5
	li	s3,87
	sb	s3,0(a5)
	addi	s6,s6,1
	addi	s4,s4,1
	li	a5,50
	bne	s4,a5,.L91
	addi	s5,s5,1
	li	s4,0
	j	.L91
.L210:
	mv	s7,s0
	j	.L90
.L211:
	bne	a7,zero,.L94
	li	a5,1
	beq	a3,a5,.L212
	addi	s8,s1,-5
.L96:
	add	s8,a4,s8
	li	a5,1
	beq	a3,a5,.L213
	addi	t0,s1,-5
.L98:
	addi	t4,t4,-5
	li	a5,1
	beq	a3,a5,.L214
.L99:
	bne	a3,zero,.L100
	li	a5,160
	bgt	t0,a5,.L100
	mv	a7,t3
	j	.L100
.L212:
	addi	s8,t0,-5
	j	.L96
.L213:
	addi	s1,t0,-5
	j	.L98
.L214:
	li	a5,160
	bgt	s1,a5,.L99
	mv	a7,t3
	j	.L100
.L94:
	addi	s8,a4,395
	li	a5,1
	beq	a3,a5,.L215
	li	t0,395
.L101:
	addi	a7,a7,-1
	li	t4,195
.L100:
	li	s6,0
	li	s5,0
	li	s7,0
.L102:
	li	a5,1950
	beq	s6,a5,.L216
	li	s3,-2093985792
	addi	s3,s3,870
	add	s3,s6,s3
	slli	a5,s7,1
	add	a5,a5,s7
	slli	s4,a5,3
	add	s4,s4,s7
	slli	a5,s4,3
	add	a5,s5,a5
	add	a5,s8,a5
	lbu	s3,0(s3)
	sb	s3,0(a5)
	addi	s6,s6,1
	addi	s5,s5,1
	li	a5,50
	bne	s5,a5,.L102
	addi	s7,s7,1
	li	s5,0
	j	.L102
.L215:
	li	s1,395
	j	.L101
.L216:
	li	a5,1
	beq	a3,a5,.L217
	mv	a5,t0
.L105:
	li	s3,200
	ble	a5,s3,.L160
	addi	a5,a5,-345
	li	s3,55
	bgtu	a5,s3,.L161
	mv	s9,a0
	j	.L106
.L217:
	mv	a5,s1
	j	.L105
.L160:
	li	s9,-1
.L106:
	beq	a7,zero,.L107
	li	a5,2
	beq	a7,a5,.L107
	li	s8,20480
	addi	s8,s8,-1285
	add	s8,a4,s8
	li	a5,1
	beq	a3,a5,.L218
	li	t5,20480
	addi	t5,t5,-1285
.L113:
	addi	a7,a7,-1
	j	.L112
.L161:
	li	s9,0
	j	.L106
.L107:
	li	a5,1
	beq	a3,a5,.L219
	addi	s8,s0,-5
.L110:
	add	s8,a4,s8
	li	a5,1
	beq	a3,a5,.L220
	addi	t5,s0,-5
.L112:
	li	s6,0
	li	s5,0
	li	s7,0
.L114:
	li	a5,1500
	beq	s6,a5,.L221
	li	s3,-2093993984
	addi	s3,s3,1012
	add	s3,s6,s3
	slli	a5,s7,1
	add	a5,a5,s7
	slli	s4,a5,3
	add	s4,s4,s7
	slli	a5,s4,3
	add	a5,s5,a5
	add	a5,s8,a5
	lbu	s3,0(s3)
	sb	s3,0(a5)
	addi	s6,s6,1
	addi	s5,s5,1
	li	a5,50
	bne	s5,a5,.L114
	addi	s7,s7,1
	li	s5,0
	j	.L114
.L219:
	addi	s8,t5,-5
	j	.L110
.L220:
	addi	s0,t5,-5
	j	.L112
.L218:
	li	s0,20480
	addi	s0,s0,-1285
	j	.L113
.L221:
	li	a5,1
	beq	s9,a5,.L222
	li	a5,-1
	beq	s9,a5,.L223
.L121:
	addi	a5,t4,-40
	li	s3,70
	bgtu	a5,s3,.L125
	li	a5,39
	ble	t1,a5,.L165
	li	a5,69
	bgt	t1,a5,.L166
.L125:
	bgt	t6,zero,.L126
.L127:
	addi	a2,a2,1
	li	a5,5
	beq	a2,a5,.L224
.L131:
	li	a5,1
	sub	a3,a5,a3
	li	a5,-2046820352
	sw	a3,4(a5)
	li	a4,0
.L132:
	li	a5,4096
	addi	a5,a5,904
	beq	a4,a5,.L225
	addi	a4,a4,1
	j	.L132
.L222:
	li	s6,0
	li	s4,0
	li	s5,0
.L117:
	li	a5,8192
	addi	a5,a5,-1942
	beq	s6,a5,.L121
	slli	a5,s5,1
	add	a5,a5,s5
	slli	s3,a5,3
	add	s3,s3,s5
	slli	a5,s3,3
	add	a5,s4,a5
	add	a5,a4,a5
	li	s3,87
	sb	s3,0(a5)
	addi	s6,s6,1
	addi	s4,s4,1
	li	a5,50
	bne	s4,a5,.L117
	addi	s5,s5,1
	li	s4,0
	j	.L117
.L223:
	li	s6,0
	li	s4,0
	li	s5,0
.L122:
	li	a5,8192
	addi	a5,a5,-1942
	beq	s6,a5,.L121
	slli	a5,s5,1
	add	a5,a5,s5
	slli	s3,a5,3
	add	s3,s3,s5
	slli	a5,s3,3
	add	a5,s4,a5
	addi	a5,a5,150
	add	a5,a4,a5
	li	s3,87
	sb	s3,0(a5)
	addi	s6,s6,1
	addi	s4,s4,1
	li	a5,50
	bne	s4,a5,.L122
	addi	s5,s5,1
	li	s4,0
	j	.L122
.L165:
	mv	t6,a0
.L126:
	li	s6,0
	li	s5,0
	li	s7,0
.L128:
	li	a5,4096
	addi	a5,a5,1904
	beq	s6,a5,.L127
	li	s3,-2093981696
	addi	s3,s3,-1276
	add	s3,s6,s3
	slli	a5,s7,1
	add	a5,a5,s7
	slli	s4,a5,3
	add	s4,s4,s7
	slli	a5,s4,3
	add	a5,s5,a5
	li	s4,12288
	addi	s4,s4,-263
	add	a5,a5,s4
	add	a5,a4,a5
	lbu	s3,0(s3)
	sb	s3,0(a5)
	addi	s6,s6,1
	addi	s5,s5,1
	li	a5,150
	bne	s5,a5,.L128
	addi	s7,s7,1
	li	s5,0
	j	.L128
.L166:
	mv	t6,a0
	j	.L126
.L224:
	li	a2,0
	j	.L131
.L225:
	bgt	t6,zero,.L226
.L134:
	li	a5,-2063597568
	lw	a5,4(a5)
	andi	a5,a5,1
	beq	a5,zero,.L60
	beq	s2,zero,.L146
.L60:
	bne	a5,zero,.L61
	beq	s2,zero,.L61
	mv	s2,a5
	j	.L61
.L226:
	li	a0,0
	lw	s0,44(sp)
	lw	s1,40(sp)
	lw	s2,36(sp)
	lw	s3,32(sp)
	lw	s4,28(sp)
	lw	s5,24(sp)
	lw	s6,20(sp)
	lw	s7,16(sp)
	lw	s8,12(sp)
	lw	s9,8(sp)
	addi	sp,sp,48
	jr	ra
	.size	main, .-main
	.ident	"GCC: (SiFive GCC 8.3.0-2019.08.0) 8.3.0"
