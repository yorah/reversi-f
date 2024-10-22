	MAC MOVE_SOUND
    li 		%10000000
	outs 	5
	
	li 		8
	lr 		5, A
	pi 		BIOS_DELAY

	clr
	outs 	5
    ENDM

    MAC PLACE_CHIP_SOUND
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

	MAC WINNING_SOUND
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