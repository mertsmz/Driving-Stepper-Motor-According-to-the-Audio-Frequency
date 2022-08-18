			AREA 	rout, READONLY, CODE
			THUMB
			EXPORT finddominant
				
finddominant	PROC
			PUSH{R0,R1,R2,R3,R6,R7,R8,R9,R10}; 
			LDR 	R1, =0x20000400; Now the array has magnitues
			LDR		R2, =0x20000600; Last adress for comparison(not included)
			
			MOV 	R4, #0; R4 will hold the dominant freq value
			MOV		R5, #0; R5 will hold its amplitude value
			MOV		R6, #0; R6 is the index flag n		
			
			;Freq = n(Fs/N) where N=256, Fs=2000, n: index
			; Fs/N = 7,8125 = 78125x10^(-4). We will multiply this value with n
			MOV32 	R7, #78125
			MOV32	R8, #10000; R7 and R8 for arithmatic
			

			
			
;The process for the first element is not in the main loop to initialize register with some values.			
			
			LDR R0, [R1], #4;
			
			;MOV R5, R0; Take the first amplitude
			;instead put 0 for the dc component since we don't want that to be highest anyway.
			;I did this because the 0 hz compenent amplitude results higher than others, I don't know why
			MOV R5, #0;
			MUL R4,R6, R7; This MUL and UDIV finds freq from index R6;
			UDIV R4, R4, R8; First freq 0 Hz value is in R4, ie DC offset component.
			
			
			
loop128		CMP R1, R2; If all off them compared
			BEQ.W finish
			
			ADD R6, #1;
			
			LDR R0, [R1], #4;
			
			;R9 and R10 are the temprorary registers for freq and amp
			MOV R10, R0; R10 holds the temporary amp value
			MUL R9,R6, R7; 
			UDIV R9, R9, R8; R9 holds the temporary freq value

			;Comparison between the previous highest amplitude freq component
			CMP R10, R5;
			BLO loop128; if its amplitude ise lower than the previous highest skip to next index
			MOV R4, R9; If amplitude is higher, then update the freq and amplitude values
			MOV R5, R10;
			B	loop128

			
finish		POP{R0,R1,R2,R3,R6,R7,R8,R9,R10}
			BX	LR
			
			
			ENDP
			END
			
