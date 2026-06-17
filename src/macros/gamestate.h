; GAME_STATE (r30) bit-field masks (single source of truth for the register layout):
;   bits 7-6 : turn state (00 can move, 01 has to skip, 10 game over)
;   bits 5-0 : blinking counter (max value 63)
GAME_STATE_BLINK_MASK 		= %00111111	; blinking counter field
GAME_STATE_BLINK_CLEAR 		= %11000000	; everything except blinking counter
GAME_STATE_TURN_MASK 		= %11000000	; turn state field
GAME_STATE_TURN_CLEAR 		= %00111111	; everything except turn state

; returns the blinking counter in A
    MAC GET_BLINKING_COUNTER
    SETISAR GAME_STATE
    lr 		A, S
    ni 		GAME_STATE_BLINK_MASK	; get blinking counter, with max value of 63
    ENDM

; decreases the blinking counter (modifies r0)
    MAC DECREASE_BLINKING_COUNTER
    GET_BLINKING_COUNTER
    lr      0, A
    ds      0

    lr 		A, S
    ni 		GAME_STATE_BLINK_CLEAR	; mask out blinking counter
    xs      0
    lr      S, A
    lr      A, 0        ; put the updated counter in A to allow checking against it
    ENDM

; sets the blinking counter
    MAC SET_BLINKING_COUNTER
    SETISAR GAME_STATE
    lr 		A, S
    ni 		GAME_STATE_BLINK_CLEAR	; mask out blinking counter
    oi      {1}
    lr      S, A
    ENDM

; Turn states: 00 - current player can move, 01 - current player has to skip, 10 - game over
GAME_OVER = %10000000
CURRENT_PLAYER_HAS_TO_SKIP = %01000000
CURRENT_PLAYER_CAN_MOVE = %00000000

; returns the turn state in A
    MAC GET_TURN_STATE
    SETISAR GAME_STATE
    lr 		A, S
    ni 		GAME_STATE_TURN_MASK	; get turn state
    ENDM

; updates the turn state with the provided value
    MAC UPDATE_TURN_STATE
    SETISAR GAME_STATE
    lr 		A, S
    ni      GAME_STATE_TURN_CLEAR
    oi      {1}
    lr      S, A
    ENDM
