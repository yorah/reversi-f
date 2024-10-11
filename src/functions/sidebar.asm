;******************************************************************************
;* DRAW SIDEBAR
;******************************************************************************

SIDEBAR_LEFT_X    = 64
FIRST_HORIZONTAL_LINE_Y = 21
SECOND_HORIZONTAL_LINE_Y = 37

sidebar.draw
sidebar 	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	; blue color
	li 		BOARD_COLOR
	lr 		1, A
	; start from row 57 (bottom)
	li 		57
	lr 		3, A
.row.loop:
	; draw from column 101
	li		101
	lr		2, A
.column.loop:
	pi 		plot
	ds 		2		; move left
	lr		A, 2
	ci		SIDEBAR_LEFT_X		; check if we reached column 64
	bnz 	.column.loop
	ds 		3		; move up
	bc 		.row.loop

	; draw "Turn"
	dci 	gfx.turn.parameters
	pi 		blitGraphic

	; draw first horizontal line
    SIDEBAR_DRAW_HORIZONTAL_LINE FIRST_HORIZONTAL_LINE_Y
    SIDEBAR_DRAW_HORIZONTAL_LINE SECOND_HORIZONTAL_LINE_Y

	; draw "Score"
	dci 	gfx.score.parameters
	pi 		blitGraphic

.drawEnd:
	pi   kstack.pop
	pk


;******************************************************************************
;* SPRITE SKIP DRAWING
;******************************************************************************
; r0 = color 1
; r1 = color 2
; r2 = x position
; r3 = y position
;
; modifies: r1-r9 (through blit call)

skip.draw:
	DRAW_BLIT 16, 4


;******************************************************************************
;* UPDATE TURN IN SIDEBAR
;******************************************************************************
updateTurnInSidebar:
updateTurnInSidebar 	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	SETISAR PLAYER_STATE
	GET_PLAYER_TURN
	; update sidebar
	bnz 	.player2
	dci 	gfx.p1.parameters
	jmp 	.end
.player2:
	dci 	gfx.p2.parameters
.end
	pi 		blitGraphic
	pi 		setBlinkColorToPlayerColor

	pi  	kstack.pop
	pk

;******************************************************************************
;* UPDATE SCORE IN SIDEBAR
;******************************************************************************
updateScoreInSidebar:
updateScoreInSidebar 	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	DRAW_DIGIT PLAYER1_COLOR, 74, 1, PLAYER1_SCORE
	DRAW_DIGIT PLAYER1_COLOR, 78, 0, PLAYER1_SCORE

	DRAW_DIGIT PLAYER2_COLOR, 86, 1, PLAYER2_SCORE
	DRAW_DIGIT PLAYER2_COLOR, 90, 0, PLAYER2_SCORE

	pi   	kstack.pop
	pk
