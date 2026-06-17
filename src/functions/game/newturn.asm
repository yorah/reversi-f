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
	; store player turn in r7 for canPlayerMove/scanAllDirections
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
	xi 		PLAYER_STATE_TURN_MASK	; switch player turn
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
; modifies: r0-r25, r52 (through scanAllDirections call)
;
; returns in A: 1 if valid move found, 0 if not

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

	; check if current slot would be a valid move.
	; EXISTS mode (r6 = 2): scanAllDirections walks the 8 directions and
	; short-circuits, returning r10 = 1 on the first valid direction (else 0).
	lis 	2
	lr 		6, A
	pi 		scanAllDirections
	lr 		A, 10
	ci 		1
	bz 		canPlayerMove.validMoveFound

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
