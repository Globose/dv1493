.equ UART_DATA, 0xff201000
.equ UART_CONTROL, 0xff201004

.data
	textA: .asciz "Jtag testing.\n"
	textB: .asciz "This is a long text, more than 64 characters, that will be stored in the data section of the program.\n"

.text
.global _start
_start:
	bl echo
	b _end

/*
-------------------------------------------------------
Reads and writes jtag
-------------------------------------------------------
*/
echo:
	ldr r5, =UART_DATA
	push {lr}
	echo_loop:
		bl read_jtag
		cmp r0, #0
		beq echo_loop

		str r0, [r5]
		b echo_loop

	echo_return:
		pop {lr}
		bx lr

write_jtag_nw:
/*
-------------------------------------------------------
Writes to jtag uart without wait
-------------------------------------------------------
Parameters
r0 - the string that will be displayed
-------------------------------------------------------
*/
	push {r4}	
	ldr r2, =UART_DATA
	jtag_nw_loop:
		ldrb r1, [r0], #1 //Load one byte
		cmp r1, #0
		beq jtag_nw_end
		str r1, [r2]
		b jtag_nw_loop

	jtag_nw_end:
		pop {r4}
		bx lr
	

write_jtag:
/*
-------------------------------------------------------
Writes to jtag uart with wait
-------------------------------------------------------
Parameters
r0 - the string that will be displayed
-------------------------------------------------------
*/
	push {r4}	
	jtag_loop:
		ldrb r1, [r0], #1 //Load one byte
		cmp r1, #0
		beq j_tag_end
		
		wait_space:
			ldr r2, =UART_CONTROL
			ldr r3, [r2]
			ldr r4, =0xffff0000
			ands r3, r3, r4
			beq wait_space
		ldr r2, =UART_DATA
		str r1, [r2]
		b jtag_loop

	j_tag_end:
		pop {r4}
		bx lr

/*
-------------------------------------------------------
Read jtag uart
-------------------------------------------------------
Returns
r0 - the string that has been read
-------------------------------------------------------
*/
read_jtag:
	ldr r1, =UART_DATA
	ldr r0, [r1]
	ands r2, r0, #0x8000
	cmp r2, #0
	beq read_jtag_return
	and r0, r0, #0x00ff
	bx lr

	read_jtag_return:
		mov r0, #0
		bx lr
		

_end:
  B _end

.end

