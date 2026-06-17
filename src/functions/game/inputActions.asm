;******************************************************************************
;* INPUT ACTIONS
;******************************************************************************
; This file contains the actions that are executed based on the input.

inputPlaceChip:
	pi 		placeChipIfValid
	ci 		0
	bnz 	.updatePlayerTurnJmp

	INVALID_MOVE_SOUND

    MAP_ACTION_RETURN 0, handleInput.continuations
.updatePlayerTurnJmp:
	jmp 	updatePlayerTurn

; VERIFIED: no fall-through. The `,1` final arg makes each UPDATE_*_POSITION macro
; emit MAP_ACTION_RETURN, which ends in `jmp handleInput.continuations` (see input.h /
; playerstate.h). So each handler terminates with a jmp; control never falls into the next.
moveUp:
	pi 		moveDecorum
	UPDATE_Y_POSITION $ff, 1
moveDown:
	pi 		moveDecorum
	UPDATE_Y_POSITION $01, 1
moveLeft:
	pi 		moveDecorum
	UPDATE_X_POSITION $ff, 1
moveRight:
	pi 		moveDecorum
	UPDATE_X_POSITION $01, 1

noInput:
    MAP_ACTION_RETURN 1, handleInput.continuations

updatePlayerTurn
	; change player turn
	SETISAR PLAYER_STATE
	lr 		A, S
	xi 		PLAYER_STATE_TURN_MASK
	lr 		S, A

    MAP_ACTION_RETURN 2, handleInput.continuations


;******************************************************************************
;* Stuff done when moving the cursor (audio, graphics...)
;******************************************************************************
moveDecorum:
moveDecorum 	SUBROUTINE

	lr 		K, P
	pi      kstack.push

	CLEAR_SELECTION

	MOVE_SOUND

.moveDecorumEnd:
	pi 		kstack.pop
	pk


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
; Modified registers: r0-r6, r10, and all registers modified by scanAllDirections

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
	; PLACE mode (r6 = 0): scanAllDirections walks all 8 directions, placing the
	; chip and flipping captured lines, and returns r10 = 1 if at least one
	; direction was valid (chip placed), or 0 if the move was invalid.
	lis 	0
	lr 		6, A
	pi 		scanAllDirections
	; scanAllDirections already returns r10 = 1 if a chip was placed, 0 otherwise,
	; which is exactly this routine's return value.

placeChipIfValid.end:
	pi 		kstack.pop
	lr 		A, 10 	; r10 will either be set to 1 if chip was placed, or 0 if not
	pk
