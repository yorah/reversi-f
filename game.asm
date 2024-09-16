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
; draw player turn
; draw current score
; IDEAS
; in draw board, use a subroutine to draw horizontal lines (need kstack)
 
    processor f8

; Include VES Header
	include "ves.h"

; Constants

; Registers used
INTERNAL_COUNTER 	= 30
PLAYER_TURN 		= 31
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

main.startgame.init:
	; init starting board state, clear r40-47 first
	clr
	lisu 	4
	lisl 	7
main.startgame.clearBoardBuffer4047:
	lr 		D, A
	br7 	main.startgame.clearBoardBuffer4047
	; clear r50-57
	lisu 	5
main.startgame.clearBoardBuffer5057:
	lr 		D, A
	br7 	main.startgame.clearBoardBuffer5057

main.startgame.drawScreen
	; draw board
	pi 		board.draw

	; draw sidebar
	pi 		sidebar.draw

	; draw players scores

	jmp 	main.startgame.drawScreen


;**********************y2j********************************************************
;* DRAW SIDEBAR
;******************************************************************************

sidebar.draw:
	lr 		K, P

	; blue color
	li 		$80
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
	dci gfx.turn.parameters
	pi blitGraphic

sidebar.drawEnd:
	pk

;**********************y2j********************************************************
;* DRAW BOARD
;******************************************************************************

board.draw:
	lr 		K, P

	; blue color
	li 		$80
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
	.byte $ff
