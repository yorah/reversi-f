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
; place piece, check if valid move (all directions)
; check if no valid moves left? or if both pass, stop? How to pass?

; IMPROVEMENTS
; decoupling of blinking and debouncing

; IDEAS
; in draw board, use a subroutine to draw horizontal lines (need kstack)
; in draw selection, use subroutine to draw selection instead of macro (need kstack)
; animate pieces flipping
;
; WTF moments
; JMP does modify the accumulator (as stated by the doc, should have read it more carefully)
 
    processor f8

; Include VES Header
	include "ves.h"

; Constants
BLINK_LOOPS			= 12	; time to loop before changing color for blinking effect
BOARD_COLOR			= COLOR_BLUE		; board color
PLAYER1_COLOR		= COLOR_GREEN		; player 1 color
PLAYER2_COLOR		= COLOR_RED			; player 2 color


; Registers used

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
	; clear screen, colored background
	li		$c6		; $d6 gray - $c0 green - $21 b/w - $93 blue
	lr		3, A
	pi		BIOS_CLEAR_SCREEN


;******************************************************************************
;* NEW GAME
;******************************************************************************

newgame.init:
	li 		BLINK_LOOPS
	SETISAR BLINK_COUNTER
	lr 		S, A
	
	li 		%01101100	; X=4, Y=4, player 1 starts
	SETISAR PLAYER_STATE
	lr		S, A

	clr
	; init starting board state, clear r40-47 first
	lisu 	4
	lisl 	7
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

	; init sidebar
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000001
	bnz 	newgame.drawScreen.initSidebar.player2
	dci 	gfx.p1.parameters
	pi 		blitGraphic
	jmp 	newgame.drawScreen.initSidebar.end
newgame.drawScreen.initSidebar.player2:
	dci 	gfx.p2.parameters
	pi 		blitGraphic
newgame.drawScreen.initSidebar.end:

	jmp	game.loop

newgame.loop.end:
	jmp newgame.init


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
	lr 		2, A		; store X in r2

	; calculate Y position
	lr 		A, S
	ni 		%00011100
	sr		1
	com
	ai 		1
	lr		3, A
	lr 		A, S
	ni 		%00011100
	sl 		1
	as 		3
	ai 		4
	lr 		3, A		; store Y in r3	
	dci		gfx.slotSelection.data
	pi slot.draw
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
	jmp game.loop.handleInput.end
	ENDM

game.loop:

game.loop.slotSelection:
	DRAW_SELECTION

game.loop.slotSelection.blinkDelay:
	; delay for blinking effect
	li		$08
	lr 		5, A
	pi 		BIOS_DELAY

game.loop.readController:
	; if debounce flag is set, wait for it to be cleared
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000010
	bnz 	game.loop.readController.skip

	clr
	outs 	0		; enable input from controllers (related to bit6 of port0?)
	outs	1		; clear port1 (right controller	)
	ins   	1		; read right controller first (requires half the CPU cycles than reading left controller on port 4 
	com				; invert bits, so that 1 means button pressed
	ni 		%10001111	; mask out twists and pullup
	bnz 	game.loop.handleInput	; if button pressed, no need to read other controller	
	outs 	4		; clear port4 (left controller)
	ins  	4		; read left controller
	com				; invert bits, so that 1 means button pressed
	ni 		%10001111	; mask out twists and pullup
	bnz 	game.loop.handleInput	; if button pressed, no need to read other controller
	
game.loop.readController.skip:
	jmp 	game.loop.blink.check

game.loop.handleInput:
	; clear previous selection (should we use r10, or is it reserved for something else?)
	lr 		10, A
	CLEAR_SELECTION
	lr 		A, 10

	; button pressed
	ni %00001111
	bz game.loop.handleInput.placePiece
	; test up direction
	ni %00000111
	bz game.loop.handleInput.up
	; test down direction
	ni %00000011
	bz game.loop.handleInput.down
	; test left direction
	ni %00000001
	bz game.loop.handleInput.left
	; right direction (only one left, and we know something was pressed)
	jmp game.loop.handleInput.right

game.loop.handleInput.placePiece:
	jmp game.loop.placePiece
game.loop.handleInput.up:
	UPDATE_Y_POSITION $ff
game.loop.handleInput.down:
	UPDATE_Y_POSITION $01
game.loop.handleInput.left:
	UPDATE_X_POSITION $ff
game.loop.handleInput.right:
	UPDATE_X_POSITION $01

game.loop.handleInput.end:
	; set debounce flag to prevent too fast input
	SETISAR PLAYER_STATE
	lr 		A, S
	oi 		%00000010
	lr 		S, A

	jmp game.loop.blink.switchToPlayerColor

game.loop.blink.check:
	SETISAR	BLINK_COUNTER
	ds		S
	bz		game.loop.blink.switchColor
	jmp 	game.loop.slotSelection.blinkDelay

game.loop.blink.switchColor:
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
	bz		game.loop.blink.switchToPlayerColor	; switch to player color
	li 		BOARD_COLOR	; else switch to clear blinking color (blue, as the board is blue)
	lr 		S, A
	jmp 	game.loop.slotSelection

game.loop.blink.switchToPlayerColor:
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000001
	bnz 	game.loop.blink.switchToPlayerColor.player2
	li 		PLAYER1_COLOR
	br 		game.loop.blink.switchToPlayerColor.end
game.loop.blink.switchToPlayerColor.player2:
	li 		PLAYER2_COLOR
game.loop.blink.switchToPlayerColor.end:
	SETISAR BLINK_COLOR
	lr 		S, A
	jmp 	game.loop.slotSelection

game.loop.end:
	jmp newgame.loop.end

;******************************************************************************
;* PLACE PIECE
;******************************************************************************

game.loop.placePiece:
game.loop.placePiece.checkIfSlotEmpty:
	; calculate index of wanted move
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00011100	; get Y position
	sl 		1			; multiply by 8 (2 sr 1 and 3 sl 1)
	lr 		0, A		; store Y*8 in r0
	lr 		A, S
	ni 		%11100000	; get X position
	sr 		4
	sr 		1
	as 		0			; add Y*8+X to get index of wanted move
	lr 		0, A		; store index in r0

	; calculate which register of BOARD_STATE to access
	sr 		1			; divide by 4 to find register (each byte stores 4 slots of 2 bits)
	sr 		1
	ai		BOARD_STATE	; add 32 to get the register number
	lr 		IS, A 		; set ISAR to the register number
	lr  	4, A		; store register number in r4

	; extract 2 bits from the register
	lr		A, 0		; get index of wanted move
	ni		%00000011	; find remainder of division by 4
	sl		1			; multiply by 2 to get the bit position
	lr 		1, A		; store bit position in r1
	lr 		2, A		; store bit position in r2 (to put it back later)

	ni 		%11111111	; check if byte is zero, no need to shift
	lr 		A, S		; load byte from register
	bz	 	game.loop.placePiece.bitOffset.end
game.loop.placePiece.bitOffset:
	sr		1			; shift to get the bit in the right position
	ds		1			; count number of bits to offset
	bnz		game.loop.placePiece.bitOffset
game.loop.placePiece.bitOffset.end:

	ni 		%00000011	; mask out the 2 bits we want to change

	; check if slot is empty
	bnz 	game.loop.placePiece.slotNotEmpty
	jmp game.loop.placePiece.checkValidMove

game.loop.placePiece.slotNotEmpty:
	; slot is not empty, do nothing
	; TODO play bad sound?
	jmp 	game.loop.placePiece.end

game.loop.placePiece.checkValidMove:
	; TODO check valid moves

game.loop.placePiece.actual:
	; slot is empty, and move is valid, place piece
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000001
	bnz 	game.loop.placePiece.actual.player2
	li 		%00000010	; set bit to 1 for player 1
	br 	game.loop.placePiece.actual.end
game.loop.placePiece.actual.player2:
	li 		%00000011	; set bit to 1 for player 2
game.loop.placePiece.actual.end:
	lr 		3, A		; store bit in r3
	lr 		A, 2		; load bit position
	ni 		%11111111	; mask out the bit we want to change
	lr 		A, 3		; load bit
	bz	 	game.loop.placePiece.shiftBitBack.end
game.loop.placePiece.shiftBitBack:	
	sl		1			; shift to get the bit in the right position
	ds		2			; count number of bits to offset
	bnz		game.loop.placePiece.shiftBitBack
game.loop.placePiece.shiftBitBack.end:
	lr 		3, A		; store new byte in r3

	lr 		A, 4	; load register number from r4
	lr 		IS, A	; set ISAR to the register number
	lr 		A, 3	; load new byte
	xs		S		; xor with the mask to set the bit
	lr 		S, A	; store xored new byte in register

	; and now draw the piece
	jmp 	game.loop.placePiece.draw

game.loop.placePiece.draw:
	li 		$ff
	lr 		0, A
	; set color based on current player
	SETISAR PLAYER_STATE
	lr 		A, S
	ni 		%00000001
	bnz 	game.loop.placePiece.draw.setColor.player2
	li 		PLAYER1_COLOR
	jmp 	game.loop.placePiece.draw.setColor.end
game.loop.placePiece.draw.setColor.player2:
	li 		PLAYER2_COLOR
game.loop.placePiece.draw.setColor.end:
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
	lr 		2, A		; store X in r2

	; calculate Y position
	lr 		A, S
	ni 		%00011100
	sr		1
	com
	ai 		1
	lr		3, A
	lr 		A, S
	ni 		%00011100
	sl 		1
	as 		3
	ai 		4
	lr 		3, A		; store Y in r3
	dci 	gfx.piece2.data
	pi 		slot.draw

game.loop.changePlayer:
	; change player turn
	SETISAR PLAYER_STATE
	lr 		A, S
	xi 		%00000001
	lr 		S, A

	; update sidebar
	ni 		%00000001
	bnz 	game.loop.changePlayer.updateSidebar.player2
	dci 	gfx.p1.parameters
	pi 		blitGraphic
	jmp 	game.loop.changePlayer.updateSidebar.end
game.loop.changePlayer.updateSidebar.player2:
	dci 	gfx.p2.parameters
	pi 		blitGraphic
game.loop.changePlayer.updateSidebar.end:

game.loop.placePiece.end:
	jmp game.loop.handleInput.end

;******************************************************************************
;* SPRITE SLOT DRAWING
;******************************************************************************
; r0 = color 1
; r1 = color 2
; r2 = x position
; r3 = y position

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
	; drawing subroutines
	include "drawing.inc"

	; graphics data
	include "graphics.inc"

; Padding
	org $fff
	.byte "yorah 2024"
