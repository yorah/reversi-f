;******************************************************************************
;* NEW TURN HANDLER
;******************************************************************************
; This routine is called at the beginning of a new turn. It checks if the
; current player has a valid move. If not, it checks if the next player has a
; valid move. If not, the game is over.
;
; modifies: r0, r7 (and a lot of other registers in canPlayerMove)
; Sets the TURN_STATE to the corresponding value (player had to skip, player can play, gameover)

newturn:
newturn     SUBROUTINE
    lr     K, P
    pi     kstack.push

    ; 1. check if current player has a valid move
	; store player turn in r7 for canPlayerMove/flipChipsInDirection
	SETISAR PLAYER_STATE
	GET_PLAYER_TURN
	lr 		7, A	; store player turn in r7	

	; check if player can move, A will be 1 if player can move, 0 if not
	pi 		canPlayerMove
	ci 		0
	bz 		.playerHasToSkip
	UPDATE_TURN_STATE	CURRENT_PLAYER_CAN_MOVE	; player has valid move
    jmp    .newturnEnd

.playerHasToSkip:
	; if current player has to skip, check if next player has a valid move
	; if not, that means end of game
	lr      A, 7    ; get player turn
	xi 		%00000001	; switch player turn
	lr 		7, A	; store next player turn in r7	

	; check if next player can move
	pi 		canPlayerMove
	ci 		0
	bnz 	.nextPlayerHasMove

	UPDATE_TURN_STATE	GAME_OVER	; game over
	jmp    .newturnEnd

.nextPlayerHasMove:
	; next player has a valid move, so current player has to skip
	; init SKIP_COLOR
	li 		SKIP_COLOR
	SETISAR SKIP_BLINK_COLOR
	lr 		S, A

	UPDATE_TURN_STATE	CURRENT_PLAYER_HAS_TO_SKIP	; player has to skip

.newturnEnd:
    pi 		kstack.pop
    pk


;******************************************************************************
;* CAN PLAYER MOVE (CHECK IF VALID MOVES LEFT FOR CURRENT PLAYER)
;******************************************************************************
; Check if there is a valid move on the board for the player set in r7
;
; modifies: r0-r26 (through flipChipsInDirection call)
;
; returns in A: 1 if valid move found, 0 if not

	MAC IS_VALID_MOVE_FOUND
		lr 		A, 6
		ci 		1
		bz 		canPlayerMove.validMoveFound
	ENDM

canPlayerMove:
canPlayerMove 	SUBROUTINE

	lr 		K, P
	pi      kstack.push

	; Set initial X and Y to 7
	lis 	7
	lr    	0, A	; store 7 in r0, initial X=7
	lr 		1, A	; store 7 in r1, initial Y=7

.loopX:
	pi 		getSlotContent

	; check if slot is empty, if not, continue to next slot
	ni 		%00000011
	bnz 	.noValidMove

	; check if current slot would be a valid move
	lis 	2		; r6 set to 2, will be set to 1 if chip placed; only set on first direction checked
	lr 		6, A
	; test right direction
	lis 	1
	lr 		4, A
	lis 	0
	lr 		5, A
	pi 		flipChipsInDirection
	IS_VALID_MOVE_FOUND
	; test right-up diagonal
	lis 	1
	lr 		4, A
	li  	$ff
	lr 		5, A
	pi 		flipChipsInDirection
	IS_VALID_MOVE_FOUND
	; test up direction
	lis 	0
	lr 		4, A
	li	 	$ff
	lr 		5, A
	pi 		flipChipsInDirection
	IS_VALID_MOVE_FOUND
	; test left-up diagonal
	li	 	$ff
	lr 		4, A
	li	 	$ff
	lr 		5, A
	pi 		flipChipsInDirection
	IS_VALID_MOVE_FOUND
	; test left direction
	li 		$ff
	lr 		4, A
	lis	 	0
	lr 		5, A
	pi 		flipChipsInDirection
	IS_VALID_MOVE_FOUND
	; test left-down diagonal
	li 		$ff
	lr 		4, A
	lis	 	1
	lr 		5, A
	pi 		flipChipsInDirection
	IS_VALID_MOVE_FOUND
	; test down direction
	lis 	0
	lr 		4, A
	lis	 	1
	lr 		5, A
	pi 		flipChipsInDirection
	IS_VALID_MOVE_FOUND
	; test down-right diagonal
	lis 	1
	lr 		4, A
	lis	 	1
	lr 		5, A
	pi 		flipChipsInDirection
	IS_VALID_MOVE_FOUND

.noValidMove:
	; continue looping to find if there is a valid move
	ds 		0		; decrement X
	lr 		A, 0
	ci      $ff
	bnz		.loopBack	; loop until X=0 
	lis 	7
	lr 		0, A	; store 7 in r10, initial X=7 (to check next line)
	ds 		1		; decrement Y
	lr 		A, 1
	ci 		$ff
	bnz     .loopBack	; loop until Y=0
	; if we went so far, no valid move found
	lis 	0
	lr 		10, A
	jmp 	.canPlayerMoveEnd

.loopBack:
	jmp 	.loopX	; Branching too far, need to use jmp

canPlayerMove.validMoveFound:
	lis 	1
	lr 		10, A	; store 1 in r10 to indicate valid move found
	jmp 	.canPlayerMoveEnd
	
.canPlayerMoveEnd:
	pi 		kstack.pop
	lr 		A, 10
	pk
