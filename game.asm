;  ____                         _       _____ 
; |  _ \ _____   _____ _ __ ___(_)     |  ___|
; | |_) / _ \ \ / / _ \ '__/ __| |_____| |_   
; |  _ <  __/\ V /  __/ |  \__ \ |_____|  _|  
; |_| \_\___| \_/ \___|_|  |___/_|     |_|    
;
; A simple game for the VES written by Yorah, 2024
; Reversi was invented in 1883, and plays similarly to the
; trademarked game Othello.
;
; This game wouldn't have been possible without all information available
; on the veswiki, and inspiration from the examples there (especially the
; pacman port by Blackbird and e5frog).
;

; TODO
; draw current score
; check if no valid moves left? or if both pass, stop? How to pass?
;
; IMPROVEMENTS
;
; IDEAS FOR IMPROVEMENT
; decoupling of blinking and debouncing
; in draw board, use a subroutine to draw horizontal lines
; in draw selection, use subroutine to draw selection instead of macro
; animate pieces flipping
; use snail pattern to check if valid move exists (more efficient)
;
 
    processor f8

; Include VES Header
	include "ves.h"

; Constants
BLINK_LOOPS			= 12	; time to loop before changing color for blinking effect
BOARD_COLOR			= COLOR_BLUE		; board color
PLAYER1_COLOR		= COLOR_GREEN		; player 1 color
PLAYER2_COLOR		= COLOR_RED			; player 2 color
SKIP_COLOR			= COLOR_BACKGROUND	; color for skip text

; Registers used
SKIP_BLINK_COLOR	= 28	; color in use for skip blinking effect
BLINK_COLOR			= 29	; color in use for blinking effect
BLINK_COUNTER		= 30	; counter for blinking effect
PLAYER_STATE 		= 31	; first (higher) 3 bits are the X selection position
							; next 3 bits are the Y selection position
							; next 1 bit is the debounce flag (to prevent too fast input)
							; last bit is the player turn (0 = player 1, 1 = player 2)
BOARD_STATE 		= 32	; 16 bytes for the board state, ranging from r32 to r47
							; corresponding to ISAR 40-47 and 50-57


;******************************************************************************
;* CARTRIDGE INITIALIZATION
;******************************************************************************

    org	$0800

cartridge.start:
	CARTRIDGE_START
cartridge.init:
	CARTRIDGE_INIT


;******************************************************************************
;* GAME INITIALIZATION
;******************************************************************************

main:
	; initialize the kstack pointer
	li		62		; stack starts at r62
	lisu	7		; stack pointer is r63
	lisl	7
	lr		S, A

	; clear screen, colored background
	li		$d6		; $d6 gray - $c0 green - $21 b/w - $93 blue
	lr		3, A
	pi		BIOS_CLEAR_SCREEN


;******************************************************************************
;* NEW GAME
;******************************************************************************

	MAC DRAW_CHIP
		li 		$ff
		lr 		0, A		; store color 1 in r0 (for blit)
		li 		{1}
		lr 		1, A		; store color 2 in r1 (for blit)
		li 		{2}
		lr 		2, A		; store X in r2
		li		{3}
		lr 		3, A		; store Y in r3
		dci 	gfx.piece.data
		pi 		slot.draw
	ENDM

newgame.init:
	li 		BLINK_LOOPS
	SETISAR BLINK_COUNTER
	lr 		S, A
	
	li 		%01101100	; X=4, Y=4, player 1 starts
	SETISAR PLAYER_STATE
	lr		S, A

	clr
	; init starting board state, clear r40-45 first (46-47 will be updated
	; to place center pieces)
	lisu 	4
	lisl 	5
newgame.clearBoardBuffer4047:
	lr 		D, A
	br7 	newgame.clearBoardBuffer4047
	; clear r50-57
	lisu 	5
newgame.clearBoardBuffer5057:
	lr 		D, A
	br7 	newgame.clearBoardBuffer5057

newgame.drawScreen
	; draw board
	pi 		board.draw

	; draw sidebar
	pi 		sidebar.draw

	; init starting positions in BOARD_STATE
	; 1011 1110 in center
	lisu 	4
	lisl 	6
	li		%10000000
	lr		S, A
	lisl	7
	lis		3
	lr		S, A
	lisu	5
	lisl	0
	li      %11000000
	lr 		S, A
	lisl	1
	lis 	2
	lr		S, A

	; draw corresponding center chips
	; top left
	DRAW_CHIP PLAYER1_COLOR, 25, 22
	; bottom right
	DRAW_CHIP PLAYER1_COLOR, 32, 28
	; top right
	DRAW_CHIP PLAYER2_COLOR, 32, 22
	; bottom left
	DRAW_CHIP PLAYER2_COLOR, 25, 28

	; init sidebar (player turn)
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000001
	bnz 	.initSidebarPlayer2
	dci 	gfx.p1.parameters
	pi 		blitGraphic
	jmp 	.initSidebarEnd
.initSidebarPlayer2:
	dci 	gfx.p2.parameters
	pi 		blitGraphic
.initSidebarEnd:

	jmp	game.loop

newgame.loop.end:
	jmp newgame.init


;******************************************************************************
;** PLAYER_STATE MACROs
;******************************************************************************
	; SETISAR PLAYER_STATE must be called before using these macros
	; returns the position in A
	MAC GET_X_POSITION
		lr 		A, S
		ni 		%11100000	; get X position
		sr 		4
		sr 		1
	ENDM
	
	; SETISAR PLAYER_STATE must be called before using these macros
	; returns the position in A
	MAC GET_Y_POSITION
		lr 		A, S
		ni 		%00011100	; get Y position
		sr 		1
		sr 		1
	ENDM

	; SETISAR PLAYER_STATE must be called before using these macros
	; returns the player turn in A
	MAC GET_PLAYER_TURN
		lr 		A, S
		ni 		%00000001	; get player turn
	ENDM

;******************************************************************************
;* PLAY GAME
;******************************************************************************

	MAC CLEAR_SELECTION
		SETISAR BLINK_COLOR
		li 		BOARD_COLOR
		lr 		S, A

		SETISAR BLINK_COUNTER
		li 		BLINK_LOOPS
		lr 		S, A

		DRAW_SELECTION

		SETISAR SKIP_BLINK_COLOR
		li 		BOARD_COLOR
		lr 		S, A

		DRAW_SKIP
	ENDM

	MAC DRAW_SELECTION
		li 		$ff
		lr 		0, A
		SETISAR BLINK_COLOR
		lr 		A, S
		lr 		1, A
		; calculate X position
		SETISAR PLAYER_STATE
		lr 		A, S
		ni 		%11100000
		sr		4
		sr	    1
		com
		ai 		1
		lr		2, A
		lr 		A, S
		ni 		%11100000
		sr 		1
		sr 		1
		as 		2
		ai 		4
		lr 		2, A		; store X-screen in r2

		; calculate Y position
		lr 		A, S
		ni 		%00011100
		sr		1			; Y*2 (sr2 + sl1)
		com
		ai 		1			; two complement to get -2Y
		lr		3, A		; store -2Y in r3
		lr 		A, S
		ni 		%00011100
		sl 		1			; Y*8 (sr2 + sl3)
		as 		3			; Y*8 - 2Y = 6Y
		ai 		4			; Add top offset
		lr 		3, A		; store Y-screen in r3	
		dci		gfx.slotSelection.data
		pi slot.draw
	ENDM

	MAC DRAW_SKIP
		li 		$ff
		lr 		0, A
		SETISAR SKIP_BLINK_COLOR
		lr 		A, S
		lr 		1, A
		; X position
		li 		76
		lr 		2, A		; store X-screen in r2
		; Y position
		li 		15
		lr 		3, A		; store Y-screen in r3	
		dci		gfx.skip.data
		pi skip.draw
	ENDM

	MAC UPDATE_Y_POSITION
		SETISAR PLAYER_STATE
		lr 		A, S
		ni		%00011100
		sr		1
		sr		1
		ai 		{1}
		ni 		%00000111
		sl 		1
		sl 		1
		lr 		0, A	; store new Y position
		lr		A, S
		ni 		%11100011	; clear Y position
		xs		0
		lr		S, A
		lis 	0		; no chip placed
		lr 		0, A
		jmp game.loop.handleInput.end
	ENDM

	MAC UPDATE_X_POSITION
		SETISAR PLAYER_STATE
		lr 		A, S
		ni		%11100000
		sr		4
		sr		1
		ai 		{1}
		ni 		%00000111
		sl 		4
		sl 		1
		lr 		0, A	; store new Y position
		lr		A, S
		ni 		%00011111	; clear Y position
		xs		0
		lr		S, A
		lis 	0		; no chip placed
		lr 		0, A
		jmp game.loop.handleInput.end
	ENDM

game.loop:
gameloop	SUBROUTINE

.nextPlayerTurn:
	; check if player can move
	pi 		game.loop.canPlayerMove
	ci 		0
	lis 	0
	lr 		11, A	; r11 flags if we processed the next player turn
	bz 		.playerHasToSkip
	lis 	0
	SETISAR 12
	lr 		S, A	; no skip turn
	jmp 	.slotSelection.draw

.playerHasToSkip:
	li 		SKIP_COLOR
	SETISAR SKIP_BLINK_COLOR
	lr 		S, A

	lis 	1
	SETISAR 12
	lr 		12, A	; r12 used to flag if player has to skip turn, 1 = yes

.draw.loop:
	SETISAR 12
	lr 		A, S
	ci 		1
	bnz 	.slotSelection.draw
.skip.draw:
	DRAW_SKIP

.slotSelection.draw:
	DRAW_SELECTION

.blinkDelay:
	; delay for blinking effect
	li		$08
	lr 		5, A
	pi 		BIOS_DELAY

.readController:
	; if debounce flag is set, wait for it to be cleared
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000010
	bnz 	.readController.skip

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
	
.readController.skip:
	jmp 	.blink.check

.handleInput:
	; clear previous selection (using r10 is ok?)
	lr 		10, A
	CLEAR_SELECTION
	lr 		A, 10

	; button pressed
	ni 		%00001111
	bz 		.handleInput.buttonPressed
	; test up direction
	ni 		%00000111
	bz 		.handleInput.up
	; test down direction
	ni		 %00000011
	bz 		.handleInput.down
	; test left direction
	ni 		%00000001
	bz 		.handleInput.left
	; right direction (only one left, and we know something was pressed)
	jmp 	.handleInput.right

.handleInput.buttonPressed:
	SETISAR 12
	lr 		A, S
	ci 		1
	bz      .updatePlayerTurnBranch
	jmp .handleInput.buttonPressed.placeChip
.updatePlayerTurnBranch:
	; set debounce flag to prevent too fast input
	SETISAR PLAYER_STATE
	lr 		A, S
	oi 		%00000010
	lr 		S, A

	jmp 	.updatePlayerTurn

.handleInput.buttonPressed.placeChip:
	pi 		game.loop.placeChipIfValid
	lr 		11, A
	jmp 	game.loop.handleInput.end
.handleInput.up:
	UPDATE_Y_POSITION $ff
.handleInput.down:
	UPDATE_Y_POSITION $01
.handleInput.left:
	UPDATE_X_POSITION $ff
.handleInput.right:
	UPDATE_X_POSITION $01

game.loop.handleInput.end:
	; set debounce flag to prevent too fast input
	SETISAR PLAYER_STATE
	lr 		A, S
	oi 		%00000010
	lr 		S, A

	jmp .blink.switchToPlayerColor

.blink.check:
	SETISAR	BLINK_COUNTER
	ds		S
	bz		.blink.switchColor
	jmp 	.blinkDelay

.blink.switchColor:
	; reset blink_counter to blink_loops count
	; relies on SETISAR BLINK_COUNTER being called prior to this
	li 		BLINK_LOOPS
	lr 		S, A

	; clear debounce flag
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%11111101
	lr 		S, A

	SETISAR BLINK_COLOR
	lr 		A, S
	ci 		BOARD_COLOR
	bz		.blink.switchToPlayerColor	; switch to player color
	li 		BOARD_COLOR	; else switch to clear blinking color (blue, as the board is blue)
	lr 		S, A
	SETISAR SKIP_BLINK_COLOR
	lr 		S, A
	jmp 	.draw.loop

.blink.switchToPlayerColor:
	SETISAR SKIP_BLINK_COLOR
	li 		SKIP_COLOR
	lr 		S, A
	SETISAR PLAYER_STATE
	GET_PLAYER_TURN
	bnz 	.blink.switchToPlayerColor.player2
	li 		PLAYER1_COLOR
	br 		.blink.switchToPlayerColor.end
.blink.switchToPlayerColor.player2:
	li 		PLAYER2_COLOR
.blink.switchToPlayerColor.end:
	SETISAR BLINK_COLOR
	lr 		S, A

	lr 		A, 11
	ci 		0	; check if chip was placed
	bz 		.noChipPlaced

.updatePlayerTurn
	; change player turn
	SETISAR PLAYER_STATE
	lr 		A, S
	xi 		%00000001
	lr 		S, A

	; update sidebar
	ni 		%00000001
	bnz 	.updateSidebarPlayer2
	dci 	gfx.p1.parameters
	pi 		blitGraphic
	jmp 	.updateSidebarEnd
.updateSidebarPlayer2:
	dci 	gfx.p2.parameters
	pi 		blitGraphic
.updateSidebarEnd:

	jmp 	.nextPlayerTurn
.noChipPlaced:
	jmp 	.draw.loop

game.loop.end:
	jmp newgame.loop.end

;******************************************************************************
;* CAN PLAYER MOVE (CHECK IF VALID MOVES LEFT FOR CURRENT PLAYER)
;******************************************************************************
; Tries to flip chips in a direction, and calls placeChip if it finds any
;
; modifies: r0-r26 (through flipChipsInDirection call)
;
; returns in A: 1 if valid move found, 0 if not

	MAC IS_VALID_MOVE_FOUND
		lr 		A, 6
		ci 		1
		bz 		game.loop.canPlayerMove.validMoveFound
	ENDM

game.loop.canPlayerMove:
canPlayerMove 	SUBROUTINE

	lr 		K, P
	pi      kstack.push

	; prepare return value
	lis 	0
	lr 		10, A	; store 0 in r10 to indicate no valid move found by default

	; Set initial X and Y to 7
	lis 	7
	lr    	0, A	; store 7 in r0, initial X=7
	lr 		1, A	; store 7 in r1, initial Y=7

	; store player turn in r7 for flipChipsInDirection
	SETISAR PLAYER_STATE
	GET_PLAYER_TURN
	lr 		7, A	; store player turn in r7	

.loopX:
	pi 		getSlotContent

	; check if slot is empty
	ni 		%00000011
	bnz 	.noValidMove

	; DEBUG Uncomment line below to test no valid moves behavior
	jmp .noValidMove

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
	
	; if we went so far, no valid move yet
	jmp .noValidMove

game.loop.canPlayerMove.validMoveFound:
	lis 	1
	lr 		10, A	; store 1 in r10 to indicate valid move found
	jmp game.loop.canPlayerMove.end

.noValidMove:
	; continue looping to find if there is a valid move

	ds 		0		; decrement X
	lr 		A, 0
	ci      $ff
	bnz		.loopBack	; loop until X=0 
	lis 	7
	lr 		0, A	; store 7 in r10, initial X=7
	ds 		1		; decrement Y
	lr 		A, 1
	ci 		$ff
	bnz     .loopBack	; loop until Y=0
	jmp game.loop.canPlayerMove.end

.loopBack:
	jmp .loopX	; Branching too far, need to use jmp
	
game.loop.canPlayerMove.end:

	pi 		kstack.pop
	lr 		A, 10
	pk

;******************************************************************************
;* PLACE CHIP IF VALID MOVE
;******************************************************************************

game.loop.placeChipIfValid:
placeChipIfValid 	SUBROUTINE

	lr 		K, P
	pi      kstack.push

	; prepare return value
	lis     0
	SETISAR 16
	lr 		S, A	; use r16 to indicate if chip was placed (0 = no, 1 = yes)

game.loop.placeChipIfValid.isSlotEmpty:
	; calculate index of wanted move
	SETISAR PLAYER_STATE
	GET_X_POSITION
	lr 		0, A		; store X in r0
	GET_Y_POSITION
	lr 		1, A		; store Y in r1
	GET_PLAYER_TURN
	lr 		7, A		; store player turn in r7
	
	pi 		getSlotContent

	; check if slot is empty
	ni 		%00000011
	bnz 	.slotNotEmpty
	jmp game.loop.placeChipIfValid.hasChipsToFlip

.slotNotEmpty:
	; slot is not empty, do nothing
	; TODO play bad sound?
	jmp 	game.loop.placeChipIfValid.end

game.loop.placeChipIfValid.hasChipsToFlip:
	; r0 and r1 are still the X and Y positions
	; r2 and r3 are the slot register and bit position
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
	SETISAR 16
	lr 		S, A
	bz 		game.loop.placeChipIfValid.end	; no chip placed, r6 still 0

	lis 	1
	SETISAR 16
	lr 		S, A	; store 1 in r16 to indicate move was valid

game.loop.placeChipIfValid.end:

	pi 		kstack.pop
	SETISAR 16
	lr 		A, S 	; r16 will either be set to 1 if chip was placed, or 0 if not
	pk

;******************************************************************************
;* FLIP CHIPS IN DIRECTION
;******************************************************************************
; Tries to flip chips in a direction, and calls placeChip if it finds any
; r0 = initial X position
; r1 = initial Y position
; r2 = slot register number (used to call placeChip)
; r3 = slot bit position (used to call placeChip)
; r4 = X direction
; r5 = Y direction
; r6 = call place chip if zero; only do checks if 2; if 1, avoid calling placeChip multiple times but flip chips
; r7 = player turn (used to check if slot is player 1 or player 2)
;
; modifies: r4-r5, r7-r9 (through placeChip call; r7 not modified if only checking)
;			r0-r1 are preserved, r2-r3 too if needed, r6 returned)
;			r16-r26 (used to preserve params)
; returns in r6: 1 if placechip was called, or if r6 was 1 initially, to avoid calling it multiple times.
;	Also serves to know if move was deemed valid, as it will be 0 if no chips were flipped on this direction
;   or on previous directions checked

	MAC PRESERVE_PARAM
		SETISAR {2}
		lr 		A, {1}
		lr 		S, A
	ENDM
	MAC RESTORE_PARAM
		SETISAR {2}
		lr 		A, S
		lr 		{1}, A
	ENDM
	
flipChipsInDirection:
flipChipsInDirection	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	; preserve parameters passed
	PRESERVE_PARAM 0, 16
	PRESERVE_PARAM 1, 17
	PRESERVE_PARAM 2, 18
	PRESERVE_PARAM 3, 19
	PRESERVE_PARAM 4, 20
	PRESERVE_PARAM 5, 21
	PRESERVE_PARAM 6, 22
	PRESERVE_PARAM 7, 23
	
	lis 	0
	lr 		9, a		; store 0 in r9 (used to track if opponents chips were found)

	; move to next slot to check
	; get new X
flipChipsInDirection.loop:
	lr		A, 0	; load X position
	as	  	4		; add X direction
	ci		8		; check if we reached the end of the board
	bz		.noChipsToFlip
	ci		$ff		; check if we reached the beginning of the board
	bz 		.noChipsToFlip
	lr 		0, A    ; store new X position in r0

	; get new Y
	lr		A, 1	; load Y position
	as		5		; add Y direction
	ci		8		; check if we reached the end of the board
	bz		.noChipsToFlip
	ci		$ff		; check if we reached the beginning of the board
	bz		.noChipsToFlip
	lr		1, A	; store new Y position in r1
	br		.checkSlotContent

.noChipsToFlip:
	jmp 	flipChipsInDirection.end

.checkSlotContent:
	pi 		getSlotContent
	lr 		8, A	; store slot content in r8
	RESTORE_PARAM 2, 18
	RESTORE_PARAM 3, 19
	RESTORE_PARAM 4, 20

	lr 		A, 8	; load slot content

	ni 	%00000011	; check if slot is empty
	bz 	.noChipsToFlip	; if slot is empty, no chips to flip

	; branching depending on which player is playing
	lr 		A, 7
	ni 		%00000001
	bz 		.checkPlayer1
.checkPlayer2:
	lr 		A, 8	; load slot content
	ci 		%00000010	; check if slot is player 1
	bz      .checkSlotContent.opponentChipsFound
	br      .checkSlotContent.ownChipsFound
.checkPlayer1
	lr 		A, 8	; load slot content
	ci 		%00000011	; check if slot is player 2
	bz      .checkSlotContent.opponentChipsFound
	br      .checkSlotContent.ownChipsFound
.checkSlotContent.opponentChipsFound:
	lr 		A, 9	; load previous chips found
	inc
	lr 		9, A	; store new chips found
	jmp flipChipsInDirection.loop
.checkSlotContent.ownChipsFound:
	lr 		A, 9	; load previous opponents chips found
	ni 		%11111111
	bz      .checkSlotContent.noChipsToFlip	; if no opponents chips were found, no chips to flip
	; chips to flip...
	jmp 	.flipChipsInDirection.flipChips
.checkSlotContent.noChipsToFlip:
	jmp 	.noChipsToFlip

.flipChipsInDirection.flipChips:
	lr 		A, 6	; load call place chip if zero
	ni 		%11111111
	RESTORE_PARAM 0, 16	; restore initial X
	RESTORE_PARAM 1, 17	; restore initial Y
	bz 		.flipChipsInDirection.callPlaceChip
	lr 		A, 6	; are we only checking, and not placing?
	ci 		2
	bz 		.flipChipsInDirection.validMoveExists	; if so, no need to place chip
	jmp 	.flipChipsInDirection.flipChips.loop
.flipChipsInDirection.validMoveExists:
	lis 	1
	lr 		6, A	; store 1 to mark valid move
	jmp 	flipChipsInDirection.end
.flipChipsInDirection.callPlaceChip:
	PRESERVE_PARAM 9, 24	; preserve r9 to avoid losing it when calling placeChip
	pi      placeChip
	RESTORE_PARAM 0, 16 ; restore initial X
	RESTORE_PARAM 1, 17 ; restore initial Y
	RESTORE_PARAM 4, 20 ; restore r4 and r5 lost when calling placeChip
	RESTORE_PARAM 5, 21
	RESTORE_PARAM 7, 23
	RESTORE_PARAM 9, 24	; restore r9
	lis 	1
	lr 		6, A	; store 1 in r6 to avoid calling placeChip multiple times
	PRESERVE_PARAM 6, 22	; preserve r6
.flipChipsInDirection.flipChips.loop:
	lr		A, 0	; load X position
	as	  	4		; add X direction
	lr 		0, A    ; store new X position in r0
	PRESERVE_PARAM 0, 25	; preserve new X

	; get new Y
	lr		A, 1	; load Y position
	as		5		; add Y direction
	lr		1, A	; store new Y position in r1
	PRESERVE_PARAM 1, 26	; preserve new Y

	; call getSlotContent to retrieve register number and bit position to update
	pi 		getSlotContent
	RESTORE_PARAM  4, 20

	PRESERVE_PARAM 9, 24	; preserve r9 to avoid losing it when calling placeChip
	pi 		placeChip
	RESTORE_PARAM  0, 25
	RESTORE_PARAM  1, 26
	RESTORE_PARAM  4, 20
	RESTORE_PARAM  5, 21
	RESTORE_PARAM  6, 22
	RESTORE_PARAM  7, 23
	RESTORE_PARAM  9, 24	; restore r9

	ds 		9		; decrement number of chips to flip
	bnz 	.flipChipsInDirection.flipChips.loop	; loop until all chips are flipped

flipChipsInDirection.end:
	RESTORE_PARAM 0, 16	; restore initial X
	RESTORE_PARAM 1, 17	; restore initial Y
	pi      kstack.pop
	pk

;******************************************************************************
;* PLACE CHIP
;******************************************************************************
; Updates the BOARD_STATE register with the new piece, and
; draws it on the screen
; r0 = X position
; r1 = Y position
; r2 = slot register number
; r3 = slot bit position
;
; modifies: r1-r9 (through blit call)
; returns nothing of interest

placeChip:
placeChip	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	; place chip on empty slot
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000001
	bnz 	.setBitPlayer2
	li 	    PLAYER1_COLOR
	lr      5, A 		; store color in r5 for later
	li 		%00000010	; set bit to 10 for player 1
	br 	.setBitEnd
.setBitPlayer2:
	li 		PLAYER2_COLOR
	lr 		5, A 		; store color in r5 for later
	li 		%00000011	; set bit to 11 for player 2
.setBitEnd:
	lr 		4, A		; store bit in r4
	lis 	3			; store %00000011 in A
	lr 		7, A		; store dynamic mask in r7
	lr 		A, 3		; load bit position
	lr 		6, A		; store bit position in r6 to create dynamic mask later
	ni 		%11111111	; check if bit position is zero, in which case no need to shift
	lr 		A, 7		; load dynamic mask from r7
	bz	 	.noShift
	lr 		A, 4		; load bit from r4
.loopShift:	
	sl		1			; shift to get the bit in the right position
	ds		3			; count number of bits to offset
	bnz		.loopShift
	lr 		4, A		; store new slot in r4
	lr 		A, 7		; load dynamic mask from r7
.loopShiftDynamicMask:
	sl 		1			; shift to get the bit in the right position
	ds      6			; count number of bits to offset
	bnz	 	.loopShiftDynamicMask
.noShift:
	com
	lr 		7, A		; store dynamic mask in r7

	lr 		A, 2		; load register number from r2
	lr 		IS, A		; set ISAR to the register number
	lr 		A, S		; load byte from BOARD_STATE
	ns 		7			; clear the slot (2 bits) to set
	lr 		S, A
	lr 		A, 4		; load new slot
	xs 		S 			; set the slot

	lr 		S, A		; save board state register updated

placeChip.draw:
	; calculate X position
	lr 		A, 0
	com
	ai 		1
	lr		2, A
	lr 		A, 0
	sl 		1
	sl 		1
	sl 		1
	as 		2
	ai 		4
	lr 		2, A		; store X in r2

	; calculate Y position
	lr 		A, 1
	sl		1
	com
	ai 		1
	lr		3, A
	lr 		A, 1
	sl 		1
	sl 		1
	sl 		1
	as 		3
	ai 		4
	lr 		3, A		; store Y in r3

	; set background color, $ff being transparent color
	li 		$ff
	lr 		0, A		; store color 1 in r0 (for blit)
	; set color based on current player
	lr 		A, 5
	lr 		1, A		; store color 2 in r1 (for blit)

	dci 	gfx.piece.data
	pi 		slot.draw

	pi	 	kstack.pop
	pk


;******************************************************************************
;* GET SLOT CONTENT
;******************************************************************************
; Get the content of a slot from BOARD_STATE
; r0 = X position
; r1 = Y position
;
; modifies: r2, r3, r4
; returns content in A, slot register in r2, and slot bit position in r3

getSlotContent:
getSlotContent	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	; calculate register number
	lr 		A, 1 	; load Y position
	sl 		1		; multiply by 8
	sl 		1
	sl 		1
	as 	    0		; add X to Y*8 to get index of slot to test
	lr 		2, A	; store index in r2

	ni 		%00000011	; find remainder of division by 4	
	sl 		1		; multiply by 2 to get the bit position
	lr 		3, A	; store bit position in r3
	lr 		4, A	; store bit position in r4

	lr 		A, 2
	sr 		1		; divide by 4 to find register (each byte stores 4 slots of 2 bits)
	sr 		1
	ai 		BOARD_STATE	; add 32 to get the register number
	lr 		2, A	; store register number in r2

	lr 		A, 4	; load bit position from r4
	ni 		%11111111	; check if byte is zero, in which case no need to shift
	lr		A, 2	; load register number from r2
	lr		IS, A	; set ISAR to the register number
	lr		A, S	; load byte from BOARD_STATE
	bz	 	.noShift
.loopShift:
	sr		1			; shift to get the bit in the right position
	ds		4			; count number of bits to offset
	bnz		.loopShift
.noShift
	ni 		%00000011	; mask out the 2 bits we want to check/flip
	lr      4, A   		; store the content in r4

	pi 		kstack.pop
	lr 		A, 4		; return content in A
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
	; blit reference:
	; r1 = color 1 (off)
	; r2 = color 2 (on)
	; r3 = x position
	; r4 = y position
	; r5 = width
	; r6 = height

	li	 	16
	lr 		5, A
	lis 	4
	lr 		6, A
	; position
	lr 		A, 3
	lr 		4, A
	lr 		A, 2
	lr 		3, A
	; colors
	lr 		A, 1
	lr 		2, A
	lr		A, 0
	lr		1, A
	
	; draw skip
	jmp 	blit


;******************************************************************************
;* SPRITE SLOT DRAWING
;******************************************************************************
; r0 = color 1
; r1 = color 2
; r2 = x position
; r3 = y position
;
; modifies: r1-r9 (through blit call)

slot.draw:
	; blit reference:
	; r1 = color 1 (off)
	; r2 = color 2 (on)
	; r3 = x position
	; r4 = y position
	; r5 = width
	; r6 = height

	lis 	8
	lr 		5, A
	lis 	7
	lr 		6, A
	; position
	lr 		A, 3
	lr 		4, A
	lr 		A, 2
	lr 		3, A
	; colors
	lr 		A, 1
	lr 		2, A
	lr		A, 0
	lr		1, A
	
	; draw slot
	jmp 	blit


;******************************************************************************
;* DRAW SIDEBAR
;******************************************************************************

sidebar.draw:
	lr 		K, P

	; blue color
	li 		BOARD_COLOR
	lr 		1, A

	; start from row 57 (bottom)
	li 		57
	lr 		3, A
sidebar.draw.row.loop:
	; draw from column 101
	li		101
	lr		2, A
sidebar.draw.column.loop:
	pi 		plot
	ds 		2		; move left
	lr		A, 2
	ci		64		; check if we reached column 64
	bnz 	sidebar.draw.column.loop
	ds 		3		; move up
	bc 		sidebar.draw.row.loop

	; draw "Turn"
	dci 	gfx.turn.parameters
	pi 		blitGraphic

sidebar.drawEnd:
	pk


;******************************************************************************
;* DRAW BOARD
;******************************************************************************

board.draw:
	lr 		K, P

	; blue color
	li 		BOARD_COLOR
	lr 		1, A

	; draw top line, starting from middle (55 width)
	li 		28
	lr 		4, A
	; used to draw from middle (substraction 57-x)
	li 		57
	lr 		5, A

board.draw.topAndBottomLines.loop:
	lr 		A, 4
	ai		4
	lr 		2, A

	; y = 4
	lis		4
	lr 		3, A
	pi		plot
	; y = 52
	li		52
	lr		3, A
	pi		plot

	; draw from middle, right
	; calculate symmetric number by doing 55-r4 (r5-r4)
	lr 		A, 4
	com
	ai		1
	as		5
	ai		4
	lr 		2, A
	pi		plot

	lis		4
	lr 		3, A
	pi		plot

	ds 		4
	bz 		board.draw.vertLines

	li		$ff
board.draw.topAndBottomLines.delay
	ai		$ff
	bnz		board.draw.topAndBottomLines.delay

	br 		board.draw.topAndBottomLines.loop

board.draw.vertLines:
	; plot missing left pixels from top/bottom
	lis 	4
	lr 		2, A
	lis 	4
	lr 		3, A
	pi 		plot

	li 		52
	lr 		3, A
	pi 		plot

	; init variables for vertical lines
	; first x position, to draw from vertical middle
	li 		28
	lr 		4, A	; left side
	lr 		5, A	; right side

	; first y position (r6 top, r7 bottom)
	lis 	5
	lr 		6, A
	li 		56
	lr 		7, A

	; counter to draw horizontal line every 6 vertical pixels
	lis 	6
	lr 		9, A

	; used to draw horizontal line, starting from middle (55 width)
	li 		28
	lr 		10, A
	; used to draw from middle (substraction 57-x)
	li 		57
	lr 		11, A

board.draw.vertLines.loop:
	lr 		A, 6
	lr 		3, A

	lr 		A, 4
	ai		4
	lr 		2, A
	pi 		plot

	lr 		A, 6
	com
	ai 		1
	as 		7
	lr 		3, A
	pi 		plot

	lr 		A, 5
	ai		4
	lr 		2, A
	pi 		plot

	lr 		A, 6
	lr 		3, A
	pi 		plot	

	lr 		A, 5
	ai		7
	lr 		5, A
	; burns my eyes
	ds		4
	ds		4
	ds		4
	ds		4
	ds		4
	ds		4
	ds		4
	bz 		board.draw.vertLines.checkHorizontalLine
	jmp 	board.draw.vertLines.loop

board.draw.vertLines.checkHorizontalLine:
	ds		9
	bz 		board.draw.vertLines.horizontalLine

	jmp 	board.draw.vertLines.nextLine

board.draw.vertLines.horizontalLine:
	lr 		A, 10
	ai		4
	lr 		2, A

	; top side
	lr 		A, 6
	lr 		3, A
	pi		plot
	; bottom side
	lr 		A, 6
	com
	ai 		1
	as 		7
	lr 		3, A
	pi		plot

	; draw from middle, right
	; calculate symmetric number by doing 57-r4 (r11-r4)
	lr 		A, 10
	com
	ai		1
	as		11
	ai		4
	lr 		2, A
	pi		plot

	lr 		A, 6
	lr 		3, A
	pi		plot

	ds 		10
	bnz 	board.draw.vertLines.horizontalLine
	lis 	6
	lr 		9, A
	li 		28
	lr 		10, A

board.draw.vertLines.nextLine:
	; left side
	lr 		A, 6
	lr 		3, A

	lis 	4
	lr 		2, A
	pi 		plot

	; right side
	li 		60
	lr 		2, A
	pi 		plot

	lr 		A, 6
	com
	ai 		1
	as 		7
	lr 		3, A
	pi 		plot

	; left side bottom
	lis 	4
	lr 		2, A
	pi 		plot

	lr 		A, 6
	inc
	lr 		6, A

	; check if we reached middle of vertical lines
	ci 		29
	bz 		board.drawEnd

	li 		28
	lr 		4, A
	lr 		5, A

	li		$ff
board.draw.vertLines.delay
	ai		$ff
	bnz		board.draw.vertLines.delay

	jmp 	board.draw.vertLines.loop

board.drawEnd:
	pk


;******************************************************************************
;* INCLUDES
;******************************************************************************
	; k stack functions
	include "kstack.inc"
	
	; drawing subroutines
	include "drawing.inc"

	; graphics data
	include "graphics.inc"

; Padding
	org $fff
	.byte "yorah 2024"
