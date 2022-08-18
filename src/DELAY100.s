			AREA 	txt, READONLY, CODE
			THUMB
			EXPORT 	DELAY100
			EXTERN __main
DELAY100	PROC
;NOTES
;I wrote this for 16 Mhz 1 cycle = 1/16.000.000 = 0.0625 us
;Branch instructions takes 3 cycles when the condition is met
;Branch instructions takes 1 cycle when the condition is not met
;Most of the instructions takes one cycle
;You can use NOP in the loop to increase delay

;BL DELAY100 and BX LR takes 0.375 us
;--
			PUSH    {R1}
			MOV32	R1, #228571
			
loop			SUBS R1, #1
			NOP
			NOP
			NOP
			BNE loop


;--			
;(1+1+1+1+3)x(0.0625 us)x(0x37CDB=228571) = 99.999 ms; 
;push,pop,mov instructions: 0.1875 us; BL and BX: 0.375 us. They are so small to consider
			POP    {R1}	
			BX LR
			ENDP
			END
