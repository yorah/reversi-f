GAMEMODE_QUICKGAME = %00000000
GAMEMODE_BO3 = %00000001
GAMEMODE_BO5 = %00000010

; GAME_MODE (r27) bit-field masks (single source of truth for the register layout):
;   bits 1-0 : game mode (00 quickgame, 01 Bo3, 10 Bo5)
;   bit  2   : AI enabled (0 = human vs human, 1 = human vs computer)
GAME_MODE_MASK 		= %00000011	; game mode field
GAME_MODE_CLEAR 	= %11111100	; everything except game mode field
GAME_MODE_AI_MASK 	= %00000100	; AI enabled bit
GAME_MODE_AI_CLEAR 	= %11111011	; everything except AI enabled bit

; returns the gamemode in A
    MAC GET_GAMEMODE
    SETISAR GAME_MODE
    lr 		A, S
    ni 		GAME_MODE_MASK
    ENDM

; sets the gamemode
    MAC SET_GAMEMODE
    SETISAR GAME_MODE
    lr 		A, S
    ni 		GAME_MODE_CLEAR	; mask out gamemode
    xs      {1}
    lr      S, A
    ENDM

; returns if AI is enabled
    MAC GET_AI
    SETISAR GAME_MODE
    lr 		A, S
    ni 		GAME_MODE_AI_MASK
    ENDM

; sets AI enabled
    MAC SET_AI_ENABLED
    SETISAR GAME_MODE
    lr 		A, S
    oi      GAME_MODE_AI_MASK
    lr      S, A
    ENDM

; sets AI disabled
    MAC SET_AI_DISABLED
    SETISAR GAME_MODE
    lr 		A, S
    ni      GAME_MODE_AI_CLEAR
    lr      S, A
    ENDM