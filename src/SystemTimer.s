					AREA sddata, READONLY, DATA
;SYSTICK INITIALIZATION
NVIC_ST_CTRL 		EQU 0xE000E010
NVIC_ST_RELOAD 		EQU 0xE000E014
NVIC_ST_CURRENT 	EQU 0xE000E018
SHP_SYSPRI3 		EQU 0xE000ED20
	
;PIOSC/4 = 4Mhz, 4Mhz, 1/4Mhz = 0.250 us
;  2000*0.25 us = 0.5 ms
RELOAD_VALUE 		EQU  2000; 2000 clock(0.5ms intervals for sampling) to obtain 2k samples per second (1sec/0.0005sec=2000samples)
;----------------------------------------------------------------------------------------

;FOR ADC PROCESS
GPIO_PORTE_DATA EQU 0x40024020; PE3 analog input
	
ATD_ADC0_PSSI EQU 0x40038028
ATD_ADC0_RIS EQU 0x40038004
ATD_ADC0_FIFO3 EQU 0x400380A8
ATD_ADC0_ISC EQU 0x4003800C
	
;*********************************************************
; I n i t i a l i z a t i o n a r e a
;*********************************************************
					AREA initisr , CODE, READONLY
					THUMB
					EXPORT My_ST_ISR
						
						
					EXPORT Init_SysTick	
Init_SysTick 		PROC
					PUSH {R0, R1}
					;first disable system timer and the related interrupt 
					;then configure oscillator as PIOSC/4
					LDR R1, =NVIC_ST_CTRL 
					MOV R0, #0
					STR R0, [R1]
					
					; now set the time out period by loadin RELOAD
					LDR R1, =NVIC_ST_RELOAD
					LDR R0, =RELOAD_VALUE
					STR R0, [R1]
					; now set the CURRENT time value to the time out value
					LDR R1, =NVIC_ST_CURRENT
					STR R0, [R1]
					; current timer = time out period
					
					; now set the priority level
					LDR R1, =SHP_SYSPRI3
					MOV R0, #0x40000000
					STR R0, [R1]
					; priority is set to 2
					
					; now enable system timer and the related interrupt
					LDR R1, =NVIC_ST_CTRL
					MOV R0, #0x03
					STR R0, [R1]
					; set up for system time is now complete
					POP {R0, R1}
					BX LR
					ENDP
						
					;*********************************************************
					; SysTick ISR area
					;*********************************************************
					
					EXPORT My_ST_ISR
My_ST_ISR			PROC
					PUSH{R0,R1,R3}; R5 needs to preserve its value since we use it for storing the values in memory.
					LDR R1, =0x20000800
					CMP R5, R1; if R5 = #0x20000800, then we have 256 sample values in memory.
					BNE continue
					;Disabling the SysTick since we done with the sampling.
					LDR R1, =NVIC_ST_CTRL 
					MOV R0, #0
					STR R0, [R1]
					B finish
					
					
					;we have 1.25 V offset in analog input. While we (0.25, 2.25V) we want (-1V, 1V)
					;offset: minimum analog value
					;Digital number = (2^n)[(analog number/span) - (offset/span)],
					;span does not change it is max analog-min analog = 2V and n=12bit
					;Therefore the value 2^n(analog number/span) is our current value, we need to subtract 2^n(offset/span)
					;from current result
continue			MOV R3, #2560; 2560 = 2^n(offset/span)
					
					
samplestart 		LDR R1, =ATD_ADC0_PSSI
					LDR R0, [R1]
					ORR R0, R0, #0x08 ;iniate sampling for SS3 (it should be started
								;again once a sampling is finished)
					STR R0, [R1]
					
pool 				LDR R1, =ATD_ADC0_RIS
					LDR R0, [R1]
					AND R0, #0x8; Obtaining only SS3 interrupt bit. If sampling
								;sequence is completed this bit is set (result is ready in FIFO3)
					EORS R0, #0x8
					BNE 	pool; if the interrupt bit is not set we continue checking
								;(polling)
					LDR R1, =ATD_ADC0_FIFO3 ; if it is set, we store sampling result
											;in R0
					LDR R0, [R1]
					SUB R0, R3; Subtraction to remove 1.25 V offset
					LSL R0, #4; To carry the result higher 12 bit side of the real part
					MOV32 R1,#0xFFFF0000; to obtain only lower 16 bit
					BIC R0, R1
					STR R0, [R5], #4; Storing the result in memory location pointed by R5

					
					;ADC interrupt bir clear steps
finish				LDR R1, =ATD_ADC0_ISC ; Clear interrupt bit to continue sampling
											;(we set END0 (stop after a sample result is generated) so we need to do this step to continue.
											;Also to be able to
											;catch the next result by being able to know when it is ready in FIFO3
					LDR R0, [R1]
					ORR R0, #0x08; By setting this bit, the interrupt flag for SS3
								;will be cleared
					STR R0, [R1]
					
					
					POP{R0,R1,R3}
					BX LR 
					ENDP
						
						
						
		
					END