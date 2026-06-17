; 8-direction (dx,dy) table for scanAllDirections (boardManipulation.asm)
; Order is LOAD-BEARING: R, RU, U, LU, L, LD, D, DR.
; AI scoring (ai.asm) sums per-direction flip counts in this exact order, so it
; must match the order the 3 callers previously unrolled by hand.
; Values: $01 = +1, $00 = 0, $ff = -1. Each row is (dx, dy).
directions:
    .byte   $01, $00    ; R   right
    .byte   $01, $ff    ; RU  right-up
    .byte   $00, $ff    ; U   up
    .byte   $ff, $ff    ; LU  left-up
    .byte   $ff, $00    ; L   left
    .byte   $ff, $01    ; LD  left-down
    .byte   $00, $01    ; D   down
    .byte   $01, $01    ; DR  down-right
