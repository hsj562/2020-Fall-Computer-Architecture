.global convert
.type matrix_mul, %function

.align 2
# int convert(char *);
convert:

    # insert your code here
    # Green card here: https://www.cl.cam.ac.uk/teaching/1617/ECAD+Arch/files/docs/RISCVGreenCardv8-20151013.pdf
    # '+' = 43 '-' = 45 '0' = 48 '9' = 57
	lbu  x6 , 0(x10) 	# x6 is the first char 
	addi x5 , x0, 0		# x5 = 0
	addi x28, x0, 1
	
	addi x7 , x0, 45	# x7 = '-'
	beq  x6 , x7, NEG	# first char is '-'
	
	addi x7 , x0, 43	# x7 = '+'
	beq  x6 , x7, POS	# first char is '+'
	
	addi x7 , x0, 1
	beq  x0 , x0, Loop  # goto Loop
NEG:
	addi x7 , x0, -1	# sign = -1
	add  x10 , x10, x28	# i = i+1	
	lbu  x6 , 0(x10)	# load next char
	beq	 x0 , x0, Loop	# goto Loop
POS:
	addi x7 , x0, 1	 	# sign = +1
	add  x10, x10,x28  	# i = i+1 				
	lbu	 x6 , 0(x10)	# load
Loop:
	beq  x6, x0, EXIT
	
	addi x29, x0, 58
	bge	 x6, x29, ERR_EXIT
	
	addi x29, x0, 47
	blt	 x6 , x29, ERR_EXIT

	addi x6 , x6, -48	# to int
	addi x31, x0, 10
	mul  x5 , x5, x31	# multiply
	add  x5 , x5, x6
	add  x10, x10,x28
	lbu  x6, 0(x10)
	beq  x0, x0, Loop
ERR_EXIT:
	addi x10, x0, -1
	ret
EXIT:
	mul	x10, x5, x7
	ret
