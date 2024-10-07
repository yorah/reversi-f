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

	WAIT_BUTTON_PRESS	%11001111, 1

	dci		gfx.quickgame.parameters
	pi		blitGraphic

	dci		gfx.Bo3.parameters
	pi		blitGraphic

	dci		gfx.Bo5.parameters
	pi		blitGraphic

	WAIT_BUTTON_PRESS	%11001111, 1

.titlescreenEnd:
	pi		kstack.pop
    pk
