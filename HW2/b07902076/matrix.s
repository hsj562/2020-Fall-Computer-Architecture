.global matrix_mul
.type matrix_mul, %function
.align 2
# void matrix_mul(unsigned int A[][], unsigned int B[][], unsinged int C[][]);
matrix_mul:
    # insert code here
    # Green card here: https://www.cl.cam.ac.uk/teaching/1617/ECAD+Arch/files/docs/RISCVGreenCardv8-20151013.pdf
    # Matrix multiplication: https://en.wikipedia.org/wiki/Matrix_multiplication
    addi sp, sp, -88
    sd s1, 80(sp)
    sd s2, 72(sp)
    sd s3, 64(sp)
    sd s4, 56(sp)
    sd s5, 48(sp)
    sd s6, 40(sp)
    sd s7, 32(sp)
    sd s8, 24(sp)
    sd s9, 16(sp)
    sd s10, 8(sp)
    sd s11, 0(sp)

    addi t0, x0, 128	# SIZE
    slli t3, t0, 8
    addi t3, t3, -16	
    slli t4, t0, 8		# bound of C

    add t4, a2, t4		
    addi s11, a1, 256	# bound of B
for1:
	
for2:
    addi s1, a0, 256	# bound of A
    addi s3, x0, 0
    addi s4, x0, 0
    addi s5, x0, 0
    addi s6, x0, 0
    addi s7, x0, 0
    addi s8, x0, 0
    addi s9, x0, 0
    addi s10, x0, 0
for3:
    lhu a3, 0(a0)		# load A[i][k]
    
	lhu s2, 0(a1)		# load B[k][j]
    mul t5, s2, a3		# A[i][k] * B[k][j]
    add s3, s3, t5		# C[i][j] += A[i][k] * B[k][j]
	andi s3, s3, 1023	# % MOD
    
	lhu s2, 2(a1)
    mul s2, s2, a3
    add s4, s4, s2
	andi s4, s4, 1023
    
	lhu s2, 4(a1)
    mul s2, s2, a3
    add s5, s5, s2
	andi s5, s5, 1023
    
	lhu s2, 6(a1)
    mul s2, s2, a3
    add s6, s6, s2
	andi s6, s6, 1023
    
	lhu s2, 8(a1)
    mul s2, s2, a3
    add s7, s7, s2
	andi s7, s7, 1023
    
	lhu s2, 10(a1)
    mul s2, s2, a3
    add s8, s8, s2
    andi s8, s8, 1023
    
	lhu s2, 12(a1)
    mul s2, s2, a3
    add s9, s9, s2
	andi s9, s9, 1023

    lhu s2, 14(a1)
    mul s2, s2, a3
    add s10, s10, s2
    andi s10, s10, 1023

    addi a0, a0, 2
    addi a1, a1, 256
    blt a0, s1, for3

    sh s3, 0(a2)	# store C
    sh s4, 2(a2)
    sh s5, 4(a2)
    sh s6, 6(a2)
    sh s7, 8(a2)
    sh s8, 10(a2)
    sh s9, 12(a2)
    sh s10, 14(a2)

    addi a2, a2, 16		
    addi a0, a0, -256	# next 8 columns
    sub a1, a1, t3		
   	blt a1, s11, for2	# if finish
   
	addi a1, a1, -256	# back to the prev row
    addi a0, a0, 256
	blt a2, t4, for1
    
	ld s1, 80(sp)
    ld s2, 72(sp)	
    ld s3, 64(sp)
    ld s4, 56(sp)
    ld s5, 48(sp)
    ld s6, 40(sp)
    ld s7, 32(sp)
    ld s8, 24(sp)
    ld s9, 16(sp)
    ld s10, 8(sp)
    ld s11, 0(sp)
    addi sp, sp, 88
    ret
