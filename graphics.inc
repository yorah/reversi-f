
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
; Piece sprite
;---------------------------------------------------------------------------

gfx.piece.data:
	.byte	%00000000
	.byte	%00011000
	.byte	%00111100
	.byte	%01111110
	.byte	%00111100
	.byte	%00011000
	.byte	%00000000

;---------------------------------------------------------------------------
; Skip sprite
;---------------------------------------------------------------------------

gfx.skip.data:
	.byte	%11101010, %11101110
	.byte	%11001100, %01001010
	.byte	%00101010, %01001110
	.byte	%11101010, %11101000


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

;---------------------------------------------------------------------------
; "Skip" Lettering
;---------------------------------------------------------------------------

gfx.skip.parameters:
	.byte	$ff			; color 1 (clear color)
	.byte	COLOR_BACKGROUND	; color 2
	.byte	76			; x position
	.byte	14			; y position
	.byte	16			; width
	.byte	4			; height
	.word	gfx.skip.data		; address for the graphics


;---------------------------------------------------------------------------
; "P1" Lettering
;---------------------------------------------------------------------------

gfx.p1.parameters:
	.byte	BOARD_COLOR		; color 1 (clear color)
	.byte	PLAYER1_COLOR	; color 2
	.byte	80			; x position
	.byte	9			; y position
	.byte	8			; width
	.byte	4			; height
	.word	gfx.p1.data		; address for the graphics

gfx.p1.data:
	.byte	%11000100
	.byte	%10101100
	.byte	%11000100
	.byte	%10001110

;---------------------------------------------------------------------------
; "P2" Lettering
;---------------------------------------------------------------------------

gfx.p2.parameters:
	.byte	BOARD_COLOR			; color 1 (clear color)
	.byte	PLAYER2_COLOR	; color 2
	.byte	80			; x position
	.byte	9			; y position
	.byte	8			; width
	.byte	4			; height
	.word	gfx.p2.data		; address for the graphics

gfx.p2.data:
	.byte	%11001100
	.byte	%10100010
	.byte	%11000100
	.byte	%10001110
