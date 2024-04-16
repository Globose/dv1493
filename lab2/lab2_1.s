.equ DISPLAY_1, 0xff200020
.equ DISPLAY_2, 0xff200030
.equ UART_DATA, 0xff201000
.equ STACK_BASE, 0x10000000

.data
numbers:
	.word 0b00111111, 0b00000110, 0b01011011, 0b01001111
	.word 0b01100110, 0b01101101, 0b01111101, 0b00000111
	.word 0b01111111, 0b01101111, 0b01110111, 0b01111100
	.word 0b00111001, 0b01011110, 0b01111001, 0b01110001
	.word 0b00000000

.text
.global _start
_start:	
	ldr	sp, =STACK_BASE
	bl reset_display
	bl counter
	b _end

counter:
/*
-------------------------------------------------------
Read jtag uart, and increments/reduces the display number
-------------------------------------------------------
*/
	push {r4, r5, lr}
	mov r4, #0
	counter_loop:
		mov r5, r4
		bl read_jtag
		
		cmp r0, #112
		beq counter_increase
		cmp r0, #111
		beq counter_decrease
		cmp r0, #27
		beq counter_return
		b counter_loop
		
	counter_increase:
		add r4, #1
		cmp r4, #16
		bne counter_display_upd
		mov r4, #0
		b counter_display_upd
	
	counter_decrease:
		sub r4, #1
		cmp r4, #-1
		bne counter_display_upd
		mov r4, #0xF
		b counter_display_upd
	
	counter_display_upd:
		bl set_display
		b counter_loop
	
	counter_return:
		pop {r4, r5, lr}
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

set_display:
/*
-------------------------------------------------------
Sets a value for the display number at the end
-------------------------------------------------------
Arguments:
r4 - the number that will be displayed (hex)
-------------------------------------------------------
*/
	ldr r0, =numbers
	mov r1, #4
	mul r1, r1, r4
	add r0, r1
	ldr r0, [r0]
	
	ldr r1, =DISPLAY_1
	str r0, [r1]
	bx lr
	
reset_display:
/*
-------------------------------------------------------
Resets the display
-------------------------------------------------------
*/	
	mov r1, #0b00000000
	ldr r0, =DISPLAY_1
	str r1, [r0]
	ldr r0, =DISPLAY_2
	str r1, [r0]
	bx lr

_end:
  B _end

.end

