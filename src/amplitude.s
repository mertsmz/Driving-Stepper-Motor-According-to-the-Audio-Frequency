			AREA 	rout, READONLY, CODE
			THUMB
			EXPORT findmagnitudes
				
findmagnitudes	PROC
			PUSH{R0,R1,R2,R3,R4,R5}	
			LDR 	R4, =0x20000400; Now the array has FFT ouputs(im and re parts in 4 bytes)
			LDR		R5, =0x20000600; Last one is 128. element since the magnitude of the other half will be same 128x4=512=0x200

			
loop128		CMP R4, R5; If all amplitudes calculated then finish subroutine
			BEQ.W finish
			
			
			
			LDRSH R3, [R4]; R3 has re part
			LDRSH R2, [R4, #2]; R2 has im part
			
			
			MUL R2, R2, R2;
			MUL R3, R3, R3;
			
			ADD R0, R2, R3; The number (im)^2 + (re)^2 is in R0
			

			
;I used this squareroot routine from the adress https://www.pertinentdetail.org/sqrt
;It is written by Dan Maloney.

;-SQRT ROUTINE
;       Optimised 32-bit integer sqrt
;       Calculates square root of R0
;       Result returned in R0, uses R1 and R2
;       Worst case execution time exactly 70 S cycles
		
intsqr
        MOV     r1,#0
        CMP     r1,r0,LSR #8
        BEQ     bit8            ; &000000xx numbers

        CMP     r1,r0,LSR #16
        BEQ     bit16           ; &0000xxxx numbers

        CMP     r1,r0,LSR #24
        BEQ     bit24           ; &00xxxxxx numbers

        SUBS    r2,r0,#&40000000
        MOVCS   r0,r2
        MOVCS   r1,#&10000

        ADD     r2,r1,#&4000
        SUBS    r2,r0,r2,LSL#14
        MOVCS   r0,r2
        ADDCS   r1,r1,#&8000

        ADD     r2,r1,#&2000
        SUBS    r2,r0,r2,LSL#13
        MOVCS   r0,r2
        ADDCS   r1,r1,#&4000

bit24
        ADD     r2,r1,#&1000
        SUBS    r2,r0,r2,LSL#12
        MOVCS   r0,r2
        ADDCS   r1,r1,#&2000

        ADD     r2,r1,#&800
        SUBS    r2,r0,r2,LSL#11
        MOVCS   r0,r2
        ADDCS   r1,r1,#&1000

        ADD     r2,r1,#&400
        SUBS    r2,r0,r2,LSL#10
        MOVCS   r0,r2
        ADDCS   r1,r1,#&800

        ADD     r2,r1,#&200
        SUBS    r2,r0,r2,LSL#9
        MOVCS   r0,r2
        ADDCS   r1,r1,#&400

bit16
        ADD     r2,r1,#&100
        SUBS    r2,r0,r2,LSL#8
        MOVCS   r0,r2
        ADDCS   r1,r1,#&200

        ADD     r2,r1,#&80
        SUBS    r2,r0,r2,LSL#7
        MOVCS   r0,r2
        ADDCS   r1,r1,#&100

        ADD     r2,r1,#&40
        SUBS    r2,r0,r2,LSL#6
        MOVCS   r0,r2
        ADDCS   r1,r1,#&80

        ADD     r2,r1,#&20
        SUBS    r2,r0,r2,LSL#5
        MOVCS   r0,r2
        ADDCS   r1,r1,#&40

bit8
        ADD     r2,r1,#&10
        SUBS    r2,r0,r2,LSL#4
        MOVCS   r0,r2
        ADDCS   r1,r1,#&20

        ADD     r2,r1,#&8
        SUBS    r2,r0,r2,LSL#3
        MOVCS   r0,r2
        ADDCS   r1,r1,#&10

        ADD     r2,r1,#&4
        SUBS    r2,r0,r2,LSL#2
        MOVCS   r0,r2
        ADDCS   r1,r1,#&8

        ADD     r2,r1,#&2
        SUBS    r2,r0,r2,LSL#1
        MOVCS   r0,r2
        ADDCS   r1,r1,#&4

        ADD     r2,r1,#&1
        CMP     r0,r2
        ADDCS   r1,r1,#&2

        MOV     r0,r1,LSR#1     ; result in R0
	
		STR R0, [R4], #4;
		B	loop128

			
			
			
finish		POP{R0,R1,R2,R3,R4,R5}
			BX	LR
			
			
			ENDP
			END
			
