; MOVE_SOUND / PLACE_CHIP_SOUND are thin wrappers around called subroutines
; (src/functions/sound.asm) so their bodies are emitted once instead of inline
; at every call site. Clobber footprint is unchanged (A, r5, plus K/kstack).
	MAC MOVE_SOUND
	pi 		moveSound
    ENDM

    MAC PLACE_CHIP_SOUND
	pi 		placeChipSound
    ENDM

	MAC INVALID_MOVE_SOUND
	li 		%10000000
	outs 	5
	li 		6
	lr 		5, a
	pi 		BIOS_DELAY
	li 		%11000000
	outs 	5
	li 		12
	lr 		5, a
	pi 		BIOS_DELAY
	clr
	outs 	5
	li 		12
	lr 		5, a
	pi 		BIOS_DELAY
	li 		%10000000
	outs 	5
	li 		6
	lr 		5, a
	pi 		BIOS_DELAY
	li 		%11000000
	outs 	5
	li 		12
	lr 		5, a
	pi 		BIOS_DELAY

	clr
	outs 	5
	ENDM

; WINNING_SOUND: the long shared body is a subroutine (winningSoundCommon in
; src/functions/sound.asm); only the small final-tone tail differs by {1}, so
; it stays inline here and no parameter needs to be passed to the subroutine.
	MAC WINNING_SOUND
	pi 		winningSoundCommon

	IF {1} = 1
	li 		%11000000
	ELSE
	li 		%10000000
	ENDIF
	outs 	5
	li 		255
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5
    ENDM