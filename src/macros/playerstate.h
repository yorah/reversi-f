;******************************************************************************
;** PLAYER_STATE MACROs
;******************************************************************************
; PLAYER_STATE (r31) bit-field masks (single source of truth for the register layout):
;   bits 7-5 : X selection position
;   bits 4-2 : Y selection position
;   bit  1   : debounce flag
;   bit  0   : player turn (0 = player 1, 1 = player 2)
PLAYER_STATE_X_MASK 		= %11100000	; X position field
PLAYER_STATE_X_CLEAR 		= %00011111	; everything except X position
PLAYER_STATE_Y_MASK 		= %00011100	; Y position field
PLAYER_STATE_Y_CLEAR 		= %11100011	; everything except Y position
PLAYER_STATE_XY_CLEAR 		= %00000011	; everything except X and Y positions
PLAYER_STATE_DEBOUNCE_MASK 	= %00000010	; debounce flag
PLAYER_STATE_DEBOUNCE_CLEAR	= %11111101	; everything except debounce flag
PLAYER_STATE_TURN_MASK 		= %00000001	; player turn bit

; SETISAR PLAYER_STATE must be called before using these macros
; returns the position in A
    MAC GET_X_POSITION
    lr 		A, S
    ni 		PLAYER_STATE_X_MASK	; get X position
    sr 		4
    sr 		1
    ENDM

; SETISAR PLAYER_STATE must be called before using these macros
; returns the position in A
    MAC GET_Y_POSITION
    lr 		A, S
    ni 		PLAYER_STATE_Y_MASK	; get Y position
    sr 		1
    sr 		1
    ENDM

; SETISAR PLAYER_STATE must be called before using these macros
; returns the player turn in A
    MAC GET_PLAYER_TURN
    lr 		A, S
    ni 		PLAYER_STATE_TURN_MASK	; get player turn
    ENDM

; Updates the player state by adding {1} to the existing Y position
    MAC UPDATE_Y_POSITION
    SETISAR PLAYER_STATE
    lr 		A, S
    ni		PLAYER_STATE_Y_MASK
    sr		1
    sr		1
    ai 		{1}
    ni 		%00000111
    sl 		1
    sl 		1
    lr 		0, A	; store new Y position
    lr		A, S
    ni 		PLAYER_STATE_Y_CLEAR	; clear Y position
    xs		0
    lr		S, A
    IF {2} = 1
        ; {2}=1 => emit MAP_ACTION_RETURN, which ends in `jmp` (terminates control flow)
        MAP_ACTION_RETURN 0, handleInput.continuations
    ENDIF
    ENDM

; Updates the player state by adding {1} to the existing X position
    MAC UPDATE_X_POSITION
    SETISAR PLAYER_STATE
    lr 		A, S
    ni		PLAYER_STATE_X_MASK
    sr		4
    sr		1
    ai 		{1}
    ni 		%00000111
    sl 		4
    sl 		1
    lr 		0, A	; store new X position
    lr		A, S
    ni 		PLAYER_STATE_X_CLEAR	; clear X position
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
    ni 		PLAYER_STATE_XY_CLEAR	; clear XY position
    xs		{1}
    lr		S, A
    ENDM