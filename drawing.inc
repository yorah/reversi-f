;******************************************************************************
;* DRAWING FUNCTIONS
;* Slightly adapted from veswiki
;******************************************************************************

;---------------;
; Plot Function ;
;---------------;

; plot out a single point on the screen
; uses three registers as "arguments"
; r1 = color
; r2 = x (to screen) (0-127)
; r3 = y (to screen) (0-63)
; Including parts outside the screen
;------------------------
; Valid colors
;------------------------
; green	= $00 (%00000000)
; red	= $40 (%01000000)
; blue	= $80 (%10000000)
; bkg	= $C0 (%11000000)
;------------------------

plot:
	; set the color using r1
	lr		A, 1
	outs	1		; Color is set by bit 6 and 7 only

	; set the column using r2
	lis		4
	as		2		; adjust the x coordinate
	com
	outs	4		; place inverted coordinate for x on port 4 (bit 7 not used)

	; set the row using r3
	lis		4
	as		3		; adjust the y coordinate
	com
	outs	5		; place inverted coordinate for y on port 5 (bit 6, 7 not used, those are for sound)

	; transfer data to the screen memory by toggling ARM
	li 		$60
	outs	0		; %01100000, no controller inputs, set b5 ARM to 1
	sl		1
	outs	0		; %11000000, no controller inputs, b5 ARM = 0, b7 (N/C) is set to 1

	; delay until it's fully updated
	lis		4		; Value is 4 in Videocart 21 - Bowling
.plotDelay:	
	ai		$ff
	bnz		.plotDelay

	pop				; return from the subroutine
