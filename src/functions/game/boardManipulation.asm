;******************************************************************************
;* PLACE CHIP
;******************************************************************************
; Updates the BOARD_STATE register with the new chip, and
; draws it on the screen. Used both to add a chip on the board,
; and to update existing ones (when flipping chips).
; BOARD_STATE encoding (slot (X,Y) -> register/bit-pair, chip codes):
; see the diagram in src/functions/newgame.asm. Chip codes: P1=%10, P2=%11.
; r0 = X position in board
; r1 = Y position in board
; r2 = slot register number
; r3 = slot bit position
;
; modifies: r1-r9 (through blit call)
; returns nothing of interest

updateBoardAndDrawChip:
updateBoardAndDrawChip	SUBROUTINE
	lr 		K, P
	pi      kstack.push

    ;-----------------------------------
    ;--- First place chip in BOARD_STATE
	SETISAR PLAYER_STATE
	GET_PLAYER_TURN
	bnz 	.setBitPlayer2
	li 	    PLAYER1_COLOR
	lr      5, A 		; store color in r5 for later
	li 		%00000010	; set bit pattern to 10 for player 1
	br 	.setBitEnd
.setBitPlayer2:
	li 		PLAYER2_COLOR
	lr 		5, A 		; store color in r5 for later
	li 		%00000011	; set bit pattern to 11 for player 2
.setBitEnd:
	lr 		4, A		; store bit pattern in r4
    ; create dynamic mask to set the bit in the right position
	lis 	3			; first store %00000011 in A
	lr 		7, A		; store it in r7
	lr 		A, 3		; load bit position from r3
	lr 		6, A		; and store it in r6 oo to later shift r7 to the right position (with calls to DS/SL)
	ni 		%11111111	; AND with all-ones: value unchanged, but sets Z from result (ni sets Z, see docs/f8-notes.md)
; VERIFIED: Z from `ni` survives to the `bz` below. The intervening `lr A,7` is a pure
; register move and affects NO status flags (docs/f8-notes.md), so Z still reflects r3==0.
	lr 		A, 7		; load dynamic mask from r7
	bz	 	.noShift
	lr 		A, 4		; load bit from r4
.loopShiftBitPattern:	
	sl		1			; shift to get the bit in the right position
	ds		3			; count number of bits to offset
	bnz		.loopShiftBitPattern
	lr 		4, A		; store bit pattern shifted to correct position in r4
	lr 		A, 7		; load dynamic mask from r7
.loopShiftDynamicMask:
	sl 		1			; shift to get the bit in the right position
	ds      6			; count number of bits to offset
	bnz	 	.loopShiftDynamicMask
.noShift:
	com                 ; invert to get the actual dynamic mask (we want to mask OUT the bits we want to set)
	lr 		7, A		; store dynamic mask in r7

	lr 		A, 2		; load register number from r2
	lr 		IS, A		; set ISAR to the register number
	lr 		A, S		; load byte from BOARD_STATE
	ns 		7			; clear the slot (2 bits) to set
	lr 		S, A
	lr 		A, 4		; load new slot
	xs 		S 			; set the slot

	lr 		S, A		; save board state register updated

    ;------------------------------------
    ;--- Then draw the chip on the screen
	; calculate X position
	lr 		A, 0
	com
	ai 		1
	lr		2, A
	lr 		A, 0
	sl 		1
	sl 		1
	sl 		1
	as 		2
	ai 		4
	lr 		2, A		; store X in r2

	; calculate Y position
	lr 		A, 1
	sl		1
	com
	ai 		1
	lr		3, A
	lr 		A, 1
	sl 		1
	sl 		1
	sl 		1
	as 		3
	ai 		4
	lr 		3, A		; store Y in r3

	; set background color, $ff being transparent color
	li 		COLOR_TRANSPARENT
	lr 		0, A		; store color 1 in r0 (for blit)
	; set color based on current player
	lr 		A, 5
	lr 		1, A		; store color 2 in r1 (for blit)

	dci 	gfx.piece.data
	pi 		slot.draw

	pi	 	kstack.pop
	pk


;******************************************************************************
;* GET SLOT CONTENT
;******************************************************************************
; Get the content of a slot from BOARD_STATE
; Encoding (index=Y*8+X; reg=32+index/4; bit-pair=(index%4)*2): see the
; full diagram + chip-code legend in src/functions/newgame.asm.
; r0 = X position
; r1 = Y position
;
; modifies: r2, r3, r4
; returns the slot content in A, the slot register number in r2, and the slot bit position in r3

getSlotContent:
getSlotContent	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	; calculate register number
	lr 		A, 1 	; load Y position
	sl 		1		; multiply by 8
	sl 		1
	sl 		1
	as 	    0		; add X to Y*8 to get index of slot to test
	lr 		2, A	; store index in r2

	ni 		%00000011	; find remainder of division by 4	
	sl 		1		; multiply by 2 to get the bit position
	lr 		3, A	; store bit position in r3
	lr 		4, A	; store bit position in r4 too (r4 will be used with DS to count bits to shift, so it will end up with 0)

	lr 		A, 2
	sr 		1		; divide by 4 to find register (each byte stores 4 slots of 2 bits)
	sr 		1
	ai 		BOARD_STATE	; add 32 to get the register number
	lr 		2, A	; store register number in r2

	lr 		A, 4	; load bit position from r4
	ni 		%11111111	; AND with all-ones: value unchanged, but sets Z from result (ni sets Z, see docs/f8-notes.md)
; VERIFIED: Z from `ni` survives to the `bz` below. The intervening `lr A,2`, `lr IS,A`
; and `lr A,S` are all pure register moves that affect NO status flags (docs/f8-notes.md),
; so Z still reflects whether r4 (bit position) was 0.
	lr		A, 2	; load register number from r2
	lr		IS, A	; set ISAR to the register number
	lr		A, S	; load byte from BOARD_STATE
	bz	 	.noShift
.loopShift:
	sr		1			; shift to get the bit in the right position
	ds		4			; count number of bits to offset
	bnz		.loopShift
.noShift
	ni 		%00000011	; mask out the 2 bits we want to check/flip
	lr      4, A   		; store the content in r4

	pi 		kstack.pop
	lr 		A, 4		; return content in A
	pk


;******************************************************************************
;* SCAN ALL DIRECTIONS
;******************************************************************************
; Walks all 8 directions from a candidate slot and, depending on the mode in r6,
; either flips/places chips (PLACE), tells whether any valid direction exists
; (EXISTS), or sums how many chips would flip across all directions (COUNT).
;
; This is the de-duplicated form of the old per-direction worker
; (flipChipsInDirection): the 8-direction loop that the 3 callers
; (ai / newturn / inputActions) used to unroll by hand now lives INSIDE here,
; so each caller makes ONE pi call. The per-direction walk below is kept inline
; (a loop body, NOT a sub-subroutine) so NO new kstack level is added.
;
; The 8 (dx,dy) pairs come from the directions table (src/data/directions.inc),
; in the load-bearing order R,RU,U,LU,L,LD,D,DR. The loop index lives in r52
; (a register that is otherwise completely unused in the codebase: the only
; symbol with value 52 is BOARD_BOTTOM_Y, used solely as an immediate constant
; in board.draw, never as a register). r52 survives the inner pi calls because
; nothing those callees touch (kstack r53-62, r0-r9, DC) overlaps it.
; The directions table is re-addressed into DC every iteration from the index,
; because updateBoardAndDrawChip -> blit clobbers DC in PLACE mode.
;
; r0 = initial X position
; r1 = initial Y position
; r2 = slot register number (used to call updateBoardAndDrawChip)
; r3 = slot bit position (used to call updateBoardAndDrawChip)
; r6 = mode:	0 = PLACE  (flip + place chips on every valid direction)
;		2 = EXISTS (check only; short-circuit + return r10=1 on first valid direction)
;		3 = COUNT  (check only; sum per-direction flip counts into r9 over all 8 directions)
;		1 is the internal already-placed transient used during PLACE
; r7 = player turn (used to check if slot is player 1 or player 2)
;	(r4/r5 are no longer caller inputs: dx/dy are fetched per direction from the table)
;
; modifies: r4-r5, r7-r10 (through updateBoardAndDrawChip call; r7 not modified if only checking)
;			r0-r1 are preserved on return, r6 mutated, r9 accumulated in COUNT mode
;			r16-r25 (used to preserve params), r52 (loop index)
; returns in r10:	EXISTS/PLACE -> 1 if a valid direction was found (chip placed / move valid), else 0
;			COUNT -> per-direction flip count of the last direction (the running sum is in r9)
; returns in r9 (COUNT only): the total number of chips that can be flipped across all 8 directions

scanAllDirections:
scanAllDirections	SUBROUTINE
	lr 		K, P
	pi      kstack.push

	; preserve the constant params (origin X/Y, slot reg/bit, mode, turn).
	; r4/r5 (dx/dy) are refreshed per direction inside the loop instead.
	PRESERVE_PARAM 0, 16
	PRESERVE_PARAM 1, 17
	PRESERVE_PARAM 2, 18
	PRESERVE_PARAM 3, 19
	PRESERVE_PARAM 6, 22
	PRESERVE_PARAM 7, 23

	; initialize the direction index (0..7)
	lis 	0
	SETISAR 52
	lr 		S, A		; r52 = 0 (first direction)

;------------------------------------------------------------------------------
; TOP OF THE 8-DIRECTION LOOP
;------------------------------------------------------------------------------
scanAllDirections.dirLoop:
	; reset X/Y to the slot origin, and slot reg/bit, for this direction
	RESTORE_PARAM 0, 16
	RESTORE_PARAM 1, 17
	RESTORE_PARAM 2, 18
	RESTORE_PARAM 3, 19
	RESTORE_PARAM 6, 22		; restore mode (PLACE may have ridden r6 to 1 on a previous direction)
	RESTORE_PARAM 7, 23

	; fetch this direction's (dx,dy) fresh from the table.
	; DC is reloaded every iteration (blit clobbers DC in PLACE mode), then
	; advanced by index*2 bytes via adc, then two lm's read dx then dy.
	dci 	directions
	SETISAR 52
	lr 		A, S		; load direction index
	sl 		1			; index * 2 (2 bytes per entry: dx, dy)
	adc					; DC += index*2  (adc treats A as signed; 0..14 fits)
	lm					; A = dx ; DC++
	lr 		4, A		; store dx in r4
	lm					; A = dy ; DC++
	lr 		5, A		; store dy in r5

	; preserve dx/dy for restore after getSlotContent / updateBoardAndDrawChip
	PRESERVE_PARAM 4, 20
	PRESERVE_PARAM 5, 21

	lis 	0
	lr 		10, A		; store 0 in r10 (used to track if opponents chips were found)

	; move to next slot to check
.flipChipsInDirection.loop:
	; get new X
	lr		A, 0	; load X position
	as	  	4		; add X direction
	ci		8		; check if we reached the end of the board
	bz		.noChipsToFlip
	ci		$ff		; check if we reached the beginning of the board
	bz 		.noChipsToFlip
	lr 		0, A    ; store new X position in r0

	; get new Y
	lr		A, 1	; load Y position
	as		5		; add Y direction
	ci		8		; check if we reached the end of the board
	bz		.noChipsToFlip
	ci		$ff		; check if we reached the beginning of the board
	bz		.noChipsToFlip
	lr		1, A	; store new Y position in r1
	br		.checkSlotContent

.noChipsToFlip:
	jmp 	scanAllDirections.nextDirection

.checkSlotContent:
	pi 		getSlotContent
	lr 		8, A	; store slot content in r8
	RESTORE_PARAM 2, 18
	RESTORE_PARAM 3, 19
	RESTORE_PARAM 4, 20

	lr 		A, 8	; load back slot content

	ni 		%00000011	; check if slot is empty
	bz 		.noChipsToFlip	; if slot is empty, no chips to flip

	; branching depending on which player is playing
	lr 		A, 7
	ni 		%00000001
	bz 		.checkPlayer1
.checkPlayer2:
	lr 		A, 8	; load back slot content
	ci 		%00000010	; check if slot contains a player 1 chip
	bz      .checkSlotContent.opponentChipsFound
	br      .checkSlotContent.ownChipsFound
.checkPlayer1
	lr 		A, 8	; load back slot content
	ci 		%00000011	; check if slot container a player 2 chip
	bz      .checkSlotContent.opponentChipsFound
	br      .checkSlotContent.ownChipsFound
.checkSlotContent.opponentChipsFound:
	lr 		A, 10	; load previous chips found
	inc
	lr 		10, A	; store new chips found
	jmp 	.flipChipsInDirection.loop	; continue looping, to check if there are more chips to flip, or if there is a chip from the current player to complete a line
.checkSlotContent.ownChipsFound:
	lr 		A, 10	; load previous opponents chips found
	ni 		%11111111
	bz      .noChipsToFlip	; if no opponents chips were found, no chips to flip

	; chips to flip... start flipping baby
.flipChips:
	RESTORE_PARAM 0, 16	; restore initial X
	RESTORE_PARAM 1, 17	; restore initial Y
	lr 		A, 6	; r6 mode: 0 = place chip; 1 = already placed (flip only);
					; 2 = EXISTS (short-circuit on first valid direction);
					; 3 = COUNT (sum per-direction flip counts, no placement)
	ni 		%11111111
	bz 		.callPlaceChip
	ci 		2		; EXISTS: only checking for existence?
	bz 		.validMoveExists	; if so, short-circuit and return r10=1
	ci 		3		; COUNT: only summing flip counts?
	bz 		.countDirection		; if so, add this direction's count and continue
	jmp 	.flipChips.loop		; chip was already placed, keep loop until all existing chips are flipped
.validMoveExists:
	; EXISTS mode: a valid direction was found, return r10 = 1 immediately
	lis 	1
	lr 		10, A	; r10 = 1 marks "a valid move exists"
	jmp 	scanAllDirections.end
.countDirection:
	; COUNT mode: r10 holds the opponent-chip count for this valid direction.
	; Add it into the running total in r9, then advance to the next direction.
	lr 		A, 9
	as 		10
	lr 		9, A
	jmp 	scanAllDirections.nextDirection
.callPlaceChip:
	PLACE_CHIP_SOUND
	pi      updateBoardAndDrawChip
	; animate chip flipping
	li		128
	lr 		5, A
	pi 		BIOS_DELAY
	RESTORE_PARAM 5, 21
	RESTORE_PARAM 7, 23

	lr 		A, 7	; load player playing
	ni 		%00000001
	bz 		.addScorePlayer1
	SETISAR PLAYER2_SCORE
	br 		.addScoreEnd
.addScorePlayer1
	SETISAR PLAYER1_SCORE
.addScoreEnd
	lis 	1
	ai 		$66
	asd 	S
	lr 		S, A

	pi      updateScoreInSidebar
	RESTORE_PARAM 0, 16 ; restore initial X
	RESTORE_PARAM 1, 17 ; restore initial Y
	RESTORE_PARAM 4, 20 ; restore r4 and r5 lost when calling updateBoardAndDrawChip
	RESTORE_PARAM 5, 21
	RESTORE_PARAM 7, 23

	lis 	1
	lr 		6, A	; store 1 in r6 to avoid calling updateBoardAndDrawChip multiple times (if several directions can be flipped)
	PRESERVE_PARAM 6, 22	; preserve r6
.flipChips.loop:
	lr		A, 0	; load X position
	as	  	4		; add X direction
	lr 		0, A    ; store new X position in r0
	PRESERVE_PARAM 0, 24	; preserve new X

	; get new Y
	lr		A, 1	; load Y position
	as		5		; add Y direction
	lr		1, A	; store new Y position in r1
	PRESERVE_PARAM 1, 25	; preserve new Y

	; call getSlotContent to retrieve register number and bit position to update in r2 and r3
	pi 		getSlotContent
	RESTORE_PARAM  4, 20

	PLACE_CHIP_SOUND
	pi 		updateBoardAndDrawChip

	; animate chip flipping
	li		128
	lr 		5, A
	pi 		BIOS_DELAY

	RESTORE_PARAM  7, 23

	lis	 	1
	lr 		0, A	; for decimal substraction

	lr 		A, 7	; load player playing
	ni 		%00000001
	bz 		.updateScorePlayer1
	SETISAR PLAYER2_SCORE
	lis	    1
	ai 		$66
	asd 	S
	lr 		S, A
	SETISAR PLAYER1_SCORE
	lis	    1
	com
	asd 	S
	ai 		$66
	asd 	0
	lr 		S, A
	br 		.updateScoreEnd
.updateScorePlayer1
	SETISAR PLAYER1_SCORE
	lis	    1
	ai 		$66
	asd 	S
	lr 		S, A
	SETISAR PLAYER2_SCORE
	lis	    1
	com
	asd 	S
	ai 		$66
	asd 	0
	lr 		S, A

.updateScoreEnd
	pi 		updateScoreInSidebar

	RESTORE_PARAM  0, 24
	RESTORE_PARAM  1, 25
	RESTORE_PARAM  4, 20
	RESTORE_PARAM  5, 21
	RESTORE_PARAM  6, 22
	RESTORE_PARAM  7, 23

	ds 		10		; decrement number of chips to flip
	bnz 	.flipChips.loop.jmp	; loop until all chips are flipped
	jmp     scanAllDirections.nextDirection	; this direction done, advance
.flipChips.loop.jmp:
	jmp 	.flipChips.loop

;------------------------------------------------------------------------------
; END OF ONE DIRECTION -> advance the index and loop, or finish.
; Reached after a direction completes (no valid line, or PLACE flip loop done,
; or COUNT added its total). EXISTS short-circuits straight to .end instead.
;------------------------------------------------------------------------------
scanAllDirections.nextDirection:
	SETISAR 52
	lr 		A, S		; load direction index
	inc					; next direction
	lr 		S, A		; store it back in r52
	ci 		8			; processed all 8 directions?
	bz 		scanAllDirections.allDirectionsDone
	jmp 	scanAllDirections.dirLoop	; loop back for the next direction

scanAllDirections.allDirectionsDone:
	; PLACE/EXISTS return r10 (1 = a valid direction / chip placed, else 0).
	; In PLACE mode r6 rode to 1 if any direction placed; mirror that into r10.
	; (EXISTS already returned r10=1 via short-circuit; COUNT leaves the sum in r9.)
	RESTORE_PARAM 6, 22	; load back the (possibly mutated) mode
	lr 		A, 6
	ci 		1			; did PLACE place at least one chip (r6 == 1)?
	bz 		.placeWasValid
	lis 	0
	lr 		10, A		; no chip placed / no valid direction -> r10 = 0
	br 		scanAllDirections.end
.placeWasValid:
	lis 	1
	lr 		10, A		; chip placed -> r10 = 1

scanAllDirections.end:
	RESTORE_PARAM 0, 16	; restore initial X
	RESTORE_PARAM 1, 17	; restore initial Y
	pi      kstack.pop
	pk
