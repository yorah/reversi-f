;******************************************************************************
;** PLAYER_STATE MACROs
;******************************************************************************
; SETISAR PLAYER_STATE must be called before using these macros
; returns the position in A
    MAC GET_X_POSITION
    lr 		A, S
    ni 		%11100000	; get X position
    sr 		4
    sr 		1
    ENDM

; SETISAR PLAYER_STATE must be called before using these macros
; returns the position in A
    MAC GET_Y_POSITION
    lr 		A, S
    ni 		%00011100	; get Y position
    sr 		1
    sr 		1
    ENDM

; SETISAR PLAYER_STATE must be called before using these macros
; returns the player turn in A
    MAC GET_PLAYER_TURN
    lr 		A, S
    ni 		%00000001	; get player turn
    ENDM

; Updates the player state by adding {1} to the existing Y position
    MAC UPDATE_Y_POSITION
    SETISAR PLAYER_STATE
    lr 		A, S
    ni		%00011100
    sr		1
    sr		1
    ai 		{1}
    ni 		%00000111
    sl 		1
    sl 		1
    lr 		0, A	; store new Y position
    lr		A, S
    ni 		%11100011	; clear Y position
    xs		0
    lr		S, A
    IF {2} = 1
        MAP_ACTION_RETURN 0, handleInput.continuations
    ENDIF
    ENDM

; Updates the player state by adding {1} to the existing X position
    MAC UPDATE_X_POSITION
    SETISAR PLAYER_STATE
    lr 		A, S
    ni		%11100000
    sr		4
    sr		1
    ai 		{1}
    ni 		%00000111
    sl 		4
    sl 		1
    lr 		0, A	; store new X position
    lr		A, S
    ni 		%00011111	; clear X position
    xs		0
    lr		S, A
    IF {2} = 1
        MAP_ACTION_RETURN 0, handleInput.continuations
    ENDIF
    ENDM

; Sets the player state X and Y position directly from passed register
    MAC SET_XY_POSITION
    SETISAR PLAYER_STATE
    lr		A, S
    ni 		%00000011	; clear XY position
    xs		{1}
    lr		S, A
    ENDM