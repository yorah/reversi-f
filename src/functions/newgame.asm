;******************************************************************************
;* NEWGAME INITIALIZATION
;******************************************************************************

newgame.init:
newgameInit 	SUBROUTINE
    lr 		K, P
    pi      kstack.push

.setRegistersForNewGame:
    ; reset blink counter to BLINK_LOOPS
	SET_BLINKING_COUNTER BLINK_LOOPS

	; reset BLINK_COLOR to player1
	li    	PLAYER1_COLOR
	SETISAR BLINK_COLOR
	lr		S, A
	
    ; reset PLAYER_STATE
	li		%01101100	; X=4, Y=4, player 1 starts
	SETISAR PLAYER_STATE
	lr		S, A

	; reset scores (both players start at 2)
	lis 	2
	SETISAR PLAYER1_SCORE
	lr		S, A
	SETISAR PLAYER2_SCORE
	lr 		S, A

	;==========================================================================
	; BOARD_STATE ENCODING  (r32..r47 = 16 bytes; ISAR octal 40-47 / 50-57)
	;--------------------------------------------------------------------------
	; The 8x8 board is packed 2 bits per slot, 4 slots per register byte.
	; Authoritative mapping is derived from getSlotContent /
	; updateBoardAndDrawChip (src/functions/game/boardManipulation.asm):
	;
	;     index = Y*8 + X                 (X,Y in 0..7)
	;     register = BOARD_STATE + (index / 4)      = 32 + index/4   (r32..r47)
	;     bit-pair position = (index % 4) * 2       = 0, 2, 4 or 6   (LSB-first)
	;
	; Each slot is a 2-bit field within its byte; pair 0 is the low two bits.
	; Chip codes (2-bit values):
	;     00 = empty      10 = Player 1      11 = Player 2     (01 unused)
	;
	; Slot -> (register . bit-pair position) for the whole board:
	;
	;       X=0    X=1    X=2    X=3    X=4    X=5    X=6    X=7
	; Y=0  r32.0  r32.2  r32.4  r32.6  r33.0  r33.2  r33.4  r33.6
	; Y=1  r34.0  r34.2  r34.4  r34.6  r35.0  r35.2  r35.4  r35.6
	; Y=2  r36.0  r36.2  r36.4  r36.6  r37.0  r37.2  r37.4  r37.6
	; Y=3  r38.0  r38.2  r38.4  r38.6  r39.0  r39.2  r39.4  r39.6
	; Y=4  r40.0  r40.2  r40.4  r40.6  r41.0  r41.2  r41.4  r41.6
	; Y=5  r42.0  r42.2  r42.4  r42.6  r43.0  r43.2  r43.4  r43.6
	; Y=6  r44.0  r44.2  r44.4  r44.6  r45.0  r45.2  r45.4  r45.6
	; Y=7  r46.0  r46.2  r46.4  r46.6  r47.0  r47.2  r47.4  r47.6
	;
	; Standard Reversi opening seeded below (P1=green, P2=red):
	;     (X3,Y3)=P1  (X4,Y3)=P2  (X3,Y4)=P2  (X4,Y4)=P1
	;==========================================================================

	; clear BOARD_STATE
	;--------------------------------------------------------------------------
	; CLEAR LOOP CORRECTNESS  (audit: highest-risk section -> VERDICT: CORRECT)
	;
	; This loop must zero exactly r32..r47, which spans TWO ISAR 8-byte windows
	; (octal 40-47 = r32..r39, then octal 50-57 = r40..r47). It deliberately
	; uses an EXPLICIT, full-width ISAR increment, NOT auto-increment:
	;     lr A, IS   ; read raw 6-bit ISAR value (== register number for 0..63)
	;     inc        ; binary +1 over all 6 bits
	;     lr IS, A   ; write it back (on next iteration)
	; Binary inc crosses the in-buffer boundary correctly:
	;     r39 = oct 47 = %100111 ; +1 -> %101000 = oct 50 = r40   (steps to r40)
	; Auto-increment (S/I port, br7) only touches the LOW 3 octal bits and would
	; WRAP within the window: %100111 -> %100000 (r39 -> r32). It must NOT be
	; used to walk r32..r47 in one pass. Hence the explicit increment here.
	; Terminator: ci $30 ($30 = 48 = r47+1); stops after writing r47.  Proof:
	; A counts 32,33,...,47 (each written), then 48 -> ci $30 sets Z -> exit.
	;--------------------------------------------------------------------------
    li      BOARD_STATE
.clearBoardStateLoop:
    lr      IS, A
    clr
    lr 		S, A
    lr      A, IS
	inc
    ci      $30
    bnz     .clearBoardStateLoop

	; init starting positions in BOARD_STATE
	; 1011 1110 in center
    ; P1 chips
	li		%10000000
	SETISAR 38
	lr		S, A
	lis 	%00000010
	SETISAR 41
	lr		S, A
	; P2 chips
    lis     %00000011
	SETISAR 39
	lr 		S, A
	li 	 	%11000000
	SETISAR 40
	lr		S, A

.drawGameSurface:
	li 		COLOR_BACKGROUND
	lr 		1, A
	pi      clearscreen

	; draw board
	pi 		board.draw

	; draw sidebar
	pi 		sidebar.draw

	; draw center chips
	; top left
	DRAW_CHIP PLAYER1_COLOR, 25, 22, COLOR_TRANSPARENT
	; bottom right
	DRAW_CHIP PLAYER1_COLOR, 32, 28, COLOR_TRANSPARENT
	; top right
	DRAW_CHIP PLAYER2_COLOR, 32, 22, COLOR_TRANSPARENT
	; bottom left
	DRAW_CHIP PLAYER2_COLOR, 25, 28, COLOR_TRANSPARENT

	; init sidebar (player turn)
	pi 		updateTurnInSidebar

	; init score in sidebar
	pi 		updateScoreInSidebar

	; init Bo3 / Bo5 score in sidebar
	pi 		updateBoScoreInSidebar

.newgameEnd:
    pi 		kstack.pop
    pk
