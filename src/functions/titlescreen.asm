;******************************************************************************
;* DRAW TITLE SCREEN
;******************************************************************************

titlescreen.draw
titlescreenDraw 	SUBROUTINE
	lr 		K, P
	pi	  	kstack.push

    ; draw Title Screen
	dci 	gfx.titlescreen.parameters
	pi 		blitGraphic

	dci		gfx.quickgame.parameters
	pi		blitGraphic

	dci		gfx.Bo3.parameters
	pi		blitGraphic

	dci		gfx.Bo5.parameters
	pi		blitGraphic

	MOVE_SOUND

	lis 	0	; quick game mode is default selection
	lr 		11, A

.gamemode.loop:
	; draw selection
	lr 		A, 11
	ci		0
	bz		.drawQuickGameSelection
	ci 		1
	bz		.drawBo3Selection
	br 		.drawBo5Selection

.drawQuickGameSelection:
	DRAW_CHIP 	COLOR_RED, 18, 31, COLOR_GREEN
	DRAW_CHIP	COLOR_GREEN, 24, 39, COLOR_GREEN
	DRAW_CHIP 	COLOR_GREEN, 24, 47, COLOR_GREEN
	jmp 	.waitButtonPress

.drawBo3Selection:
	DRAW_CHIP 	COLOR_GREEN, 18, 31, COLOR_GREEN
	DRAW_CHIP	COLOR_RED, 24, 39, COLOR_GREEN
	DRAW_CHIP 	COLOR_GREEN, 24, 47, COLOR_GREEN
	jmp 	.waitButtonPress

.drawBo5Selection:
	DRAW_CHIP 	COLOR_GREEN, 18, 31, COLOR_GREEN
	DRAW_CHIP	COLOR_GREEN, 24, 39, COLOR_GREEN
	DRAW_CHIP 	COLOR_RED, 24, 47, COLOR_GREEN



.waitButtonPress:
	WAIT_BUTTON_PRESS	%10001100, 0
	ni 		%10001100
	bnz 	.handleInput	

	; randomize seed
	SETISAR RANDOM_GENERATOR
	ds 		S

    jmp 	.gamemode.loop

.handleInput:
	; button pressed
	ni 		%00001100
	bz 		.gamemodeSelect
	lr 		0, A
	MOVE_SOUND
	lr 		A, 0
	; test up direction
	ni 		%00000100
	bz 		.up
	; test down direction
	jmp		.down

.gamemodeSelect:
	PLACE_CHIP_SOUND
	SET_GAMEMODE	11
	jmp 	.opponentSelect
.up:
	lr 		A, 11
	ci		0
	bz		.nogamemodechange
	ds 		11
	jmp 	.gamemode.loop
.down:
	lr 		A, 11
	ci		2
	bz		.nogamemodechange
	inc
	lr 		11, A
	jmp 	.gamemode.loop

.nogamemodechange:
	jmp		.gamemode.loop

.opponentSelect:
	SET_AI_DISABLED ; default selection

	dci 	gfx.titlescreen.parameters
	pi 		blitGraphic

	dci		gfx.p1vsp2.parameters
	pi		blitGraphic

	dci		gfx.p1vsAI.parameters
	pi		blitGraphic

	MOVE_SOUND

	lis 	0	; quick game mode is default selection
	lr 		11, A

.opponentSelect.loop:
	; draw selection
	lr 		A, 11
	ci		0
	bz		.drawP1vsP2Selection
	br 		.drawP1vsAISelection

.drawP1vsP2Selection:
	DRAW_CHIP 	COLOR_RED, 24, 33, COLOR_GREEN
	DRAW_CHIP	COLOR_GREEN, 19, 42, COLOR_GREEN
	jmp 	.waitButtonPressOpponent

.drawP1vsAISelection:
	DRAW_CHIP 	COLOR_GREEN, 24, 33, COLOR_GREEN
	DRAW_CHIP	COLOR_RED, 19, 42, COLOR_GREEN

.waitButtonPressOpponent:
	WAIT_BUTTON_PRESS	%10001100, 0
	ni 		%10001100
	bnz 	.handleInputOpponent

	; randomize seed
	SETISAR RANDOM_GENERATOR
	ds 		S

    jmp 	.opponentSelect.loop

.handleInputOpponent:
	; button pressed
	ni 		%00001100
	bz 		.selectOpponent
	lr 		0, A
	MOVE_SOUND
	lr 		A, 0
	; test up direction
	ni 		%00000100
	bz 		.upOpponent
	; test down direction
	jmp		.downOpponent

.selectOpponent:
	PLACE_CHIP_SOUND
	li 		255
	lr 		5, A
	pi 		BIOS_DELAY
	jmp 	.titlescreenEnd
.upOpponent:
	lis  	0
	lr 		11, A
	SET_AI_DISABLED
	jmp 	.opponentSelect.loop
.downOpponent:
	lis  	1
	lr 		11, A
	SET_AI_ENABLED
	jmp 	.opponentSelect.loop

.titlescreenEnd:
	pi		kstack.pop
    pk
