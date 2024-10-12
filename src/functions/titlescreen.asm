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

    jmp 	.gamemode.loop

.handleInput:
	; button pressed
	ni 		%00001100
	bz 		.gamemodeSelect
	; test up direction
	ni 		%00000100
	bz 		.up
	; test down direction
	jmp		.down

.gamemodeSelect:
	SET_GAMEMODE	11
	jmp 	.titlescreenEnd
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

.titlescreenEnd:
	pi		kstack.pop
    pk
