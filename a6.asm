//AUTHOR: Akib Hasan Aryan
//UCID: 30141456

error:	.string "Error opening a file. Aborting\n"

pi:	.double 0r1.57079632679489661923

ninety: .double 0r90.0000000000

heading: .string "Angle\t\tSine(x)\t\tCosine(x)\n"

lines:	.string "%12.10f\t%12.10f\t%12.10f\n"
	
abs_value: .double 0r1.0e-10

check: .string "angle %f\n"


	AT_FDWCD = -100
	buf_size = 8					//Size of the buffer
	d_size	= 8					//Size of the double to be read
	alloc	= -(16 + buf_size + d_size) & -16	//Space to be allocated on stack for variables
	dealloc = -alloc				//Space to be deallocated at the end
	fd_s	= 16					//Position on stack of file descriptor
	bytes_read_s = 20				//Position on stack of number of bytes read
	angle_s   = 24					//Position on stack of the angle to be read itself
	

	.balign 4					//Ensures word alignment
	.global main					//Makes main visible to the linker

main:
	stp	x29, x30, [sp,alloc]!
	mov	x29, sp
	mov	w19, 1		//Moves 1 to w19 which is index of file pathname in command line
	ldr	x20, [x1, w19, SXTW 3]	//Loads pathname in x20
	ldr	x0, =heading	//Loads x0 with the string for the heading of the table
	bl	printf		//Prints the heading
	mov	w0, AT_FDWCD	//1st arg (current working directory)
	mov	x1, x20		//2nd arg (pathname)
	mov	w2, 0		//3rd arg (read-only)
	mov	w3, 0		//4th arg (not used)
	mov	x8, 56		//openat I/O request
	svc	0		//call system function
	str	w0, [x29, fd_s]	//Stores the file descriptor on stack
	cmp	w0, 0		//Check if file opened normally
	b.ge	openok		//If yes go to openok

	ldr	x0, =error	//Otherwise, loads error message
	bl	printf		//Prints the error message
	mov	w0, -1		//Moves -1 to w0 to return -1
	b	exit		//Goes to exit the program
openok:
	ldr	w0, [x29, fd_s]		//1st arg (file descriptor)
	add	x1, x29, angle_s	//2nd arg (pointer to buf)
	mov	x2, buf_size		//3rd arg (n bytes to read)
	mov	x8, 63			//read service request
	svc	0			//System call
	str	w0, [x29, bytes_read_s]	//Stores number of bytes read on stack
	cmp	w0, buf_size		//check that n_read >= 8
	b.lt	exit			//if less than end of the file
	ldr	d0, [x29, angle_s] 	//store double into the register


	fmov	d19, 1.0000000000	//Initial denominator value for the first term of sine
	fmov	d25, 1.0000000000	//value of 1 to be added to the counter for calculation of denominator
	fmov	d26, 2.0000000000	//Value of 2 to be added to the counter for calculation of denominator
	fmov	d13, -1.0000000000	//Value to help attain the appropriate sign of each term in sine
	fmov	d12, -1.0000000000	//Register with value to attain the appropriate sign of each term in cosine
	fmov	d20, 1.0000000000	//Counter for denominator in sine
	fmov	d24, 1.0000000000	//Initial denominator value for the first term of cosine
	fsub	d27, d24, d20		//Counter for numerator in cosine which is 0.0 to begin with
	fmov	d28, 1.0000000000	//Value of numerator for first term in cosine
	fcmp	d0,  0.0		//Compares the angle obtained with 0 to see if is less than, if so
	b.lt	openok			//goes to top of loop
	ldr	x20, =ninety		//Loads address of 90.0
	ldr	d10, [x20]		//Puts 90.0 in d10
	fcmp	d0, d10			//Sees if angle>90
	b.gt	openok			//Goes to top of loop if value of angle is greater than 90 degrees
	
	ldr	x19, =pi		//Loads address of pi in x19
	fmov	d11, d10		//Moves 90 to d11
	ldr	d10, [x19]		//Loads value of pi/2 in d10
	fdiv	d10, d10, d11		// pi/180 to convert degree into radian

	fmul	d0, d10, d0		//Converts degree to radian

	fmov	d1, d0		  	//Moves value of first term of sin(x) to d1
	fmov	d18, d0			//Moves the value of x to d18 which is the value of numerator of first term in sine
	fmov	d2, 1.0000000000	//Moves value 1.0 to d2 which is value of first term in cosine(x0	
not_first:
sine:

	// num *= x^2
	fmul	d21, d0, d0		// x*x stored in d21
	fmul	d18, d18, d21		//x^n+2 stored in d18

	// den = den * (c+1) * (c+2)
	fadd	d21, d20, d25		//c+1 since d20 is 1 and d25 is 1
	fadd	d22, d20, d26		//c+2 since d20 is 1 and d26 is 2
	fmul	d19, d21, d19		//value of (c+1)!
	fmul	d19, d22, d19		//Gives value of current factorial needed for sine

	// get term = num / den * sign
	fdiv	d21, d18, d19		//Divides power of x by factorial
	fmul	d21, d21, d13		//Adds or negates it according to need
	
	ldr	x26, =abs_value		//Loads address of 1.0e-10
	ldr	d22, [x26]		//Loads above value

	fabs	d23, d21		//Gets the absolute value of the current term
 	fcmp	d23, d22		//sees if current term is less than 1.0e-10
	b.lt	cosine			//If so, does not add it to total value of sine

	fadd	d1, d21, d1		//Adds value of sine to total one
	fneg	d13, d13		//Changes value of sign in front of term for next loop
	fadd	d20, d20, d26		//Adds 2 to the counter to progress it for the next term's denominator
	b       sine			//Loops back to sine since terms are still larger than threshold value
cosine:
	fmul	d21, d0, d0		//x*x stored in d21
	fmul	d24, d24, d21		//Stores x^2n in d24

	fadd	d21, d27, d25		//c+1
	fadd	d22, d27, d26		//c+2
	fmul	d28, d28, d21		//(c+1)!
	fmul	d28, d28, d22		//Value of the factorial needed for denominator
	fdiv	d21, d24, d28		//Current term
	fmul	d21, d21, d12		//Applies appropriate negation
	fabs	d23, d21		//Absolute value of current term
	ldr	x26, =abs_value		//Loads address of threshold value
	ldr	d22, [x26]		//Loads threshold value in d22
	fadd	d2, d21, d2		//Adds the term to total value of cosine
	fadd	d27, d27, d26		//Adds 2 to the counter
	fneg	d12, d12		//Negates d12 for appropriate sign in d12
	fcmp	d23, d22		//Compares absolute value of the current term with the threshold value
	b.ge	cosine			//Branches to top of cosine if is greater
	fsub	d2, d2, d21		//Otherwise subtracts the current term that was added which was less than threshold value

	
	
printer:
	
	ldr	x0, =lines		//Loads x0 with string to be printed
	bl	printf			//prints
	
	b	openok			//loop back again
	


exit:
	ldr	w0, [x29, fd_s]		//1st arg(file descriptor)
	mov	x8, 57			//close() service request
	svc	0			//System call


	mov	w0, 0			//Moves 0 to w0

	
	ldp	x29, x30, [sp], dealloc	//Deallocates the memory on stack
	ret				//Returns to OS
