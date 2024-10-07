;******************************************************************************
;* HANDLE INPUT
;******************************************************************************
; Handles input, and setups the return value for the input.actions JMP Table,
; which will do the actual action based on the input.
;
; Returns in A (used for input.actions JMP Table):
;   0 if no button pressed/debounce in progress
;   1 if button pressed, and current player has to skip
;   2 if button pressed, and current player places a chip
;   3 if up direction
;   4 if down direction
;   5 if left direction
;   6 if right direction

handleInput:
handleInput     SUBROUTINE
    lr      K, P
    pi      kstack.push

    ; if debounce flag is set, wait for it to be cleared
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000010
	bnz 	.skip

	clr
	outs 	0		; enable input from controllers (related to bit6 of port0?)
	outs	1		; clear port1 (right controller	)
	ins   	1		; read right controller first (requires half the CPU cycles than reading left controller on port 4 
	com				; invert bits, so that 1 means button pressed
	ni 		%10001111	; mask out twists and pullup
	bnz 	.handleInput	; if button pressed, no need to read other controller	
	outs 	4		; clear port4 (left controller)
	ins  	4		; read left controller
	com				; invert bits, so that 1 means button pressed
	ni 		%10001111	; mask out twists and pullup
	bnz 	.handleInput	; if button pressed, no need to read other controller
	
.skip
    MAP_ACTION_RETURN 0, handleInputEnd

.handleInput:
	; reset selection/skip colors/timers (provides a nice feedback to the player that
    ; his input was registered). We have to use r10 as r0-r9 are used in CLEAR_SELECTION
    ; by the blitGraphic routine
	lr 		10, A   ; save A in r10 (contains the input value)
	CLEAR_SELECTION

    ; set debounce flag to prevent too fast input
	SETISAR PLAYER_STATE
	lr 		A, S
	oi 		%00000010
	lr 		S, A
	lr 		A, 10   ; restore A from r10 (to the input value)

	; button pressed
	ni 		%00001111
	bz 		.buttonPressed
	; test up direction
	ni 		%00000111
	bz 		.up
	; test down direction
	ni		 %00000011
	bz 		.down
	; test left direction
	ni 		%00000001
	bz 		.left
	; right direction (only one direction left, which is the right one, and we know something was pressed)
	jmp 	.right

.buttonPressed:
    ; button pressed can either be a "Skip" (if player had no valid move), or a "Place chip"
	GET_TURN_STATE
	ci 		CURRENT_PLAYER_HAS_TO_SKIP
	bz      .updatePlayerTurnBranch
	jmp     .placeChip

.updatePlayerTurnBranch:
	MAP_ACTION_RETURN 1, handleInputEnd
.placeChip:
	MAP_ACTION_RETURN 2, handleInputEnd

.up:
	MAP_ACTION_RETURN 3, handleInputEnd
.down:
	MAP_ACTION_RETURN 4, handleInputEnd
.left:
	MAP_ACTION_RETURN 5, handleInputEnd 
.right:
	MAP_ACTION_RETURN 6, handleInputEnd
 
handleInputEnd:
    pi 		kstack.pop
    lr      A, 0
    pk