; Wait for / poll a button press on either controller.
; Arguments passed: {1} = pattern to match, {2} = 0 (poll once) / 1 (block until pressed).
;
; This is now a thin wrapper around the waitButtonPress / pollButtonPress
; subroutine (src/functions/game/waitButtonPress.asm) — factored out to save ROM,
; since dasm macros expand inline at every call site. It loads the mask into r1
; and calls the matching entry point. Result is returned in A (and r10), exactly
; as before. `pi` is safe at every current call site (all are inside kstack-based
; subroutines that already preserve their own return; see the subroutine header).

    MAC WAIT_BUTTON_PRESS
    li      {1}
    lr      1, A		; mask -> r1
    IF {2} = 0
        pi  pollButtonPress
    ELSE
        pi  waitButtonPress
    ENDIF
    ENDM

    ; Writes action code {1} into r0 (via A), then `jmp {2}`. The `jmp` terminates
    ; control flow; the destination later does `lr A,0` to read the action code back.
    MAC MAP_ACTION_RETURN
    lis     {1}
    lr      0, A
    jmp     {2}
    ENDM