;******************************************************************************
;* WAIT / POLL BUTTON PRESS
;******************************************************************************
; Reads both controllers (right on port 1 first — cheaper — then left on port 4)
; and matches the buttons against a mask. Factored out of the WAIT_BUTTON_PRESS
; macro (input.h) to save ROM: the macro now expands to a register setup plus a
; single `pi` to one of the two entry points below.
;
; Arguments:
;   r1 = button mask (which inverted port bits to keep)
;   r0 = mode: 0 = poll once then return, 1 = block until a matching button
;        (only meaningful via the entry point chosen — see below)
;
; Two shared-body entry points:
;   waitButtonPress  — block: loops until a masked button is pressed.
;   pollButtonPress  — poll : reads both controllers once; if nothing matches,
;                      returns 0 (in A/r10) without looping.
;
; Returns the matched (inverted) controller pattern in A, and a copy in r10.
;
; LEAF ROUTINE: contains NO `pi` calls, so PC1 still holds the caller's return
; address. It returns via `pop` (PC0 <- PC1) and consumes ZERO kstack levels.
; Every call site is inside a kstack-based SUBROUTINE that already saved its own
; return (lr K,P / pi kstack.push, returns via pk) and makes other `pi` calls,
; so clobbering PC1 here is safe.

pollButtonPress
pollButtonPress SUBROUTINE
	lis		0			; mode = poll once
	lr		0, A
	br		.scan

waitButtonPress:
	lis		1			; mode = block until pressed
	lr		0, A

.scan:
	clr
	outs	0			; enable input from controllers (related to bit6 of port0?)
	outs	1			; clear port1 (right controller)
	ins		1			; read right controller first (cheaper than port 4)
	com					; invert bits, so that 1 means button pressed
	ns		1			; mask
	bnz		.waitRelease	; if button pressed, no need to read other controller
	outs	4			; clear port4 (left controller)
	ins		4			; read left controller
	com
	ns		1			; mask
	bnz		.waitRelease	; if button pressed, no need to read other controller

	; nothing matched. poll mode (r0 = 0) returns 0; block mode (r0 = 1) loops.
	lr		A, 0		; A = mode flag (lr does NOT set status flags)
	ci		0			; compare A - 0 to set Z (A unchanged); Z set iff poll mode
	bnz		.scan		; block mode: keep polling
	clr					; poll mode: A = 0 (no match)
	br		.exit

.waitRelease:
	lr		10, A		; save matched pattern
	clr
	outs	0
	outs	1
	ins		1
	com
	bnz		.waitRelease
	outs	4
	ins		4
	com
	bnz		.waitRelease
	lr		A, 10		; restore matched pattern into A

.exit:
	pop					; leaf return (PC0 <- PC1)
