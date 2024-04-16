.equ SWITCH, 0xff200040

.global _start
_start:
	bl get_switch
	b _end

get_switch:
/*
-------------------------------------------------------
Reads the switch status
-------------------------------------------------------
Returns:
r0 - the number that the switches are displaying in binary.
-------------------------------------------------------
*/
	ldr r1, =SWITCH
	ldr r0, [r1]
	bx lr

	
_end:
  B _end

.end