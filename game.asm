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
                                             
 
    processor f8

; Include VES Header
	include "ves.h"

; Constants

; Registers used


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
	li	$c6		; $d6 gray - $c0 green - $21 b/w - $93 blue
	lr	3, A
	pi	BIOS_CLEAR_SCREEN

; Padding
	org $fff
	.byte $ff
