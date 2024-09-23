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
; on the VES Wiki, and inspiration from the examples there (especially the
; pacman port by Blackbird and e5frog).
;

; TODO
; draw current score
;
; IDEAS FOR IMPROVEMENT
; decoupling of blinking and debouncing (is it really necessary? Use wait-for-release from e5frog maybe?)
; in draw selection, use subroutine to draw selection instead of macro (is it really necessary?)
; animate pieces flipping
; use snail pattern to check if valid move exists (more efficient)
; play "bad" sound if invalid move
;
 
    processor f8

; Include VES Header
	include "src/ves.h"

; Include macros
	include "src/macros/input.h"
	include "src/macros/general.h"
	include "src/macros/draw.h"
	include "src/macros/playerstate.h"
	include "src/macros/gamestate.h"

; Configuration
GAME_SIZE 			= 4		; size in KB
BLINK_DELAY			= $08		; delay for blinking effect (delay is actually delay * loops)
BLINK_LOOPS			= %00001100	; time to loop before changing color for blinking effect
BOARD_COLOR			= COLOR_BLUE		; board color
PLAYER1_COLOR		= COLOR_GREEN		; player 1 color
PLAYER2_COLOR		= COLOR_RED			; player 2 color
SKIP_COLOR			= COLOR_BACKGROUND	; color for skip text

; Registers used
SKIP_BLINK_COLOR	= 28	; color in use for skip blinking effect
BLINK_COLOR			= 29	; color in use for blinking effect
GAME_STATE			= 30	; holds the counter for blinking effect (selection
							; and skip text) in the low bits
							; also holds the turn state in the 2 high bits
							; 00 player can play, 01 player has to skip, 10 game over
PLAYER_STATE 		= 31	; first (higher) 3 bits are the X selection position
							; next 3 bits are the Y selection position
							; next 1 bit is the debounce flag (to prevent too fast input)
							; last bit is the player turn (0 = player 1, 1 = player 2)
BOARD_STATE 		= 32	; 16 bytes for the board state, ranging from r32 to r47
							; corresponding to ISAR 40-47 and 50-57
PLAYER1_SCORE		= 48	; player 1 score
PLAYER2_SCORE		= 49	; player 2 score


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
	; call it before initializing kstack, as it makes use of the builtin stack
	li		$d6		; $d6 gray - $c0 green - $21 b/w - $93 blue
	lr		3, A
	pi		BIOS_CLEAR_SCREEN

	; initialize the kstack pointer
	li	62		; stack starts at r62
	lisu	7	; stack pointer is r63
	lisl	7
	lr		S, A

;******************************************************************************
;* TITLE SCREEN
;******************************************************************************
; displays the titlescreen
; there could be options to choose from here (1 game, best of 3, 1p or 2p, etc)
; for now, just a simple titlescreen, and then start a new game

titlescreen:
	pi		titlescreen.draw


;******************************************************************************
;* NEW GAME INITIALIZATION
;******************************************************************************

newgame:
	pi 		newgame.init

	jmp		game.loop

newgame.end:
	jmp 	newgame


;******************************************************************************
;* PLAY GAME
;******************************************************************************

game.loop:
gameloop	SUBROUTINE

	;-----------------------
	;--- Handle new turn ---
	pi 		newturn

	GET_TURN_STATE
	ci 		GAME_OVER
	bz 		.gameOver	; game over, jump to game over screen

	;--------------------------------------
	;--- Update sidebar (between turns) ---
	pi 		updateSidebar
	jmp 	.draw.loop	; jump to draw loop

	;-----------------
	;--- Game over ---
.gameOver:
	pi    	gameover
	jmp 	game.loop.end

	;-----------------
	;--- Draw loop ---
.draw.loop:
	GET_TURN_STATE
	ci 		CURRENT_PLAYER_CAN_MOVE
	bz		.slotSelection.draw
.skip.draw:
	DRAW_SKIP
.slotSelection.draw:
	DRAW_SELECTION

.blinkDelay.loop:	; delay for blinking effect
	li		BLINK_DELAY
	lr 		5, A
	pi 		BIOS_DELAY

	;--------------------
	;--- Handle input ---
	pi 		handleInput
	JMP_TABLE input.actions

handleInput.continuations:
	lr 		A, 0
	JMP_TABLE input.actions.continuations

resetBlinkColor.continue:
	pi 		setBlinkColorToPlayerColor
	jmp 	.handleInputEnd

blink.continue:
	pi 		blinkUpdate
	jmp 	.handleInputEnd
	; TODO: call blinkdelay drectly if blink_counter is not yet to 0 (no need to redraw)

.handleInputEnd:
	GET_BLINKING_COUNTER
	ci		BLINK_LOOPS		; check if we need to switch color
	bz	 	.loop.draw
	jmp 	.blinkDelay.loop
.loop.draw:
	jmp 	.draw.loop

game.loop.end:
	jmp newgame.end


;******************************************************************************
;* INCLUDE FUNCTIONS
;******************************************************************************
	; include functions
	include "src/functions/board.asm"
	include "src/functions/sidebar.asm"
	include "src/functions/titlescreen.asm"
	include "src/functions/newgame.asm"

	; include game functions
	include "src/functions/game/newturn.asm"
	include "src/functions/game/gameover.asm"
	include "src/functions/game/handleInput.asm"
	include "src/functions/game/inputActions.asm"
	include "src/functions/game/blink.asm"
	include "src/functions/game/boardManipulation.asm"


;******************************************************************************
;* INCLUDE LIBS
;******************************************************************************
	; kstack functions
	include "src/libs/kstack.inc"
	
	; drawing subroutines
	include "src/libs/drawing.inc"

	; graphics data
	include "src/data/graphics.inc"

	; jump tables
	include "src/data/jumptables.inc"

; Padding
	org $800 + (GAME_SIZE * $400) - $16
	.byte "yorah 2024"
