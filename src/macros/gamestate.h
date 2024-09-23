; returns the blinking counter in A
    MAC GET_BLINKING_COUNTER
    SETISAR GAME_STATE
    lr 		A, S
    ni 		%00111111	; get blinking counter, with max value of 63
    ENDM

; decreases the blinking counter (modifies r0)
    MAC DECREASE_BLINKING_COUNTER
    GET_BLINKING_COUNTER
    lr      0, A
    ds      0

    lr 		A, S
    ni 		%11000000	; mask out blinking counter
    xs      0
    lr      S, A
    lr      A, 0        ; put the updated counter in A to allow checking against it
    ENDM

; sets the blinking counter
    MAC SET_BLINKING_COUNTER
    SETISAR GAME_STATE
    lr 		A, S
    ni 		%11000000	; mask out blinking counter
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
    ni 		%11000000	; get turn state
    ENDM

; updates the turn state with the provided value
    MAC UPDATE_TURN_STATE
    SETISAR GAME_STATE
    lr 		A, S
    ni      %00111111
    oi      {1}
    lr      S, A
    ENDM
