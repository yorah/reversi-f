;===========================================================================
; KStack Functions (from pacman game => it is more optimized than the
; built-in channelf one)
;===========================================================================
; the K stack implements a stack using the registers. it uses r63 as a stack
; pointer that holds the register number of the top of the stack, starting
; at r57 and working down. when called, K is pushed to the first two
; registers on the stack, and the pointer is increased.
;
; at startup, the stack pointer (r63) should be set to 62 ($3E)

;---------------------------------------------------------------------------
; KStack Push
;---------------------------------------------------------------------------
; pushes register K onto the stack using r63 as the stack pointer
; destroys ISAR

kstack.push:
	; get the top of the stack
	lisu	7
	lisl	7			; r63, stack pointer
	lr	A, S
	lr	IS, A			; load the referenced register
	; push K onto the stack
	lr	A, Ku
	lr	S, A			; push high byte of K
	lr	A, IS
	ai	$ff				; decrease ISAR
	lr	IS, A
	lr	A, Kl
	lr	S, A			; push low byte of K
	; adjust the stack pointer
	lr	A, IS
	ai	$ff				; decrease ISAR
	lisu	7
	lisl	7
	lr	S, A			; store the adjusted stack pointer in r63

	; return from the subroutine
	pop

;---------------------------------------------------------------------------
; KStack Pop
;---------------------------------------------------------------------------
; pops register K from the stack using r63 as the stack pointer
; destroys ISAR
                
kstack.pop:
	; retrieve K from the stack
	lisu	7
	lisl	7
	lr	A, S			; load the stack pointer into A
	inc					; increment the pointer
	lr	IS, A			; and set the ISAR
	lr	A, S
	lr	Kl, A			; load lower byte of K 
	lr	A, IS
	inc					; increase ISAR
	lr	IS, A
	lr	A, S
	lr	Ku, A			; load upper byte of K
	; adjust the stack pointer
	lr	A, IS
	lisu	7
	lisl	7
	lr	S, A			; store the adjusted stack pointer in r63

	; return from the subroutine
	pop