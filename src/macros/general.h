; Simple delay loop
    MAC DELAY
    li		$ff
.delay
	ai		$ff
	bnz		.delay
    ENDM

; JMP Table using jmp instructions (see F8 programming guide)
    MAC JMP_TABLE
    dci 	{1}
	adc
	adc
	adc
	lr 		Q, DC
	lr 		P0, Q
    ENDM

; Preserve and restore parameter
	MAC PRESERVE_PARAM
		SETISAR {2}
		lr 		A, {1}
		lr 		S, A
	ENDM
	MAC RESTORE_PARAM
		SETISAR {2}
		lr 		A, S
		lr 		{1}, A
	ENDM