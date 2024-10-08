;******************************************************************************
;* NEWGAME INITIALIZATION
;******************************************************************************

newgame.init:
newgameInit 	SUBROUTINE
    lr 		K, P
    pi      kstack.push

.setRegistersForNewGame:
    ; reset blink counter to BLINK_LOOPS
	SET_BLINKING_COUNTER BLINK_LOOPS

	; reset BLINK_COLOR to player1
	li    	PLAYER1_COLOR
	SETISAR BLINK_COLOR
	lr		S, A
	
    ; reset PLAYER_STATE
	li		%01101100	; X=4, Y=4, player 1 starts
	SETISAR PLAYER_STATE
	lr		S, A

	; reset scores (both players start at 2)
	lis 	2
	SETISAR PLAYER1_SCORE
	lr		S, A
	SETISAR PLAYER2_SCORE
	lr 		S, A

	; clear BOARD_STATE
    li      BOARD_STATE
.clearBoardStateLoop:
    lr      IS, A
    clr
    lr 		S, A
    lr      A, IS
	inc
    ci      $30
    bnz     .clearBoardStateLoop

	; init starting positions in BOARD_STATE
	; 1011 1110 in center
    ; P1 chips
	li		%10000000
	SETISAR 38
	lr		S, A
	lis 	%00000010
	SETISAR 41
	lr		S, A
	; P2 chips
    lis     %00000011
	SETISAR 39
	lr 		S, A
	li 	 	%11000000
	SETISAR 40
	lr		S, A

.drawGameSurface:
	li 		COLOR_BACKGROUND
	lr 		1, A
	pi      clearscreen

	; draw board
	pi 		board.draw

	; draw sidebar
	pi 		sidebar.draw

	; draw center chips
	; top left
	DRAW_CHIP PLAYER1_COLOR, 25, 22, COLOR_TRANSPARENT
	; bottom right
	DRAW_CHIP PLAYER1_COLOR, 32, 28, COLOR_TRANSPARENT
	; top right
	DRAW_CHIP PLAYER2_COLOR, 32, 22, COLOR_TRANSPARENT
	; bottom left
	DRAW_CHIP PLAYER2_COLOR, 25, 28, COLOR_TRANSPARENT

	; init sidebar (player turn)
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000001
	bnz 	.initSidebarPlayer2
	dci 	gfx.p1.parameters
	jmp 	.initSidebarEnd
.initSidebarPlayer2:
	dci 	gfx.p2.parameters
.initSidebarEnd:
	pi 		blitGraphic

.newgameEnd:
    pi 		kstack.pop
    pk
