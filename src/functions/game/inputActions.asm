;******************************************************************************
;* INPUT ACTIONS
;******************************************************************************
; This file contains the actions that are executed based on the input.

inputPlaceChip:
	pi 		placeChipIfValid
	ci 		0
	bnz 	.updatePlayerTurnJmp
    MAP_ACTION_RETURN 0, handleInput.continuations
.updatePlayerTurnJmp:
	jmp 	updatePlayerTurn

moveUp:
	CLEAR_SELECTION
	UPDATE_Y_POSITION $ff, 1
moveDown:
	CLEAR_SELECTION
	UPDATE_Y_POSITION $01, 1
moveLeft:
	CLEAR_SELECTION
	UPDATE_X_POSITION $ff, 1
moveRight:
	CLEAR_SELECTION
	UPDATE_X_POSITION $01, 1

noInput:
    MAP_ACTION_RETURN 1, handleInput.continuations

updatePlayerTurn
	; change player turn
	SETISAR PLAYER_STATE
	lr 		A, S
	xi 		%00000001
	lr 		S, A

    MAP_ACTION_RETURN 2, handleInput.continuations

;******************************************************************************
;* PLACE CHIP IF VALID MOVE
;******************************************************************************
; This routine is called when the player tries to place a chip. It checks if
; the move is valid, and if so, places the chip and flips the necessary chips.
; The checks and the flipping are done at the same time, meaning that if at the
; end of all directions tests no chips were flipped, the move is invalid and the
; chip is not placed.
;
; Returns in A: 1 if chip was placed, 0 if not
; Modified registers: r0-r6, r10, and all registers modified by flipChipsInDirection

placeChipIfValid:
placeChipIfValid 	SUBROUTINE

	lr 		K, P
	pi      kstack.push

	; prepare return value
	lis     0
	lr 		10, A	; use r16 to indicate if chip was placed (0 = no, 1 = yes)

placeChipIfValid.isSlotEmpty:
	; calculate index of wanted move
	SETISAR PLAYER_STATE
	GET_X_POSITION
	lr 		0, A		; store X in r0
	GET_Y_POSITION
	lr 		1, A		; store Y in r1
	GET_PLAYER_TURN
	lr 		7, A		; store player turn in r7

	; check if slot is empty
	pi 		getSlotContent
	ni 		%00000011
	bnz 	.slotNotEmpty
	jmp placeChipIfValid.hasChipsToFlip

.slotNotEmpty:
	; slot is not empty, do nothing
	jmp 	placeChipIfValid.end

placeChipIfValid.hasChipsToFlip:
	; r0 and r1 are still the X and Y positions
	; r2 and r3 are the slot register and bit position (after calling getSlotContent)
	lis 	0		; r6 set to zero, will be set to 1 if chip placed; only set on first direction checked
	lr 		6, A
	; test right direction
	lis 	1
	lr 		4, A
	lis 	0
	lr 		5, A
	pi 		flipChipsInDirection
	; test right-up diagonal
	lis 	1
	lr 		4, A
	li  	$ff
	lr 		5, A
	pi 		flipChipsInDirection
	; test up direction
	lis 	0
	lr 		4, A
	li	 	$ff
	lr 		5, A
	pi 		flipChipsInDirection
	; test left-up diagonal
	li	 	$ff
	lr 		4, A
	li	 	$ff
	lr 		5, A
	pi 		flipChipsInDirection
	; test left direction
	li 		$ff
	lr 		4, A
	lis	 	0
	lr 		5, A
	pi 		flipChipsInDirection
	; test left-down diagonal
	li 		$ff
	lr 		4, A
	lis	 	1
	lr 		5, A
	pi 		flipChipsInDirection
	; test down direction
	lis 	0
	lr 		4, A
	lis	 	1
	lr 		5, A
	pi 		flipChipsInDirection
	; test down-right diagonal
	lis 	1
	lr 		4, A
	lis	 	1
	lr 		5, A
	pi 		flipChipsInDirection

	; check if move was valid and chip was placed
	lr 		A, 6
	ni 		%11111111
	SETISAR 10
	lr 		S, A
	bz 		placeChipIfValid.end	; no chip placed, r6 still 0

	lis 	1
	lr 		10, A	; store 1 in r10 to indicate move was valid

placeChipIfValid.end:
	pi 		kstack.pop
	lr 		A, 10 	; r10 will either be set to 1 if chip was placed, or 0 if not
	pk
