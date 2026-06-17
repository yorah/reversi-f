;******************************************************************************
;* GAME OVER HANDLER
;******************************************************************************
; routine called when the game is over.
;
; In Bo3 gamemode, this routine will update match score and check if the match is over.
; It will also display the end of the match.
; In QuickGame (Bo1) gamemode, this routine only displays the winner and wait for a console button
; to be pressed
;
; In case match keeps going, returns 1 in A, 0 otherwise


gameover:
gameover    SUBROUTINE
    lr     K, P
    pi     kstack.push


	; game over, find winner
	SETISAR PLAYER2_SCORE
	lr 		A, S
	ni 		%11110000	; mask for high nibble
	sr 		4
	lr 		3, A

	SETISAR PLAYER1_SCORE
	lr 		A, S
	ni      %11110000	; mask for high nibble
	sr 		4
	com
	ai 		1
	as 		3

	bm 		.player1Wins
	bz 		.compareLowNibble
	jmp 	.player2Wins

.compareLowNibble:
	SETISAR PLAYER2_SCORE
	lr 		A, S
	ni 		%00001111	; mask for low nibble
	lr 		3, A

	SETISAR PLAYER1_SCORE
	lr 		A, S
	ni      %00001111	; mask for low nibble
	com
	ai 		1
	as 		3

	bm 		.player1Wins
	bz 		.draw
	jmp 	.player2Wins

.player2Wins:    
	SETISAR GAME_SCORE	; increase gamescore
	lis 	1
	ai 		$66
	asd		S
	lr 		S, A
	dci 	gfx.p2wins.parameters
    br      .blitAndWait
.draw:
	dci 	gfx.draw.parameters
    br      .blitAndWait
.player1Wins:
	SETISAR GAME_SCORE	; increase gamescore
	li 	%00010000
	ai 		$66
	asd		S
	lr 		S, A
	dci 	gfx.p1wins.parameters
.blitAndWait:    
	pi 		blitGraphic

	pi  	updateBoScoreInSidebar

	; check if match is over. The required number of round wins equals
	; (gamemode + 1): quickgame(0)->1, Bo3(1)->2, Bo5(2)->3. The P2 win
	; threshold lives in the low nibble of GAME_SCORE, the P1 threshold in
	; the high nibble (= P2 threshold << 4). Derive both from the gamemode
	; instead of duplicating one check block per mode.
	GET_GAMEMODE			; A = gamemode (0/1/2)
	inc 					; A = round wins needed (1/2/3) = P2 threshold
	lr 		1, A			; r1 = P2 threshold (low nibble)
	sl 		4				; A = threshold << 4 = P1 threshold
	lr 		2, A			; r2 = P1 threshold (high nibble)

	lis 	0
	lr 		11, A			; default: match over
	SETISAR GAME_SCORE
	lr 		A, S
	ni 		%00001111		; maskout P1 score, only keep P2 score
	xs 		1				; equal to P2 threshold? (Z set if so)
	bz 		.p2WinsMatchJmp	; P2 won the match
	lr 		A, S
	ni 		%11110000		; maskout P2 score, only keep P1 score
	xs 		2				; equal to P1 threshold? (Z set if so)
	bz 		.p1WinsMatch	; P1 won the match
	lis 	1
	lr 		11, A			; match continues
	jmp 	.waitButtonPress

.p2WinsMatchJmp:
	jmp     .p2WinsMatch

.p1WinsMatch:
	dci 	gfx.p1winsmatch.parameters
	pi 		blitGraphic
	WINNING_SOUND 0
	jmp 	.waitButtonPress
.p2WinsMatch:
	; display AI or P2 wins
	GET_AI
	bz 		.p2WinsMatchDisplay
	dci 	gfx.compwinsmatch.parameters
	pi 		blitGraphic
	WINNING_SOUND 1
	jmp 	.waitButtonPress
.p2WinsMatchDisplay:
	dci 	gfx.p2winsmatch.parameters
	pi 		blitGraphic
	WINNING_SOUND 0
	jmp 	.waitButtonPress

.waitButtonPress:
	WAIT_BUTTON_PRESS	%01000000, 1

.gameoverEnd:
    pi 		kstack.pop
	lr		A, 11
    pk