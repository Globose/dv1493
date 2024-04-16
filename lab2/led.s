.equ LED, 0xff200000
.equ FILTER, 0x7ff

.global _start
_start:
	mov r0, #128
	bl set_led
	bl flip_led
	bl get
	b _end

flip_led:
/*
-------------------------------------------------------
Activates the inactive LED:s and activates the inactive
-------------------------------------------------------
*/
	ldr r1, =LED
	ldr r0, [r1]
	ldr r2, =FILTER
	eor r0, r2
	b set_led
	bx lr

get_led:
/*
-------------------------------------------------------
Reads the LED status
-------------------------------------------------------
Returns:
r0 - the number that the LED is be displaying in binary
-------------------------------------------------------
*/
	ldr r1, =LED
	ldr r0, [r1]
	bx lr

set_led:
/*
-------------------------------------------------------
Activates the LED:s
-------------------------------------------------------
Parameters:
r0 - the number that the LED should be displaying in binary 
-------------------------------------------------------
*/
	ldr r1, =LED
	str r0, [r1]
	bx lr
	
_end:
  B _end

.end