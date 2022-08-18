					AREA 	sddata, READONLY, DATA
;GPIO Initialization for MOTOR. B4 will be the input to the motor
GPIO_PORTB_DATA 	EQU 0x4000503C; B3-B0 configured 
GPIO_PORTB_DIR 		EQU 0x40005400
GPIO_PORTB_AFSEL 	EQU 0x40005420
GPIO_PORTB_AMSEL 	EQU 0x40005528 ;
GPIO_PORTB_PCTL 	EQU 0x4000552C ; 
GPIO_PORTB_DEN 		EQU 0x4000551C
IOB					EQU	0x0F; B3-B0 output 

SYSCTL_RCGCGPIO 	EQU 0x400FE608

					
;;Timer Registers					
; 16/32 Timer Registers
TIMER0_CFG			EQU 0x40030000 ; Config, it is used to choose 16 bit or 32 bit mode
TIMER0_TAMR			EQU 0x40030004 ; Timer mode register
TIMER0_CTL			EQU 0x4003000C ; Control register
TIMER0_IMR			EQU 0x40030018 ; Interrupt mask, setting related bits enables related interrupts
TIMER0_RIS			EQU 0x4003001C ; Timer Interrupt Status
TIMER0_ICR			EQU 0x40030024 ; Timer Interrupt Clear
TIMER0_TAILR		EQU 0x40030028 ; Timer interval
TIMER0_TAPR			EQU 0x40030038 ; Prescale register
TIMER0_TAR			EQU	0x40030048 ; Timer register

SYSCTL_RCGCTIMER 	EQU 0x400FE604 ; GPTM Gate Control
	
	
MID					EQU 15000; 15ms mid value, initial
	
;Nested Vector Interrupt Controller registers
NVIC_EN0_INT19 EQU 0x00080000 ; Interrupt 19 enable
NVIC_EN0 EQU 0xE000E100 ; IRQ 0 to 31 Set Enable Register
NVIC_PRI4 EQU 0xE000E410 ; IRQ 16 to 19 Priority Register
;Timer clock is 1Mhz, so T=1us	


GPIO_PORTF_RIS		EQU 0x40025414; for inputs: PF0(SW2), PF4(SW1), we will change direction according to interrupt flags
GPIO_PORTF_ICR		EQU 0x4002541C


					AREA 	cfg, READONLY, CODE
					THUMB
					EXPORT 	Timer0Init
					EXPORT  My_Timer0A_Handler
						
;Port B initialization for MOTOR
					EXPORT	initPortB
initPortB			PROC
					PUSH {R0, R1};Saving registers to be used in initialization
					LDR R1, =SYSCTL_RCGCGPIO
					LDR R0, [R1]
					ORR R0, R0 , #0x02; only port B will be clocked and used
					STR R0, [R1]
					NOP
 					NOP
 					NOP
					
					LDR R1, =GPIO_PORTB_DIR
					LDR R0, [R1]
					BIC R0, #0xFF;First directions are cleared to start from a clean/default point(default is all pins are inputs)
					ORR R0, #IOB
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTB_AFSEL
					LDR R0, [R1]
					;ORR R0, #0x10; We need to enable alternate funcs for B4
					BIC R0, #0xFF
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTB_PCTL ; Enabling alternate function T1CCGP0 (Timer 1)
					LDR R0, [R1]
					;ORR R0, R0, #0x00070000
					MOV R0, #0
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTB_AMSEL ; disable analog
					MOV R0, #0
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTB_DEN
					LDR R0, [R1]
					ORR R0, #0xFF; We need digital configuration 
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTB_DATA
					MOV R0, #0x8
					STR R0, [R1]
					
					POP {R0, R1}
					BX	LR
					ENDP			

;Timer Initialization						
Timer0Init			PROC
					PUSH {R0,R1,R2}	
					;Timer 0 initialization
					LDR R1, =SYSCTL_RCGCTIMER ; Start Timer0
					LDR R2, [R1]
					ORR R2, R2, #0x01
					STR R2, [R1]
					NOP ; allow clock to settle
					NOP
					NOP
					
					LDR R1, =TIMER0_CTL ; disable timer during setup 
					LDR R2, [R1]
					BIC R2, R2, #0x01; Only enable bit clear
					STR R2, [R1]
					
					LDR R1, =TIMER0_CFG ; set 16 bit mode
					MOV R2, #0x04
					STR R2, [R1]
					
					LDR R1, =TIMER0_TAMR
					MOV R2, #0x02 ; set to periodic , count down
					STR R2, [R1]
					
					LDR R1, =TIMER0_TAILR ; count value
					LDR R2, =MID; initial speed is mid speed
					STR R2, [R1]
					LDR R1, =TIMER0_TAPR
					MOV R2, #15 ; divide clock by 16 to
					STR R2, [R1] ; get 1 us clocks
					LDR R1, =TIMER0_IMR ; enable time out interrupt
					MOV R2, #0x01
					STR R2, [R1]
					
					
					; Configure interrupt priorities
					; Timer0A is interrupt #19.
					; Interrupts 16-19 are handled by NVIC register PRI4.
					; Interrupt 19 is controlled by bits 31:29 of PRI4.
					; set NVIC interrupt 19 to priority 2
					LDR R1, =NVIC_PRI4
					LDR R2, [R1]
					AND R2, R2, #0x00FFFFFF ; clear interrupt 19 priority
					ORR R2, R2, #0x40000000 ; set interrupt 19 priority to 2
					STR R2, [R1]
					; NVIC has to be enabled
					; Interrupts 0-31 are handled by NVIC register EN0
					; Interrupt 19 is controlled by bit 19
					; enable interrupt 19 in NVIC
					LDR R1, =NVIC_EN0
					MOVT R2, #0x08 ; set bit 19 to enable interrupt 19 (MOVT: move top yapiyor, it
					;moves to MSB half and makes LSB half)
					STR R2, [R1]
					
					
					; Enable timer
					LDR R1, =TIMER0_CTL
					LDR R2, [R1]
					ORR R2, R2, #0x03 ; set bit0 to enable
					STR R2, [R1] ; and bit 1 to stall on debug

					BX LR ; return
					POP {R0, R1,R2}
					ENDP
						
						
						
;---------------------------------------------------
;Timer ISR (One step in each Timer0 ISR call)
My_Timer0A_Handler	PROC; tusu direkt burada check et.
					PUSH{R0,R1,R2,R7}
					;R10 will be a flag to be used for debouncing
					;R3 holds the direction information, #0 means ccw, #1 means cw
					
					;We need to check if SW1 or SW2 is pressed
					LDR R1, =GPIO_PORTF_RIS
					LDR R0, [R1]
					AND R0, #0x11; To obtain switch interrupt flags, 1 means they are pressed, 0 means they are not pressed
					;PF0(sw2) basilinca ccw, PF4(SW1) cw
					MOV R2, R0;
					AND R2, #0x1; obtaining only sw2 (ccw) bit
					CMP R2, #0x1;
					
					BNE skipintpclear1
					LDR R0,=GPIO_PORTF_ICR		
					LDR R0, [R1]
					BIC R0, #0x1; Clear interrupt flag for SW2
					STR R0, [R1]
					
skipintpclear1		CMP R2, #0x1;
					ADDEQ R10, #1;
					CMP R10, #5; if we take a button is pressed input ten times then we change the direction
					ITT EQ
					MOVEQ R11, #0
					MOVEQ R10, #0
			
			
			
					LDR R1, =GPIO_PORTF_RIS
					LDR R0, [R1]
					
					MOV R3, R0;
					AND R3, #0x10; obtaining only sw1 (cw) bit 
					CMP R3, #0x10;
					
					BNE skipintpclear2
					LDR R0,=GPIO_PORTF_ICR		
					LDR R0, [R1]
					BIC R0, #0x10; Clear interrupt flag for SW1
					STR R0, [R1]
					
					
skipintpclear2		CMP R3, #0x10;
					ADDEQ R10, #1;
					CMP R10, #5
					ITT EQ
					MOVEQ R11, #1
					MOVEQ R10, #0
					

detdirect			CMP R11, #1
					BEQ clock_c1
					
					CMP R11, #0
					BEQ counter_c1

;Counter clockwise steps. Each ISR call we will advance one step in motor with "B finish"

counter_c1			LDR R1, =GPIO_PORTB_DATA
					LDR R0, [R1]
					EORS R7 ,R0, #0x1; Since EORS R0, #0x1 changes content of R0 I use R7 as result register but I wont use its content
									 ;It is just for comparison reason
					BNE	counter_c2
					MOV R0, #0x2; 
					STR R0, [R1] 
					B finish
					
counter_c2			LDR R0, [R1]
					EORS R7, R0, #0x2
					BNE	counter_c3
					MOV R0, #0x4; 
					STR R0, [R1]
					B finish
					
					
counter_c3			LDR R0, [R1]
					EORS R7, R0, #0x4
					BNE	counter_c4
					MOV R0, #0x8; 
					STR R0, [R1]
					B finish					

counter_c4			LDR R0, [R1]
					EORS R7, R0, #0x8
					BNE	counter_c1
					MOV R0, #0x1; 
					STR R0, [R1]
					B finish



;Clockwise steps
clock_c1			LDR R1, =GPIO_PORTB_DATA
					LDR R0, [R1]
					EORS R7,R0, #0x8
					BNE	clock_c2
					MOV R0, #0x4; 
					STR R0, [R1] 
					B finish
					
clock_c2			LDR R0, [R1]
					EORS R7,R0, #0x4
					BNE	clock_c3
					MOV R0, #0x2; 
					STR R0, [R1]
					B finish
					
					
clock_c3			LDR R0, [R1]
					EORS R7,R0, #0x2
					BNE	clock_c4
					MOV R0, #0x1; 
					STR R0, [R1]
					B finish					

clock_c4			LDR R0, [R1]
					EORS R7,R0, #0x1
					BNE	clock_c1
					MOV R0, #0x8; 
					STR R0, [R1]
					B finish
					
					

finish				LDR R1, =TIMER0_ICR ; 
					LDR R0, [R1]
					ORR R0, R0, #0x1 ; set bit 2 of ICR to clear capture interrupt bit in RIS, to be able to catch next capture interrupt
					STR R0, [R1]

					POP{R0,R1,R2, R7}			
					BX 	LR 
					ENDP
;---------------------------------------------------
					END
