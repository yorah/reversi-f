
;******************************************************************************
;* GRAPHICS DATA
;* Used for blit
;* Idea and adaptation from pacman
;******************************************************************************

;---------------------------------------------------------------------------
; Slot selection sprite
;---------------------------------------------------------------------------

gfx.slotSelection.data:
	.byte	%11111111
	.byte	%10000001
	.byte	%10000001
	.byte	%10000001
	.byte	%10000001
	.byte	%10000001
	.byte	%11111111
	
;---------------------------------------------------------------------------
; "Turn" Lettering
;---------------------------------------------------------------------------

gfx.turn.parameters:
	.byte	$ff			; color 1 (clear color)
	.byte	COLOR_BACKGROUND	; color 2
	.byte	76			; x position
	.byte	4			; y position
	.byte	16			; width
	.byte	4			; height
	.word	gfx.turn.data		; address for the graphics

gfx.turn.data:
	.byte	%11101010, %11001110
	.byte	%01001010, %10101010
	.byte	%01001010, %11001010
	.byte	%01001110, %10101010