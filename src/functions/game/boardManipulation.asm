;******************************************************************************
;* PLACE CHIP
;******************************************************************************
; Updates the BOARD_STATE register with the new chip, and
; draws it on the screen. Used both to add a chip on the board,
; and to update existing ones (when flipping chips).
; r0 = X position in board
; r1 = Y position in board
; r2 = slot register number
; r3 = slot bit position
;
; modifies: r1-r9 (through blit call)
; returns nothing of interest

updateBoardAndDrawChip:
updateBoardAndDrawChip	SUBROUTINE
	lr 		K, P
	pi      kstack.push

    ;-----------------------------------
    ;--- First place chip in BOARD_STATE
	SETISAR PLAYER_STATE
	GET_PLAYER_TURN
	bnz 	.setBitPlayer2
	li 	    PLAYER1_COLOR
	lr      5, A 		; store color in r5 for later
	li 		%00000010	; set bit pattern to 10 for player 1
	br 	.setBitEnd
.setBitPlayer2:
	li 		PLAYER2_COLOR
	lr 		5, A 		; store color in r5 for later
	li 		%00000011	; set bit pattern to 11 for player 2
.setBitEnd:
	lr 		4, A		; store bit pattern in r4
    ; create dynamic mask to set the bit in the right position
	lis 	3			; first store %00000011 in A
	lr 		7, A		; store it in r7
	lr 		A, 3		; load bit position from r3
	lr 		6, A		; and store it in r6 oo to later shift r7 to the right position (with calls to DS/SL)
	ni 		%11111111	; check if bit position is zero, in which case no need to shift
	lr 		A, 7		; load dynamic mask from r7
	bz	 	.noShift
	lr 		A, 4		; load bit from r4
.loopShiftBitPattern:	
	sl		1			; shift to get the bit in the right position
	ds		3			; count number of bits to offset
	bnz		.loopShiftBitPattern
	lr 		4, A		; store bit pattern shifted to correct position in r4
	lr 		A, 7		; load dynamic mask from r7
.loopShiftDynamicMask:
	sl 		1			; shift to get the bit in the right position
	ds      6			; count number of bits to offset
	bnz	 	.loopShiftDynamicMask
.noShift:
	com                 ; invert to get the actual dynamic mask (we want to mask OUT the bits we want to set)
	lr 		7, A		; store dynamic mask in r7

	lr 		A, 2		; load register number from r2
	lr 		IS, A		; set ISAR to the register number
	lr 		A, S		; load byte from BOARD_STATE
	ns 		7			; clear the slot (2 bits) to set
	lr 		S, A
	lr 		A, 4		; load new slot
	xs 		S 			; set the slot

	lr 		S, A		; save board state register updated

    ;------------------------------------
    ;--- Then draw the chip on the screen
	; calculate X position
	lr 		A, 0
	com
	ai 		1
	lr		2, A
	lr 		A, 0
	sl 		1
	sl 		1
	sl 		1
	as 		2
	ai 		4
	lr 		2, A		; store X in r2

	; calculate Y position
	lr 		A, 1
	sl		1
	com
	ai 		1
	lr		3, A
	lr 		A, 1
	sl 		1
	sl 		1
	sl 		1
	as 		3
	ai 		4
	lr 		3, A		; store Y in r3

	; set background color, $ff being transparent color
	li 		COLOR_TRANSPARENT
	lr 		0, A		; store color 1 in r0 (for blit)
	; set color based on current player
	lr 		A, 5
	lr 		1, A		; store color 2 in r1 (for blit)

	dci 	gfx.piece.data
	pi 		slot.draw

	pi	 	kstack.pop
	pk


;******************************************************************************
;* GET SLOT CONTENT
;******************************************************************************
; Get the content of a slot from BOARD_STATE
; r0 = X position
; r1 = Y position
;
; modifies: r2, r3, r4
; returns the slot content in A, the slot register number in r2, and the slot bit position in r3

getSlotContent:
getSlotContent	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	; calculate register number
	lr 		A, 1 	; load Y position
	sl 		1		; multiply by 8
	sl 		1
	sl 		1
	as 	    0		; add X to Y*8 to get index of slot to test
	lr 		2, A	; store index in r2

	ni 		%00000011	; find remainder of division by 4	
	sl 		1		; multiply by 2 to get the bit position
	lr 		3, A	; store bit position in r3
	lr 		4, A	; store bit position in r4 too (r4 will be used with DS to count bits to shift, so it will end up with 0)

	lr 		A, 2
	sr 		1		; divide by 4 to find register (each byte stores 4 slots of 2 bits)
	sr 		1
	ai 		BOARD_STATE	; add 32 to get the register number
	lr 		2, A	; store register number in r2

	lr 		A, 4	; load bit position from r4
	ni 		%11111111	; check if byte is zero, in which case no need to shift
	lr		A, 2	; load register number from r2
	lr		IS, A	; set ISAR to the register number
	lr		A, S	; load byte from BOARD_STATE
	bz	 	.noShift
.loopShift:
	sr		1			; shift to get the bit in the right position
	ds		4			; count number of bits to offset
	bnz		.loopShift
.noShift
	ni 		%00000011	; mask out the 2 bits we want to check/flip
	lr      4, A   		; store the content in r4

	pi 		kstack.pop
	lr 		A, 4		; return content in A
	pk


;******************************************************************************
;* FLIP CHIPS IN DIRECTION
;******************************************************************************
; Tries to flip chips in a direction, and calls updateBoardAndDrawChip if it finds any
; r0 = initial X position
; r1 = initial Y position
; r2 = slot register number (used to call updateBoardAndDrawChip)
; r3 = slot bit position (used to call updateBoardAndDrawChip)
; r4 = X direction
; r5 = Y direction
; r6 = call updateBoardAndDrawChip if zero; only do checks if 2; if 1, avoid calling updateBoardAndDrawChip multiple times but flip chips
; r7 = player turn (used to check if slot is player 1 or player 2)
;
; modifies: r4-r5, r7-r10 (through updateBoardAndDrawChip call; r7 not modified if only checking)
;			r0-r1 are preserved, r2-r3 too if needed (no chip flipped in this direction), r6 returned as 1 if updateBoardAndDrawChip was called
;			r16-r26 (used to preserve params)
; returns in r6: 1 if updateBoardAndDrawChip was called, or if r6 was 1 initially, to avoid calling it multiple times.
;	Also serves to know if move was deemed valid, as it will be 0 if no chips were flipped on this direction
;   or on previous directions checked
; returns in r10: the number of chips that can be flipped in this direction (if only checking, with r6=2)

flipChipsInDirection:
flipChipsInDirection	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	; preserve parameters passed
	PRESERVE_PARAM 0, 16
	PRESERVE_PARAM 1, 17
	PRESERVE_PARAM 2, 18
	PRESERVE_PARAM 3, 19
	PRESERVE_PARAM 4, 20
	PRESERVE_PARAM 5, 21
	PRESERVE_PARAM 6, 22
	PRESERVE_PARAM 7, 23
	
	lis 	0
	lr 		10, A		; store 0 in r10 (used to track if opponents chips were found)

	; move to next slot to check
.flipChipsInDirection.loop:
	; get new X
	lr		A, 0	; load X position
	as	  	4		; add X direction
	ci		8		; check if we reached the end of the board
	bz		.noChipsToFlip
	ci		$ff		; check if we reached the beginning of the board
	bz 		.noChipsToFlip
	lr 		0, A    ; store new X position in r0

	; get new Y
	lr		A, 1	; load Y position
	as		5		; add Y direction
	ci		8		; check if we reached the end of the board
	bz		.noChipsToFlip
	ci		$ff		; check if we reached the beginning of the board
	bz		.noChipsToFlip
	lr		1, A	; store new Y position in r1
	br		.checkSlotContent

.noChipsToFlip:
	jmp 	flipChipsInDirection.end

.checkSlotContent:
	pi 		getSlotContent
	lr 		8, A	; store slot content in r8
	RESTORE_PARAM 2, 18
	RESTORE_PARAM 3, 19
	RESTORE_PARAM 4, 20

	lr 		A, 8	; load back slot content

	ni 		%00000011	; check if slot is empty
	bz 		.noChipsToFlip	; if slot is empty, no chips to flip

	; branching depending on which player is playing
	lr 		A, 7
	ni 		%00000001
	bz 		.checkPlayer1
.checkPlayer2:
	lr 		A, 8	; load back slot content
	ci 		%00000010	; check if slot contains a player 1 chip
	bz      .checkSlotContent.opponentChipsFound
	br      .checkSlotContent.ownChipsFound
.checkPlayer1
	lr 		A, 8	; load back slot content
	ci 		%00000011	; check if slot container a player 2 chip
	bz      .checkSlotContent.opponentChipsFound
	br      .checkSlotContent.ownChipsFound
.checkSlotContent.opponentChipsFound:
	lr 		A, 10	; load previous chips found
	inc
	lr 		10, A	; store new chips found
	jmp 	.flipChipsInDirection.loop	; continue looping, to check if there are more chips to flip, or if there is a chip from the current player to complete a line
.checkSlotContent.ownChipsFound:
	lr 		A, 10	; load previous opponents chips found
	ni 		%11111111
	bz      .noChipsToFlip	; if no opponents chips were found, no chips to flip

	; chips to flip... start flipping baby
.flipChips:
	RESTORE_PARAM 0, 16	; restore initial X
	RESTORE_PARAM 1, 17	; restore initial Y
	lr 		A, 6	; r6 is 0 if we need to place chip, 2 if only checking (from canPlayerMove for instance), 1 if placeChip was called 
					; and we need to avoid calling it multiple times
	ni 		%11111111
	bz 		.callPlaceChip
	ci 		2		; are we only checking, and not placing?
	bz 		.validMoveExists	; if so, no need to place chip
	jmp 	.flipChips.loop		; chip was already placed, keep loop until all existing chips are flipped
.validMoveExists:
	lis 	1
	lr 		6, A	; store 1 to mark valid move
	jmp 	flipChipsInDirection.end
.callPlaceChip:
	PLACE_CHIP_SOUND
	pi      updateBoardAndDrawChip
	; animate chip flipping
	li		128
	lr 		5, A
	pi 		BIOS_DELAY
	RESTORE_PARAM 5, 21
	RESTORE_PARAM 7, 23

	lr 		A, 7	; load player playing
	ni 		%00000001
	bz 		.addScorePlayer1
	SETISAR PLAYER2_SCORE
	br 		.addScoreEnd
.addScorePlayer1
	SETISAR PLAYER1_SCORE
.addScoreEnd
	lis 	1
	ai 		$66
	asd 	S
	lr 		S, A

	pi      updateScoreInSidebar
	RESTORE_PARAM 0, 16 ; restore initial X
	RESTORE_PARAM 1, 17 ; restore initial Y
	RESTORE_PARAM 4, 20 ; restore r4 and r5 lost when calling updateBoardAndDrawChip
	RESTORE_PARAM 5, 21
	RESTORE_PARAM 7, 23

	lis 	1
	lr 		6, A	; store 1 in r6 to avoid calling updateBoardAndDrawChip multiple times (if several directions can be flipped)
	PRESERVE_PARAM 6, 22	; preserve r6
.flipChips.loop:
	lr		A, 0	; load X position
	as	  	4		; add X direction
	lr 		0, A    ; store new X position in r0
	PRESERVE_PARAM 0, 24	; preserve new X

	; get new Y
	lr		A, 1	; load Y position
	as		5		; add Y direction
	lr		1, A	; store new Y position in r1
	PRESERVE_PARAM 1, 25	; preserve new Y

	; call getSlotContent to retrieve register number and bit position to update in r2 and r3
	pi 		getSlotContent
	RESTORE_PARAM  4, 20

	PLACE_CHIP_SOUND
	pi 		updateBoardAndDrawChip

	; animate chip flipping
	li		128
	lr 		5, A
	pi 		BIOS_DELAY

	RESTORE_PARAM  7, 23

	lis	 	1
	lr 		0, A	; for decimal substraction

	lr 		A, 7	; load player playing
	ni 		%00000001
	bz 		.updateScorePlayer1
	SETISAR PLAYER2_SCORE
	lis	    1
	ai 		$66
	asd 	S
	lr 		S, A
	SETISAR PLAYER1_SCORE
	lis	    1
	com
	asd 	S
	ai 		$66
	asd 	0
	lr 		S, A
	br 		.updateScoreEnd
.updateScorePlayer1
	SETISAR PLAYER1_SCORE
	lis	    1
	ai 		$66
	asd 	S
	lr 		S, A
	SETISAR PLAYER2_SCORE
	lis	    1
	com
	asd 	S
	ai 		$66
	asd 	0
	lr 		S, A

.updateScoreEnd
	pi 		updateScoreInSidebar

	RESTORE_PARAM  0, 24
	RESTORE_PARAM  1, 25
	RESTORE_PARAM  4, 20
	RESTORE_PARAM  5, 21
	RESTORE_PARAM  6, 22
	RESTORE_PARAM  7, 23

	ds 		10		; decrement number of chips to flip
	bnz 	.flipChips.loop.jmp	; loop until all chips are flipped
	jmp     flipChipsInDirection.end
.flipChips.loop.jmp:
	jmp 	.flipChips.loop

flipChipsInDirection.end:
	RESTORE_PARAM 0, 16	; restore initial X
	RESTORE_PARAM 1, 17	; restore initial Y
	pi      kstack.pop
	pk
