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

	WAIT_ANY_BUTTON_PRESS

.titlescreenEnd:
	pi		kstack.pop
    pk
