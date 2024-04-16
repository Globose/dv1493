.equ DISPLAY_1, 0xff200020
.equ DISPLAY_2, 0xff200030

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
	bl set_display
	b _end
	
set_display:
/*
-------------------------------------------------------
Sets a value for the display
-------------------------------------------------------
Returns:
r0 - the number that will be displayed
-------------------------------------------------------
*/
	ldr r2, =numbers
	ldr r0, [r2]
	
	loop:
		ldr r1, =DISPLAY_1
		str r0, [r1]
		ldr r1, =DISPLAY_2
		str r0, [r1]
	
	add r2, r2, #4
	ldr r0, [r2]
	cmp r0, #0
	bne loop
	bx lr

_end:
  B _end

.end

