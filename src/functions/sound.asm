;******************************************************************************
;* SOUND SUBROUTINES
;******************************************************************************
; These subroutines hold the bodies of the multiply-invoked sound envelopes.
; The MOVE_SOUND / PLACE_CHIP_SOUND macros (src/macros/sound.h) are now thin
; wrappers that `pi` into these, and WINNING_SOUND calls winningSoundCommon for
; its long shared part. Factoring them out of inline macro expansion saves ROM
; (macros expand at every call site; a subroutine is emitted once).
;
; clobbers: A, r5 (same footprint as the original inline macros) + K/kstack
; calls BIOS_DELAY (duration in r5), exactly as the macros did.

;------------------------------------------------------------------------------
; MOVE SOUND (was MOVE_SOUND, x5 invocations)
;------------------------------------------------------------------------------
moveSound:
moveSound 	SUBROUTINE
	lr 		K, P
	pi      kstack.push

    li 		%10000000
	outs 	5

	li 		8
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5

	pi      kstack.pop
	pk

;------------------------------------------------------------------------------
; PLACE CHIP SOUND (was PLACE_CHIP_SOUND, x5 invocations)
;------------------------------------------------------------------------------
placeChipSound:
placeChipSound 	SUBROUTINE
	lr 		K, P
	pi      kstack.push

    li 		%01000000
	outs 	5

	li 		12
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5
    li 		8
	lr 		5, A
	pi 		BIOS_DELAY

    li 		%10000000
	outs 	5

	li 		12
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5

	pi      kstack.pop
	pk

;------------------------------------------------------------------------------
; WINNING SOUND COMMON (shared body of WINNING_SOUND, x3 invocations)
;------------------------------------------------------------------------------
; This is everything BEFORE the `IF {1}` tail of the original WINNING_SOUND
; macro. The small differing tail (final tone + outs/delay/clear) stays inline
; in the macro so no parameter needs to be passed.
winningSoundCommon:
winningSoundCommon 	SUBROUTINE
	lr 		K, P
	pi      kstack.push

    li 		%01000000
	outs 	5
	li 		48
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5
    li 		16
	lr 		5, A
	pi 		BIOS_DELAY

    li 		%01000000
	outs 	5
	li 		48
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5
    li 		16
	lr 		5, A
	pi 		BIOS_DELAY

	li 		%01000000
	outs 	5
	li 		48
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5
    li 		16
	lr 		5, A
	pi 		BIOS_DELAY



    li 		%10000000
	outs 	5
	li 		96
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5
    li 		32
	lr 		5, A
	pi 		BIOS_DELAY


	li 		%01000000
	outs 	5
	li 		48
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5
    li 		16
	lr 		5, A
	pi 		BIOS_DELAY

	pi      kstack.pop
	pk
