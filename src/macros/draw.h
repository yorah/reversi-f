; Resets selection blink color and delay (typically called when input is pressed,
; to show that input has been received)
	MAC CLEAR_SELECTION
	SETISAR BLINK_COLOR
	li 		BOARD_COLOR
	lr 		S, A

	SET_BLINKING_COUNTER BLINK_LOOPS

	DRAW_SELECTION

	SETISAR SKIP_BLINK_COLOR
	li 		BOARD_COLOR
	lr 		S, A

	DRAW_SKIP
	ENDM

; Draw selection square on board
	MAC DRAW_SELECTION
	li 		COLOR_TRANSPARENT
	lr 		0, A
	SETISAR BLINK_COLOR
	lr 		A, S
	lr 		1, A
	; calculate X position
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%11100000
	sr		4
	sr	    1
	com
	ai 		1
	lr		2, A
	lr 		A, S
	ni 		%11100000
	sr 		1
	sr 		1
	as 		2
	ai 		4
	lr 		2, A		; store X-screen in r2

	; calculate Y position
	lr 		A, S
	ni 		%00011100
	sr		1			; Y*2 (sr2 + sl1)
	com
	ai 		1			; two complement to get -2Y
	lr		3, A		; store -2Y in r3
	lr 		A, S
	ni 		%00011100
	sl 		1			; Y*8 (sr2 + sl3)
	as 		3			; Y*8 - 2Y = 6Y
	ai 		4			; Add top offset
	lr 		3, A		; store Y-screen in r3	
	dci		gfx.slotSelection.data
	pi slot.draw
	ENDM

; Draw SKIP text on sidebar
	MAC DRAW_SKIP
	li 		COLOR_TRANSPARENT
	lr 		0, A
	SETISAR SKIP_BLINK_COLOR
	lr 		A, S
	lr 		1, A
	; X position
	li 		76
	lr 		2, A		; store X-screen in r2
	; Y position
	li 		15
	lr 		3, A		; store Y-screen in r3	
	dci		gfx.skip.data
	pi skip.draw
	ENDM

; Draw an horizontal line in the sidebar
    MAC SIDEBAR_DRAW_HORIZONTAL_LINE
    li 		COLOR_BACKGROUND
	lr 		1, A
	li 		99
	lr 		2, A
	li 		FIRST_HORIZONTAL_LINE_Y
	lr 		3, A
.drawLine:
	pi 		plot
	ds 		2
	lr 		A, 2
	ci 		66
	bnz 	.drawLine
    ENDM

; Draw a chip on a board slot
	MAC DRAW_CHIP
	li 		$ff
	lr 		0, A		; store color 1 in r0 (for blit)
	li 		{1}
	lr 		1, A		; store color 2 in r1 (for blit)
	li 		{2}
	lr 		2, A		; store X in r2
	li		{3}
	lr 		3, A		; store Y in r3
	dci 	gfx.piece.data
	pi 		slot.draw
	ENDM

	MAC DRAW_BLIT
	; blit reference:
	; r1 = color 1 (off)
	; r2 = color 2 (on)
	; r3 = x position
	; r4 = y position
	; r5 = width
	; r6 = height

	IF {1} < 16
	lis	 	{1}
	ELSE
	li 		{1}
	ENDIF
	lr 		5, A
	IF {1} < 16
	lis 	{2}
	ELSE
	li 		{2}
	ENDIF
	lr 		6, A
	; position
	lr 		A, 3
	lr 		4, A
	lr 		A, 2
	lr 		3, A
	; colors
	lr 		A, 1
	lr 		2, A
	lr		A, 0
	lr		1, A
	
	; draw skip
	jmp 	blit
	ENDM