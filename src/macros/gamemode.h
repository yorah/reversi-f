; returns the gamemode in A
    MAC GET_GAMEMODE
    SETISAR GAME_MODE
    lr 		A, S
    ni 		%00000011
    ENDM

; sets the gamemode
    MAC SET_GAMEMODE
    SETISAR GAME_MODE
    lr 		A, S
    ni 		%11111100	; mask out gamemode
    xs      {1}
    lr      S, A
    ENDM