;******************************************************************************
;* DRAW BOARD
;******************************************************************************

BOARD_MIDDLE_X	= 28
BOARD_RIGHT_X 	= 57
BOARD_TOP_Y 	= 4
BOARD_BOTTOM_Y 	= 52

board.draw:
boardDraw 	SUBROUTINE
	lr 		K, P
	pi 		kstack.push

	; blue color
	li 		BOARD_COLOR
	lr 		1, A
	; draw top line, starting from middle (55 width)
	li 		BOARD_MIDDLE_X
	lr 		4, A

.topAndBottomLines.loop:
	lr 		A, 4
	ai		3		; offset from left screen limit
	lr 		2, A

	; y = 4
	lis		BOARD_TOP_Y
	lr 		3, A
	pi		plot
	; y = 52
	li		BOARD_BOTTOM_Y
	lr		3, A
	pi		plot

	; draw from middle, right
	; calculate symmetric number by doing (BOARD_RIGHT_X-r4)
	lr 		A, 4
	com
	ai		5	; +1 for 2 complement +4 for offset
	ai 		BOARD_RIGHT_X
	lr 		2, A
	pi		plot

	lis		BOARD_TOP_Y
	lr 		3, A
	pi		plot

	ds 		4
	bz 		.vertLines

    ; delay between each plots (animation effect)
    DELAY 	$ff

	br 		.topAndBottomLines.loop

.vertLines:
	; plot missing center pixels from top/bottom
	li 	BOARD_MIDDLE_X+4
	lr 		2, A
	lis 	BOARD_TOP_Y
	lr 		3, A
	pi 		plot

	li 		BOARD_BOTTOM_Y
	lr 		3, A
	pi 		plot

	; init variables for vertical lines
	; first x position, to draw from vertical middle
	li 		BOARD_MIDDLE_X
	lr 		4, A	; left side
	lr 		5, A	; right side
	; first y position (r6 top, r7 bottom)
	lis 	5
	lr 		6, A
	; counter to draw horizontal line every 6 vertical pixels
	lis 	6
	lr 		8, A
	; used to draw horizontal line, starting from middle (55 width)
	li 		BOARD_MIDDLE_X
	lr 		7, A

.vertLines.loop:
	lr 		A, 6
	lr 		3, A

	lr 		A, 4
	ai		4
	lr 		2, A
	pi 		plot

	lr 		A, 6
	com
	ai 		57		; 56 + 1 for 2 complement
	lr 		3, A
	pi 		plot

	lr 		A, 5
	ai		4
	lr 		2, A
	pi 		plot

	lr 		A, 6
	lr 		3, A
	pi 		plot	

	li 		%11111001	; add -7 to r4
	as 		4
	lr 		4, A
	bz 		.vertLines.checkHorizontalLine
	lr 		A, 5
	ai		7
	lr 		5, A
	jmp 	.vertLines.loop

.vertLines.checkHorizontalLine:
	ds		8
	bz 		.vertLines.horizontalLine
	jmp 	.vertLines.nextLine

.vertLines.horizontalLine:
	lr 		A, 7
	ai		4
	lr 		2, A

	; top side
	lr 		A, 6
	lr 		3, A
	pi		plot
	; bottom side
	lr 		A, 6
	com
	ai 		57  		; 56 + 1 for 2 complement
	lr 		3, A
	pi		plot

	; draw from middle, right
	; calculate symmetric number by doing (BOARD_RIGHT_X-r7)
	lr 		A, 7
	com
	ai		5		; +1 for 2 complement +4 for offset
	ai		BOARD_RIGHT_X
	lr 		2, A
	pi		plot

	lr 		A, 6
	lr 		3, A
	pi		plot

	ds 		7
	bnz 	.vertLines.horizontalLine
	lis 	6
	lr 		8, A
	li 		28
	lr 		7, A

.vertLines.nextLine:
	; left side
	lr 		A, 6
	lr 		3, A

	lis 	4
	lr 		2, A
	pi 		plot

	; right side
	li 		60
	lr 		2, A
	pi 		plot

	lr 		A, 6
	com
	ai 		57		; 56 + 1 for 2 complement
	lr 		3, A
	pi 		plot

	; left side bottom
	lis 	4
	lr 		2, A
	pi 		plot

	lr 		A, 6
	inc
	lr 		6, A

	; check if we reached middle of vertical lines
	ci 		29
	bz 		.drawEnd

	li 		BOARD_MIDDLE_X
	lr 		4, A
	lr 		5, A

	DELAY 	$ff

	jmp 	.vertLines.loop

.drawEnd:
	pi 		kstack.pop
	pk


;******************************************************************************
;* SPRITE SLOT DRAWING
;******************************************************************************
; r0 = color 1
; r1 = color 2
; r2 = x position
; r3 = y position
;
; modifies: r1-r9 (through blit call)

slot.draw:
	DRAW_BLIT 8, 7
