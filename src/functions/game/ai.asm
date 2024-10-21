;******************************************************************************
;* AI management
;******************************************************************************

	MAC ADD_NEXT_MOVE_SCORE
		lr 		A, 6
		ci 		1
		bnz 	.noChipsToFlip
		; reset r6 to 2 for next direction
		lis 	2
		lr 		6, A
		; r10 contains the number of chips that can be flipped in the tested direction
		lr 		A, 9
		as 		10
		lr 		9, A
.noChipsToFlip:
	ENDM

aiNextMove:
aiNextMove    SUBROUTINE
    lr     K, P
    pi     kstack.push

	SETISAR PLAYER_STATE
	GET_PLAYER_TURN
	lr 		7, A	; store player turn in r7	(for flipChipsInDirection)

    lis    0    ; reset the next move score
    SETISAR AI_NEXT_MOVE_SCORE
    lr     S, A
	lis    %00000001
	lr 	   11, A	; store 1 in r11 to indicate no valid move found by default

	; Set initial X and Y to 7
	lis 	7
	lr    	0, A	; store 7 in r0, initial X=7
	lr 		1, A	; store 7 in r1, initial Y=7

.loopX:
	; resets currently tested move score in r9
	lis 	0
	lr 		9, A
    pi 		getSlotContent

	; check if slot is empty, if not, continue to next slot
	ci 		%00000000
	bnz 	.nextSlotJmp
	br  	.testSlotScore

.nextSlotJmp:
	jmp 	.nextSlot

.testSlotScore:
	; Similarly to what is done in newturn.asm to check if a next valid move exists,
	; we only need to check, not actually flip the chips
	lis 	2		; r6 set to 2, will be set to 1 if chip placed; only set on first direction checked
	lr 		6, A
	; test right direction
	lis 	1
	lr 		4, A
	lis 	0
	lr 		5, A
	pi 		flipChipsInDirection
	ADD_NEXT_MOVE_SCORE
	; test right-up diagonal
	lis 	1
	lr 		4, A
	li  	$ff
	lr 		5, A
	pi 		flipChipsInDirection
	ADD_NEXT_MOVE_SCORE
	; test up direction
	lis 	0
	lr 		4, A
	li	 	$ff
	lr 		5, A
	pi 		flipChipsInDirection
	ADD_NEXT_MOVE_SCORE
	; test left-up diagonal
	li	 	$ff
	lr 		4, A
	li	 	$ff
	lr 		5, A
	pi 		flipChipsInDirection
	ADD_NEXT_MOVE_SCORE
	; test left direction
	li 		$ff
	lr 		4, A
	lis	 	0
	lr 		5, A
	pi 		flipChipsInDirection
	ADD_NEXT_MOVE_SCORE
	; test left-down diagonal
	li 		$ff
	lr 		4, A
	lis	 	1
	lr 		5, A
	pi 		flipChipsInDirection
	ADD_NEXT_MOVE_SCORE
	; test down direction
	lis 	0
	lr 		4, A
	lis	 	1
	lr 		5, A
	pi 		flipChipsInDirection
	ADD_NEXT_MOVE_SCORE
	; test down-right diagonal
	lis 	1
	lr 		4, A
	lis	 	1
	lr 		5, A
	pi 		flipChipsInDirection
	ADD_NEXT_MOVE_SCORE

	; if score is 0 at that point, no chips to flip on this slot
	lr 		A, 9
	ci 		%00000000
	bz 		.nextSlot

	; add positional weight to score
	lr 		A, 1	; Y
	sl 		1		; x8 (sl 3)
	sl 		1
	sl 		1
	as 		0	    ; add X

	dci 	positional.weights
	adc

	lr 		A, 9
	am
	lr 		9, A

	; check if the current move is better than the previous best move, unless this is the first valid move found
	lr 		A, 11
	ni 		%00000001 	; check if a valid move was already found (in which case r11 is not 1)
	SETISAR AI_NEXT_MOVE_SCORE	; set ISAR here to avoid having to set it again in the branch
	bnz 	.storeValidMove	; no valid move found yet

	lr 		A, 9
	com
	ai 		1
	as 		S

	bz		.keepOrContinue	; if 0, then score are equal, randomly take the new one or not
	bp 		.nextSlot	; if positive, then we already have the best score
	jmp 	.storeValidMove

.keepOrContinue:
	; LFSR implementation from: https://channelf.se/veswiki/index.php?title=Snippet:Pseudorandom_numbers
	SETISAR RANDOM_GENERATOR
	clr
	as 		S
	bz 		.doEor
	lr 		2, A
	sl 		1
	lr 		S, A
	bz 		.noEor

	; XOR if b7 was 1, no carry on sl
	lr 		A, 2
	ni 		%10000000
	bz 		.noEor

.doEor:
	lr 		A, S
	xi 		$e7
	lr 		S, A

.noEor:
	; if b7 is 1 (> 128), then keep the new score
	ni 		%10000000
	bz 		.nextSlot	; if 0, then keep the old score
	
	; store the new best score
.storeValidMove:
	lr 		A, 9
	lr 		S, A
	; store the next best score coordinates
	; X
    lr 		A, 0
	sl		4
	sl		1
	lr 		9, A
	lr 		A, 11
	ni 		%00011110	; clear X position (and sets last bit to 0 to indicate valid move)
	xs 		9
	lr    	11, A
	; Y
	lr 		A, 1
	sl 		1
	sl 		1
	lr 		9, A
	lr 		A, 11
	ni 		%11100011	; clear Y position
	xs 		9
	lr   	11, A

.nextSlot:
	; continue looping to find if there is a valid move
	ds 		0			; decrement X
	lr 		A, 0
	ci      $ff
	bnz		.loopBack	; loop until X=0 
	lis 	7
	lr 		0, A		; store 7 in r0, initial X=7 (to check next line)
	ds 		1			; decrement Y
	lr 		A, 1
	ci 		$ff
	bnz     .loopBack	; loop until Y=0
	jmp 	.allSlotsTested

.loopBack:
	jmp 	.loopX		; Branching too far, need to use jmp

.allSlotsTested:
	; move to selection, X from r18 to r16, Y from r19 to r17
	SETISAR PLAYER_STATE
	GET_X_POSITION
	SETISAR 16
	lr 		S, A
	SETISAR PLAYER_STATE
	GET_Y_POSITION
	SETISAR 17
	lr 		S, A

	lr 		A, 11
    ni 		%11100000	; get X position
    sr 		4
    sr 		1
	SETISAR 18
	lr 		S, A

    lr 		A, 11
    ni 		%00011100	; get Y position
    sr 		1
    sr 		1
	SETISAR 19
	lr 		S, A

	; first move to correct X position
.moveX:
	SETISAR 16
	lr 		A, S
	com
	ai 		1
	SETISAR 18
	as 		S
	bz 		.moveYJmp
	bp 		.moveXtoRightJmp
	br 		.moveXToLeftJmp
.moveYJmp:
	jmp 	.moveY
.moveXToLeftJmp:
	jmp 	.moveXtoLeft
.moveXtoRightJmp:
	jmp 	.moveXToRight

.moveXtoLeft:
	CLEAR_SELECTION
	UPDATE_X_POSITION $ff, 0
	SETISAR 16
	ds 		S
	SETISAR BLINK_COLOR
	li 		PLAYER2_COLOR
	lr 		S, A
	DRAW_SELECTION
	li		128
	lr 		5, A
	pi 		BIOS_DELAY
	jmp 	.moveX

.moveXToRight
	CLEAR_SELECTION
	UPDATE_X_POSITION $01, 0
	SETISAR 16
	lr 		A, S
	inc
	lr 		S, A
	SETISAR BLINK_COLOR
	li 		PLAYER2_COLOR
	lr 		S, A
	DRAW_SELECTION
	li		128
	lr 		5, A
	pi 		BIOS_DELAY
	jmp 	.moveX

.moveY
	SETISAR 17
	lr 		A, S
	com
	ai 		1
	SETISAR 19
	as 		S
	bz 		.moveEndJmp
	bp 		.moveYToBottomJmp
	br 		.moveYToTopJmp
.moveEndJmp:
	jmp 	.moveEnd
.moveYToTopJmp:
	jmp 	.moveYToTop
.moveYToBottomJmp:
	jmp 	.moveYToBottom

.moveYToTop:
	CLEAR_SELECTION
	UPDATE_Y_POSITION $ff, 0
	SETISAR 17
	ds 		S
	SETISAR BLINK_COLOR
	li 		PLAYER2_COLOR
	lr 		S, A
	DRAW_SELECTION
	li		128
	lr 		5, A
	pi 		BIOS_DELAY
	jmp 	.moveY

.moveYToBottom:
	CLEAR_SELECTION
	UPDATE_Y_POSITION $01, 0
	SETISAR 17
	lr 		A, S
	inc
	lr 		S, A
	SETISAR BLINK_COLOR
	li 		PLAYER2_COLOR
	lr 		S, A
	DRAW_SELECTION
	li		128
	lr 		5, A
	pi 		BIOS_DELAY
	jmp 	.moveY

.moveEnd:
	pi 		placeChipIfValid
	; change player turn
	SETISAR PLAYER_STATE
	lr 		A, S
	xi 		%00000001
	lr 		S, A

.aiNextMoveEnd:
    pi     kstack.pop
    pk