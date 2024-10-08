; Wait for any button press on either controller
; Arguments passed: pattern to match, 0/1 to indicate if waiting until a button is pressed or not

    MAC WAIT_BUTTON_PRESS
.waitButtonPress:
    clr
    outs 	0		; enable input from controllers (related to bit6 of port0?)
    outs	1		; clear port1 (right controller	)
    ins   	1		; read right controller first (requires half the CPU cycles than reading left controller on port 4 
    com
    ni      {1}
    bnz 	.waitRelease	; if button pressed, no need to read other controller	
    outs 	4		; clear port4 (left controller)
    ins  	4		; read left controller
    com
    ni      {1}
    bnz 	.waitRelease	; if button pressed, no need to read other controller
    IF {2} = 0
        br     .exit
    ENDIF
    br		.waitButtonPress
.waitRelease:
    lr      10, A
    clr
    outs    0
    outs    1
    ins     1
    com
    bnz     .waitRelease
    outs    4
    ins     4
    com
    bnz     .waitRelease
    lr      A, 10
.exit
    ENDM

    MAC MAP_ACTION_RETURN
    lis     {1}
    lr      0, A
    jmp     {2}
    ENDM