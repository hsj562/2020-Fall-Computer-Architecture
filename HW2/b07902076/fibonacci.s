.global fibonacci
.type fibonacci, %function

.align 2
# unsigned long long int fibonacci(int n);
fibonacci:  
    
    # insert code here
    # Green card here: https://www.cl.cam.ac.uk/teaching/1617/ECAD+Arch/files/docs/RISCVGreenCardv8-20151013.pdf

	addi  x5, x0, 0 	# a = 0
	addi  x6, x0, 1 	# b = 1
	addi  x7, x0, 1 	# c = 1
Loop:
	beq   x10, x0, Exit  # if n == 0: exit
	addi  x5,  x6, 0		# a = b
	addi  x6,  x7, 0		# b = c
	add   x7,  x5, x6	# c = a + b
	addi  x10, x10, -1	# n--
	beq   x0,  x0, Loop	
Exit:					
	addi x10, x5, 0		# ret = c
	ret	
