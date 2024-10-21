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

	GET_GAMEMODE
	ci  	GAMEMODE_QUICKGAME
	bz 		.bo1Check

	ci 		GAMEMODE_BO3
	bz 		.bo3Check
	br 		.bo5Check
.bo1Check:
	; check if match is over
	lis 	0
	lr 		11, A
	SETISAR GAME_SCORE
	lr 		A, S
	ni 		%00001111	; maskout P1 score, only keep P2 score
	ci 		%00000001	; check if P2 score is 1, in which case P2 won the match
	bz 		.p2WinsMatch
	lr 		A, S
	ni 		%11110000	; maskout P2 score, only keep P1 score
	ci 		%00010000	; check if P1 score is 1, in which case P1 won the match
	bz 		.p1WinsMatch
	lis 	1
	lr 		11, A
	jmp 	.waitButtonPress
.bo5Check:
	; check if match is over
	lis 	0
	lr 		11, A
	SETISAR GAME_SCORE
	lr 		A, S
	ni 		%00001111	; maskout P1 score, only keep P2 score
	ci 		%00000011	; check if P2 score is 3, in which case P2 won the match
	bz 		.p2WinsMatch
	lr 		A, S
	ni 		%11110000	; maskout P2 score, only keep P1 score
	ci 		%00110000	; check if P1 score is 3, in which case P1 won the match
	bz 		.p1WinsMatch
	lis 	1
	lr 		11, A
	jmp 	.waitButtonPress
.bo3Check:
	; check if match is over
	lis 	0
	lr 		11, A
	SETISAR GAME_SCORE
	lr 		A, S
	ni 		%00001111	; maskout P1 score, only keep P2 score
	ci 		%00000010	; check if P2 score is 2, in which case P2 won the match
	bz 		.p2WinsMatch
	lr 		A, S
	ni 		%11110000	; maskout P2 score, only keep P1 score
	ci 		%00100000	; check if P1 score is 2, in which case P1 won the match
	bz 		.p1WinsMatch
	lis 	1
	lr 		11, A
	jmp 	.waitButtonPress

.p1WinsMatch:
	dci 	gfx.p1winsmatch.parameters
	pi 		blitGraphic
	jmp 	.waitButtonPress
.p2WinsMatch:
	; display AI or P2 wins
	GET_AI
	bz 		.p2WinsMatchDisplay
	dci 	gfx.aiwinsmatch.parameters
	pi 		blitGraphic
	jmp 	.waitButtonPress
.p2WinsMatchDisplay:
	dci 	gfx.p2winsmatch.parameters
	pi 		blitGraphic
	jmp 	.waitButtonPress

.waitButtonPress:
	WAIT_BUTTON_PRESS	%01000000, 1

.gameoverEnd:
    pi 		kstack.pop
	lr		A, 11
    pk