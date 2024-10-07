;******************************************************************************
;* Blink color management
;******************************************************************************

blinkUpdate:
blinkUpdate     SUBROUTINE
    lr     K, P
    pi     kstack.push

    DECREASE_BLINKING_COUNTER
	ci		0
	bz 		.switchColor
    jmp     .blinkUpdateEnd
	;jmp 	blinkDelay.loop

.switchColor:
	; reset the blinking counter to blink_loops count
	SET_BLINKING_COUNTER BLINK_LOOPS

	; clear debounce flag (debounce delay is linked to blinking delay at the moment)
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%11111101
	lr 		S, A

	SETISAR BLINK_COLOR
	lr 		A, S
	ci 		BOARD_COLOR
	bz		.resetBlinkColor	; switch to player color
	li 		BOARD_COLOR	; else switch to clear blinking color (blue, as the board is blue)
	lr 		S, A
	SETISAR SKIP_BLINK_COLOR	 ; also set the skip color to the clear blinking color
	lr 		S, A
	jmp 	.blinkUpdateEnd

.resetBlinkColor:
	pi  	setBlinkColorToPlayerColor

.blinkUpdateEnd:
    pi     kstack.pop
    pk


setBlinkColorToPlayerColor:
setBlinkColorToPlayerColor  SUBROUTINE
    lr     K, P
    pi     kstack.push

	; skip color is not player dependent, so set it to the solid one
	SETISAR SKIP_BLINK_COLOR
	li 		SKIP_COLOR
	lr 		S, A
	
	SETISAR PLAYER_STATE
	GET_PLAYER_TURN
	bnz 	.player2
	li 		PLAYER1_COLOR
	br 		.end
.player2:
	li 		PLAYER2_COLOR
.end:
	SETISAR BLINK_COLOR
	lr 		S, A

    pi      kstack.pop
    pk