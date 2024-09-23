; Wait for any button press on either controller

    MAC WAIT_ANY_BUTTON_PRESS
.waitButtonPress:
    clr
    outs 	0		; enable input from controllers (related to bit6 of port0?)
    outs	1		; clear port1 (right controller	)
    ins   	1		; read right controller first (requires half the CPU cycles than reading left controller on port 4 
    com
    bnz 	.buttonPressed	; if button pressed, no need to read other controller	
    outs 	4		; clear port4 (left controller)
    ins  	4		; read left controller
    com
    bnz 	.buttonPressed	; if button pressed, no need to read other controller
    br		.waitButtonPress
.buttonPressed:
    ENDM

    MAC MAP_ACTION_RETURN
    lis     {1}
    lr      0, A
    jmp     {2}
    ENDM