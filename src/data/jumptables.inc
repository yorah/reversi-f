;---------------------------------------------------------------------------
; JMP Table used to triggers actions related to input
;---------------------------------------------------------------------------

; JMP used to act on the different inputs
input.actions:
	jmp 	noInput
	jmp 	updatePlayerTurn
	jmp 	inputPlaceChip
	jmp		moveUp
	jmp		moveDown
	jmp 	moveLeft
	jmp		moveRight

; JMP used to continue after acting on the different inputs
; the input.actions above must set A accordingly to the continuation they want/need
input.actions.continuations:
    jmp     resetBlinkColor.continue
    jmp     blink.continue
    jmp     game.loop