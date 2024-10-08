;******************************************************************************
;* DRAWING SUBROUTINES
;* Slightly adapted from veswiki (plot & blit)
;* clearscreen adapted from builtin bios version to use r0 and kstack
;******************************************************************************

;----------------------;
; Clearscreen Function ;
;----------------------;
; Clears the screen line by line, but without relying on r31 set to 0 and using
; improved kstack from VES Wiki (doesn't use the drawchar like the builtin clrscrn)
; r1 = color

clearscreen:
clearnscreen	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	; color is already in r1
	; start from row 57 (bottom)
	li 		57
	lr 		3, A
.row.loop:
	; draw from column 101
	li		101
	lr		2, A
.column.loop:
	pi 		plot
	ds 		2		; move left
	bc   	.column.loop
	ds 		3		; move up
	bc 		.row.loop

.drawEnd:
	pi   kstack.pop
	pk

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

;===========;
; Blit Code ;
;===========;

;--------------;
; Blit Graphic ;
;--------------;

; takes graphic parameters from ROM, stores them in r1-r6, 
; changes the DC and calls the blit function with the parameters
;
; modifies: r1-r6, Q, DC

blitGraphic:
	; load six bytes from the parameters into r0-r5
	lisu	0
	lisl	1
.blitGraphicGetParms:
	lm   
	lr	I, A						; store byte and increase ISAR
	br7	.blitGraphicGetParms		; not finished with the registers, loop

	; load the graphics address
	lm
	lr	Qu, A						; into Q
	lm
	lr	Ql, A
	lr	DC, Q						; load it into the DC

	; call the blit function
	jmp	blit


;---------------;
; Blit Function ;
;---------------;

; this function blits a graphic based on parameters set in r1-r6,
; and the graphic data pointed to by DC0, onto the screen
; originally from cart 26, modified and annotated
;
; modifies: r1-r9, DC

; register reference:
; -------------------
; r1 = color 1 (off)
; r2 = color 2 (on)
; r3 = x position
; r4 = y position
; r5 = width
; r6 = height (and vertical counter)
;
; r7 = horizontal counter
; r8 = graphics byte
; r9 = bit counter
;
; DC = pointer to graphics

blit:
	; fix the x coordinate
	lis	4
	as	3
	lr	3, A
	; fix the y coordinate
	lis	4
	as	4
	lr	4, A

	lis	1
	lr	9, A					; load #1 into r9 so it'll be reset when we start
	lr	A, 4					; load the y offset
	com							; invert it
.blitRow:
	outs	5					; load accumulator into port 5 (row)

	; check vertical counter
	ds	6						; decrease r6 (vertical counter)
	bnc	.blitExit				; if it rolls over exit

	; load the width into the horizontal counter
	lr	A, 5
	lr	7, A

	lr	A, 3					; load the x position
	com							; complement it
.blitColumn:
	outs	4					; use the accumulator as our initial column
	; check to see if this byte is finished
	ds	9						; decrease r9 (bit counter)
	bnz	.blitDrawBit			; if we aren't done with this byte, branch

.blitGetByte:
	; get the next graphics byte and set related registers
	lis	8
	lr	9, A					; load #8 into r9 (bit counter)
	lm
	lr	8, A					; load a graphics byte into r8

.blitDrawBit:
	; shift graphics byte
	lr	A, 8					; load r8 (graphics byte)
	as	8						; shift left one (with carry)
	lr	8, A					; save it

	; check color to use
	lr	A, 2					; load color 1
	bc	.blitSavePixel			; if this bit is on, draw the color
	lr	A, 1					; load color 2
.blitSavePixel:
	inc
	bc	.blitCheckColumn		; branch if the color is "clear"
	outs	1					; output A in p1 (color)

.blitTransferData:
	; transfer the pixel data
	li	$60
	outs	0
	li	$c0
	outs	0
	; and delay a little bit
.blitSavePixelDelay:
	ai	$60						; add 96
	bnz	.blitSavePixelDelay		; loop if not 0 (small delay)

.blitCheckColumn:
	ds	7						; decrease r7 (horizontal counter)
	bz	.blitCheckRow			; if it's 0, branch

	ins	4						; get p4 (column)
	ai	$ff						; add 1 (complemented)
	br	.blitColumn				; branch

.blitCheckRow:
	ins	5						; get p5 (row)
	ai	$ff						; add 1 (complemented)
	br	.blitRow				; branch

.blitExit:
	; return from the subroutine
	pop
