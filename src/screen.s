					AREA 	sddata, READONLY, DATA
GPIO_PORTA_DATA 	EQU 0x400043F0; A2,A3,A4,A5 will be used as clk,Fss,Rx,Tx 
; A7 for the reset of LCD, A6 for D/C
;Fss is connected to CE of LCD
GPIO_PORTA_DIR 		EQU 0x40004400
GPIO_PORTA_AFSEL 	EQU 0x40004420
GPIO_PORTA_AMSEL 	EQU 0x40004528 ;
GPIO_PORTA_PCTL 	EQU 0x4000452C ; 
GPIO_PORTA_DEN 		EQU 0x4000451C;
GPIO_PORTA_PUR		EQU 0x40004510;
	
IOB_A				EQU	0xEC; A2,A3,A5 output, A4(Rx) input, A6 OUTPUT,A7 output

SYSCTL_RCGCGPIO 	EQU 0x400FE608
;-----------------------------------------------------------
;SSI0 base adress: 0x40008000
SPI_SSI0_CR1		EQU 0x40008004
SPI_SSI0_CPSR		EQU 0x40008010
SPI_SSI0_CR0		EQU 0x40008000
SPI_SSI0_DR			EQU 0x40008008
SPI_SSI0_SSISR		EQU 0x4000800C
	
SYSCTL_RCGCSSI      EQU	0x400FE61C
;----------
;Timer1 to check how much time have passed since last update on LCD
TIMER1_CFG			EQU 0x40031000 ; Config, it is used to choose 16 bit or 32 bit mode
TIMER1_TAMR			EQU 0x40031004 ; Timer mode register
TIMER1_CTL			EQU 0x4003100C ; Control register
TIMER1_IMR			EQU 0x40031018 ; Interrupt mask, setting related bits enables related interrupts
TIMER1_RIS			EQU 0x4003101C ; Timer Interrupt Status
TIMER1_ICR			EQU 0x40031024 ; Timer Interrupt Clear
TIMER1_TAILR		EQU 0x40031028 ; Timer interval
TIMER1_TAPR			EQU 0x40031038 ; Prescale register
TIMER1_TAR			EQU	0x40031048 ; Timer register

SYSCTL_RCGCTIMER 	EQU 0x400FE604 ; GPTM Gate Control
	

					AREA 	cfg, READONLY, CODE
					THUMB
						
					EXPORT initPortA
					EXPORT 	SPIinit
					EXPORT LCDinit
					EXTERN DELAY100
					EXPORT drawdata
					EXPORT drawdigit
;Port A init						
initPortA			PROC
					PUSH {R0, R1,R2,LR};Saving registers to be used in initialization
					LDR R1, =SYSCTL_RCGCGPIO
					
					LDR R0, [R1] 
					ORR R0, #0x01; only port A will be clocked and used
					STR R0, [R1]
					NOP
 					NOP
 					NOP
					
					LDR R1, =GPIO_PORTA_DIR
					LDR R0, [R1]
					BIC R0, #0xFF;First directions are cleared to start from a clean/default point(default is all pins are inputs)
					ORR R0, #IOB_A
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTA_AFSEL
					LDR R0, [R1]
					BIC R0, #0xFF;
					ORR R0, #0x3C; AFSEL is enabled for pins A5,A4,A3,A2
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTA_DEN
					LDR R0, [R1]
					ORR R0, #0xFC; Digital 
					STR R0, [R1]
					
					
					LDR R1, =GPIO_PORTA_PCTL
					LDR R0, [R1]
					BIC R0, #0xFF
					MOV32 R2, #0x222200
					ORR R0, R2; Configure A2,A3,A4,A5 as clk,Fss,Rx,Tx 
					STR R0, [R1]
					
					;LDR R1, =GPIO_PORTA_PUR
					;LDR	R0, [R1];
					;ORR R0, #0x4; Pull up is enabled for A2 
					;Datasheet says this is needed for the clk pin when SPO bit in the SSICR0 is enabled in SSI initialization
					STR R0, [R1]
					POP {R0, R1,R2}
					BX	LR
					ENDP
					LTORG
;End of portAinit

;SSI0 module initialization
SPIinit				PROC
					PUSH {R0, R1,R2}
					LDR R1, =SYSCTL_RCGCSSI
					LDR R0, [R1] 
					ORR R0, #0x01; only SSI0 will be used
					STR R0, [R1]
					NOP
 					NOP
 					NOP
					NOP
					NOP
					NOP
					
					
					
					LDR R1, =SPI_SSI0_CR1
					LDR R0, [R1] 
					BIC R0, #0x2; disable before config
					STR R0, [R1]
					
					LDR R1, =SPI_SSI0_CPSR
					MOV R0, #24; 2Mbit = 16MHz/(CPSDVSR * (1 + SCR)); CPDVSR must be even num so I choose it as 4
					STR R0, [R1] 
					
					LDR R1, =SPI_SSI0_CR0
					LDR R0, [R1] 
					MOV32 R2,#0xFFFF 
					BIC R0, R2
					MOV32 R2,#0x7
					ORR R0, R2;SCR is 0 (BITS 15-8); 8bit data length, freescale mod 
					STR R0, [R1]; 
					
					LDR R1, =SPI_SSI0_CR1
					LDR R0, [R1] 
					ORR R0, #0x2; Enable the SSI
					STR R0, [R1]
	
					POP {R0, R1,R2}
					BX LR
					ENDP
					LTORG



LCDinit				PROC
					PUSH {R0, R1,LR}
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0, #0x80; only reset pin A7
					STR R0, [R1]
					BL DELAY100; wait 100 ms for reset
					LDR R0, [R1]
					ORR R0, #0x80
					STR R0, [R1]
					
					
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0,#0x40; D/C=0
					STR R0, [R1]
					
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x21; H=1, V=0
					STR R0, [R1]
					BL waitforsend
					
					

					
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0xBB; Vop contrast value setting 
					STR R0, [R1]
					BL waitforsend

					
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x05; Temp control value 
					STR R0, [R1]
					BL waitforsend

					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x13; Bias setting
					STR R0, [R1]
					BL waitforsend

					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x20; H=0, basic command mode
					STR R0, [R1]
					BL waitforsend

					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x0C; Normal mode
					STR R0, [R1]
					BL waitforsend

					BL ClrAll; To make screen clean initally
	
					POP {R0, R1,LR}
					BX LR
					ENDP
					LTORG
					
;FUNCTIONS TO BE USED WHILE DRIVING LCD
;It waits current data to be sent
waitforsend			PROC ;
					PUSH {R0, R1}				
					LDR R1, =SPI_SSI0_SSISR;;Bit 4 in SSISR is busy status flag
wait				LDR R0, [R1]
					AND R0, #0x10
					CMP R0, #0x10
					BEQ wait					
					
					POP {R0, R1}
					BX	LR						
					ENDP
					LTORG	
;sends the data placed in R12
					EXPORT drawdata
drawdata			PROC
					PUSH {R0, R1,LR}
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					ORR R0, #0x40; D/C=1
					STR R0, [R1]

					LDR R1, =SPI_SSI0_DR					
					STR R12, [R1]
					BL waitforsend
					POP {R0, R1,LR}
					BX	LR
					ENDP
						
;Draws the digit in R12 on LCD 

drawdigit			PROC
					PUSH {R0, R1,LR}
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					ORR R0, #0x40; D/C=1
					STR R0, [R1]
					
					LDR R1, =SPI_SSI0_DR	
					CMP R12, #0
					BEQ.W draw0
					
					CMP R12, #1
					BEQ.W draw1
					
					CMP R12, #2
					BEQ.W draw2
					
					CMP R12, #3
					BEQ.W draw3
					
					CMP R12, #4
					BEQ.W draw4
					
					CMP R12, #5
					BEQ.W draw5
					
					CMP R12, #6
					BEQ.W draw6
					
					CMP R12, #7
					BEQ.W draw7
					
					CMP R12, #8
					BEQ.W draw8
					
					CMP R12, #9
					BEQ.W draw9


draw0
					MOV 	R12, #0xFF;
					BL drawdata
					MOV 	R12, #0x81;
					BL drawdata
					MOV 	R12, #0x81;
					BL drawdata
					MOV 	R12, #0x81;
					BL drawdata
					MOV 	R12, #0xFF;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit

draw1
					MOV 	R12, #0x84;
					BL drawdata
					MOV 	R12, #0x82;
					BL drawdata
					MOV 	R12, #0xFF;
					BL drawdata
					MOV 	R12, #0x80;
					BL drawdata
					MOV 	R12, #0x80;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit
					
draw2
					MOV 	R12, #0xF9;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x8F;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit

draw3				
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0xFF;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit

draw4
					MOV 	R12, #0x0F;
					BL drawdata
					MOV 	R12, #0x08;
					BL drawdata
					MOV 	R12, #0x08;
					BL drawdata
					MOV 	R12, #0x08;
					BL drawdata
					MOV 	R12, #0xFF;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit
draw5
					MOV 	R12, #0x8F;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0xF9;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit

draw6				MOV 	R12, #0xFF;
					BL drawdata
					MOV 	R12, #0x91;
					BL drawdata
					MOV 	R12, #0x91;
					BL drawdata
					MOV 	R12, #0x91;
					BL drawdata
					MOV 	R12, #0xF1;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit
					
draw7				MOV 	R12, #0x01;
					BL drawdata
					MOV 	R12, #0x01;
					BL drawdata
					MOV 	R12, #0x01;
					BL drawdata
					MOV 	R12, #0x01;
					BL drawdata
					MOV 	R12, #0xFF;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit
					
draw8				MOV 	R12, #0xFF;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0xFF;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit

draw9
					MOV 	R12, #0x8F;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0x89;
					BL drawdata
					MOV 	R12, #0xFF;
					BL drawdata
					MOV		R12, #0x00
					BL drawdata
					B donedigit
					
donedigit			POP {R0, R1,LR}
					BX	LR
					ENDP

					EXPORT x_gofirst
x_gofirst			PROC
					PUSH {R0, R1,LR}
					
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0,#0x40; D/C=0
					STR R0, [R1]
					
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x80
					STR R0, [R1]
					BL waitforsend
	
					POP {R0, R1,LR}
					BX LR
					ENDP
						
					EXPORT y_gofirst
y_gofirst			PROC
					PUSH {R0, R1,LR}
					
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0,#0x40; D/C=0
					STR R0, [R1]
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x40
					STR R0, [R1]
					BL waitforsend
	
					POP {R0, R1,LR}
					BX LR
					ENDP
						
					EXPORT y_gosecond
y_gosecond			PROC
					PUSH {R0, R1,LR}
					
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0,#0x40; D/C=0
					STR R0, [R1]
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x41
					STR R0, [R1]
					BL waitforsend
	
					POP {R0, R1,LR}
					BX LR
					ENDP					
					
					
					EXPORT y_gothird
y_gothird			PROC
					PUSH {R0, R1,LR}
					
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0,#0x40; D/C=0
					STR R0, [R1]
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x42
					STR R0, [R1]
					BL waitforsend
	
					POP {R0, R1,LR}
					BX LR
					ENDP

					EXPORT y_gofourth
y_gofourth			PROC
					PUSH {R0, R1,LR}
					
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0,#0x40; D/C=0
					STR R0, [R1]
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x43
					STR R0, [R1]
					BL waitforsend
	
					POP {R0, R1,LR}
					BX LR
					ENDP
						
					EXPORT y_gofifth
y_gofifth			PROC
					PUSH {R0, R1,LR}
					
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0,#0x40; D/C=0
					STR R0, [R1]
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x44
					STR R0, [R1]
					BL waitforsend
	
					POP {R0, R1,LR}
					BX LR
					ENDP
						
					EXPORT y_gosixth
y_gosixth			PROC
					PUSH {R0, R1,LR}
					
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0,#0x40; D/C=0
					STR R0, [R1]
					
					LDR R1, =SPI_SSI0_DR
					MOV R0, #0x45
					STR R0, [R1]
					BL waitforsend
	
					POP {R0, R1,LR}
					BX LR
					ENDP						

ClrAll				PROC			;
					PUSH {R0, R1,R2,LR}
					LDR R1, =GPIO_PORTA_DATA
					LDR R0, [R1]
					BIC R0,#0x40; D/C=0
					STR R0, [R1]
							
					MOV R2, #504
					MOV32 R12, #0x00	;Drawing spaces for 6X84=504times
loopCLR				BL drawdata
					SUBS R2,#1				
					BNE loopCLR
					
					BL x_gofirst
					BL y_gofirst
					
					POP {R0, R1,R2,LR}	
					BX LR
					ENDP
					
					EXPORT Timer1Init
Timer1Init			PROC
					PUSH {R0,R1,R2}	
					;Timer 0 initialization
					LDR R1, =SYSCTL_RCGCTIMER ; Start Timer1
					LDR R2, [R1]
					ORR R2, R2, #0x02
					STR R2, [R1]
					NOP ; allow clock to settle
					NOP
					NOP
					
					LDR R1, =TIMER1_CTL ; disable timer during setup 
					LDR R2, [R1]
					BIC R2, R2, #0x01; Only enable bit clear
					STR R2, [R1]
					
					LDR R1, =TIMER1_CFG ; set 32 bit mode
					MOV R2, #0x00
					STR R2, [R1]
					
					LDR R1, =TIMER1_TAMR
					MOV R2, #0x02 ; set to periodic , count down
					STR R2, [R1]
					
					LDR R1, =TIMER1_TAILR ; count value
					LDR R2, =16000000; for 16 Mhz clock 16000000 counts provides us 1 sec
					STR R2, [R1]
					
					LDR R1, =TIMER1_IMR ; No interrupt enabled, we will poll to check if when it counts 1 sec 
					MOV R2, #0x00
					STR R2, [R1]
					
					LDR R1, =TIMER1_CTL
					LDR R2, [R1]
					ORR R2, R2, #0x03 ; set bit0 to enable
					STR R2, [R1] ; and bit 1 to stall on debug
					
					
					POP {R0,R1,R2}	
					BX LR
					ENDP

					END