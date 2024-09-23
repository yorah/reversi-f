;******************************************************************************
;* GAME OVER HANDLER
;******************************************************************************
; routine called when the game is over.
;
; In Bo3 gamemode, this routine will update match score and check if the match is over.
; It will also display the end of the match.
; In Bo1 gamemode, this routine only displays the winner and wait for a console button
; to be pressed


gameover:
gameover    SUBROUTINE
    lr     K, P
    pi     kstack.push

	; game over, show winner
	SETISAR PLAYER2_SCORE
	lr 		A, S
	com
	ai 		1
	SETISAR PLAYER1_SCORE
	as	    S

    ; if 0, scores are equal, so it's a draw
	bz .draw
    ; if player 1 score > player 2 score, player 1 wins
	bp 		.player1Wins

.player2Wins:    
	dci 	gfx.p2wins.parameters
    br      .blitAndWait
.draw:
	dci 	gfx.draw.parameters
    br      .blitAndWait
.player1Wins:
	dci 	gfx.p1wins.parameters
.blitAndWait:    
	pi 		blitGraphic

.waitButtonPress:
	; wait for button press
    clr
    outs    0
	ins     0
    com
    ni      %00001000   ; check if button 4 (Start) is pressed
    bz   .waitButtonPress

.gameoverEnd:
    pi 		kstack.pop
    pk