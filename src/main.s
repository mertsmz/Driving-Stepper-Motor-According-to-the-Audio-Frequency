					AREA 	sddData, READONLY, DATA

AMP_TH 			EQU 0x3FF; 
FRQ_TH_LOW		EQU 300;
FRQ_TH_HIGH		EQU 750;

GPIO_PORTF_DATA_LEDS 	EQU 0x40025038; To light up RGB leds	

TIMER0_CTL			EQU 0x4003000C
TIMER0_TAILR		EQU 0x40030028 
MOT_SLOW			EQU 30000; 30ms 
MOT_MID				EQU 15000; 15ms
MOT_FAST			EQU 7500; 7.5ms
	
;To draw  values on LCD
GPIO_PORTA_DATA 	EQU 0x400043F0
SPI_SSI0_DR			EQU 0x40008008
;To check time since last LCD update
TIMER1_RIS			EQU 0x4003101C ; Timer Interrupt Status
TIMER1_ICR			EQU 0x40031024 ; Timer Interrupt Clear
TIMER1_TAR			EQU	0x40031048
	
			AREA main, READONLY, CODE
			THUMB
			EXTERN arm_cfft_q15
			EXTERN arm_cfft_sR_q15_len256
			EXPORT __main
			
			EXTERN 	initPortF
			EXTERN  initPortE
			EXTERN	initADC			
			EXTERN Init_SysTick
			EXTERN findmagnitudes
			EXTERN finddominant
			;For motor
			EXTERN initPortB
			EXTERN Timer0Init
			;For LCD
			EXTERN initPortA
			EXTERN 	SPIinit
			EXTERN  LCDinit
			EXTERN drawdigit
			EXTERN drawdata
			EXTERN y_gosecond
			EXTERN y_gothird
			EXTERN y_gofourth
			EXTERN y_gofifth
			EXTERN x_gofirst
			EXTERN Timer1Init



__main		PROC
			MOV32 R5, #0x20000400; This is for storing sampling results in memory
			BL initPortF ; for direction changes SW0,SW1 and RGB LEDS
			BL initPortE; for ADC
			BL initADC;  initates ADC0(SS3) and starts sampling
			;Motor initialization
			BL initPortB
			MOV R10, #0; R10 will be used in changing motor direction process in Timer0Init for debouncing
			MOV R11, #0; R11 will hold the direction information.
			BL Timer0Init
			;LCD initialization
			BL initPortA
			BL	SPIinit
			BL	LCDinit
			BL Timer1Init
			;;
			BL Init_SysTick
			CPSIE I
	
;Displaying the thresholds on LCD
			
			;At first the column names are written on LCD; A_TH, FL_TH, FH_TH
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x09
			BL drawdata
			MOV R12,#0x09
			BL drawdata
			MOV R12,#0x09
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x00
			BL drawdata
			MOV R12,#0x40
			BL drawdata
			MOV R12,#0x40
			BL drawdata
			MOV R12,#0x41
			BL drawdata
			MOV R12,#0x01
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x01
			BL drawdata
			MOV R12,#0x01
			BL drawdata
			MOV R12,#0x00
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x08
			BL drawdata
			MOV R12,#0x08
			BL drawdata
			MOV R12,#0x08
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12, #0x00
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			
			
			
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x09
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			MOV R12,#0x00
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x40
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			MOV R12,#0x00
			BL drawdata
			MOV R12,#0x40
			BL drawdata
			BL drawdata
			MOV R12,#0x41
			BL drawdata
			MOV R12,#0x01
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x01
			BL drawdata
			BL drawdata
			MOV R12,#0x00
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x08
			BL drawdata
			BL drawdata
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12, #0x00
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			
			
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x09
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			MOV R12,#0x00
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x08
			BL drawdata
			BL drawdata
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x00
			BL drawdata
			MOV R12,#0x40
			BL drawdata
			BL drawdata
			MOV R12,#0x41
			BL drawdata
			MOV R12,#0x01
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x01
			BL drawdata
			BL drawdata
			MOV R12,#0x00
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			MOV R12,#0x08
			BL drawdata
			BL drawdata
			BL drawdata
			MOV R12,#0x7F
			BL drawdata
			
			BL y_gosecond
			BL x_gofirst
			
			;Obtaining decimal digits for a num
			;The max val for amplitude threshold is 0xFFFF=65535 it is 5 digit decimal num
			LDR R1, =10000; to obtain individual digits
			LDR R4, =10
			LDR R0, =AMP_TH
			UDIV R12, R0, R1; first digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R4
			MUL  R12 ,R6, R1
			MUL  R12, R12, R4
			SUB R0, R12;
			UDIV R12, R0, R1; second digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R4
			MUL  R12 ,R6, R1
			MUL  R12, R12, R4
			SUB R0, R12;
			UDIV R12, R0, R1; third digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R4
			MUL  R12 ,R6, R1
			MUL  R12, R12, R4
			SUB R0, R12;
			UDIV R12, R0, R1;  fourth digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R4
			MUL  R12 ,R6, R1
			MUL  R12, R12, R4
			SUB R0, R12;
			UDIV R12, R0, R1; fifth digit is in r12
			MOV R6, R12
			BL drawdigit
			MOV R12, #0x00
			BL drawdata; putting spaces
			BL drawdata
			BL drawdata
			BL drawdata
			
			;Displaying Freq Thresholds
			;The max val for freq thresholds is 999 it is 3 digit decimal num
			LDR R1, =100; to obtain individual digits
			LDR R4, =10
			LDR R0, =FRQ_TH_LOW
			
			UDIV R12, R0, R1; first digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R4
			MUL  R12 ,R6, R1
			MUL  R12, R12, R4
			SUB R0, R12;
			UDIV R12, R0, R1; second digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R4
			MUL  R12 ,R6, R1
			MUL  R12, R12, R4
			SUB R0, R12;
			UDIV R12, R0, R1; third digit is in r12
			MOV R6, R12
			BL drawdigit
			MOV R12, #0x00
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata


			
			
			LDR R1, =100; to obtain individual digits
			LDR R4, =10
			LDR R0, =FRQ_TH_HIGH
			
			UDIV R12, R0, R1; first digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R4
			MUL  R12 ,R6, R1
			MUL  R12, R12, R4
			SUB R0, R12;
			UDIV R12, R0, R1; second digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R4
			MUL  R12 ,R6, R1
			MUL  R12, R12, R4
			SUB R0, R12;
			UDIV R12, R0, R1; third digit is in r12
			MOV R6, R12
			BL drawdigit
			MOV R12, #0x00
			BL drawdata
			BL drawdata
			
			;Write measurements columns on LCD: A_M, F_M
			BL y_gofourth; go fourth blank 
			BL x_gofirst
			MOV R12, #0x7F
			BL drawdata
			MOV R12, #0x09
			BL drawdata
			BL drawdata
			BL drawdata
			MOV R12, #0x7F
			BL drawdata
			MOV R12, #0x00
			BL drawdata
			MOV R12, #0x40
			BL drawdata
			BL drawdata
			MOV R12, #0x7F
			BL drawdata
			MOV R12, #0x02
			BL drawdata
			MOV R12, #0x04
			BL drawdata
			BL drawdata
			MOV R12, #0x02
			BL drawdata
			MOV R12, #0x7F
			BL drawdata
			MOV R12, #0x00
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata

			
			
			MOV R12, #0x7F
			BL drawdata
			MOV R12, #0x09
			BL drawdata
			BL drawdata
			BL drawdata
			BL drawdata
			MOV R12, #0x00
			BL drawdata
			MOV R12, #0x40
			BL drawdata
			BL drawdata
			MOV R12, #0x7F
			BL drawdata
			MOV R12, #0x02
			BL drawdata
			MOV R12, #0x04
			BL drawdata
			BL drawdata
			MOV R12, #0x02
			BL drawdata
			MOV R12, #0x7F
			BL drawdata
		
			
			
			
			
			
			
			
;Wait for the systick to be disabled to go fft process;

waitsampling	LDR R1, =0xE000E010; adress of NVIC_ST_CTRL 
				LDR R0, [R1]
				AND R0, #0x1; only obtain enable bit to check if it is still active 
				CMP R0, #0x1
				BEQ waitsampling

			; Fill the input array with ADC data and do other tasks
			; Assuming the array starts with adress 0x2000.0400
			
			; call FFT function 
			LDR 	R0, =arm_cfft_sR_q15_len256 ; The constant table
			LDR 	R1, =0x20000400; Adress of your array
			MOV		R2, #0 ; Inverse FFT flag: 0 for forward FFT
			MOV		R3, #1 ; Bit reversal, use 1
			BL		arm_cfft_q15 ; Branch to the function
			
			BL findmagnitudes
			BL finddominant; R4 holds the dominant(highest amplitude) freq value, R5 holds its amplitude
			
			;;Display the measurements on LCD if 1 sec has passed since last update
			
		
			BL y_gofifth; go fifth blank 
			BL x_gofirst
			
			LDR R1, =TIMER1_RIS			
			LDR R0, [R1]
			AND R0, #0x1; Obtain Timeout bit
			CMP R0, #1
			BNE.W	skip

			
			LDR R1, =10000; to obtain individual digits
			LDR R7, =10
			MOV R0, R5
			UDIV R12, R0, R1; first digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R7
			MUL  R12 ,R6, R1
			MUL  R12, R12, R7
			SUB R0, R12;
			UDIV R12, R0, R1; second digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R7
			MUL  R12 ,R6, R1
			MUL  R12, R12, R7
			SUB R0, R12;
			UDIV R12, R0, R1; third digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R7
			MUL  R12 ,R6, R1
			MUL  R12, R12, R7
			SUB R0, R12;
			UDIV R12, R0, R1;  fourth digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R7
			MUL  R12 ,R6, R1
			MUL  R12, R12, R7
			SUB R0, R12;
			UDIV R12, R0, R1; fifth digit is in r12
			MOV R6, R12
			BL drawdigit
			MOV R12, #0x00
			BL drawdata; putting spaces
			BL drawdata
			BL drawdata
			BL drawdata
			
			;The max val for freq is 999 it is 3 digit decimal num
			LDR R1, =100; to obtain individual digits
			LDR R7, =10
			MOV R0, R4
			
			UDIV R12, R0, R1; first digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R7
			MUL  R12 ,R6, R1
			MUL  R12, R12, R7
			SUB R0, R12;
			UDIV R12, R0, R1; second digit is in r12
			MOV R6, R12
			BL drawdigit
			
			UDIV R1, R1, R7
			MUL  R12 ,R6, R1
			MUL  R12, R12, R7
			SUB R0, R12;
			UDIV R12, R0, R1; third digit is in r12
			MOV R6, R12
			BL drawdigit
			
			
			MOV R12, #0xFF
			BL drawdata
			MOV R12, #0x08
			BL drawdata
			BL drawdata
			BL drawdata
			MOV R12, #0xFF
			BL drawdata
			MOV R12, #0x00
			BL drawdata
			MOV R12, #0x88
			BL drawdata
			MOV R12, #0xC8
			BL drawdata
			MOV R12, #0xC8
			BL drawdata
			MOV R12, #0x98
			BL drawdata
			MOV R12, #0x88
			BL drawdata

			
			LDR R1, =TIMER1_ICR; clear interrupt bit to catch next timeout interrupt
			LDR R0, [R1];
			ORR R0, #0x1
			STR R0, [R1]
			
			LDR R1, =TIMER1_TAR		
			LDR R0, [R1]
skip	
			;;--

			LDR R6, =FRQ_TH_LOW;
			LDR R7, =FRQ_TH_HIGH;
			LDR R8, =AMP_TH;
			
			CMP R5, R8; Amplitude threshold comparison
			BHS ledsmotorupdate
			LDR R1, =GPIO_PORTF_DATA_LEDS; On board leds are on when they are 1
			MOV R0,#0x0; All LEDs OFF
			STR R0, [R1]
			B  newsamp

;Input amplitude is higher than threshold, then we turn ON corresponding LED and adjust motor to one of the 3 levels
ledsmotorupdate	
			CMP R4, R6
			BHS next1
			;freq is low
			;update motor to be slow
			LDR R1, =TIMER0_CTL ; disable timer to update count value
			LDR R2, [R1]
			BIC R2, R2, #0x01; Only enable bit clear
			STR R2, [R1] 
			
			LDR R1, =TIMER0_TAILR ; count value
			LDR R2, =MOT_SLOW;
			STR R2, [R1]
			
			LDR R1, =TIMER0_CTL;enable timer back
			LDR R2, [R1]
			ORR R2, R2, #0x03 ; set bit0 to enable
			STR R2, [R1]
			
			;update led
			LDR R1, =GPIO_PORTF_DATA_LEDS; 
			MOV R0,#0x2; RED ON
			STR R0, [R1]
			B  newsamp
			
			
next1		CMP R4, R7
			BHS next2
			;freq is mid
			LDR R1, =TIMER0_CTL ; disable timer to update count value
			LDR R2, [R1]
			BIC R2, R2, #0x01; Only enable bit clear
			STR R2, [R1] 
			
			LDR R1, =TIMER0_TAILR ; count value
			LDR R2, =MOT_MID;
			STR R2, [R1]
			
			LDR R1, =TIMER0_CTL;enable timer back
			LDR R2, [R1]
			ORR R2, R2, #0x03 ; set bit0 to enable
			STR R2, [R1]
			
			LDR R1, =GPIO_PORTF_DATA_LEDS; 
			MOV R0,#0x8; GREEN ON
			STR R0, [R1]
			B  newsamp
			
			
next2		;freq is high
			LDR R1, =TIMER0_CTL ; disable timer to update count value
			LDR R2, [R1]
			BIC R2, R2, #0x01; Only enable bit clear
			STR R2, [R1] 
			
			LDR R1, =TIMER0_TAILR ; count value
			LDR R2, =MOT_FAST;
			STR R2, [R1]
			
			LDR R1, =TIMER0_CTL;enable timer back
			LDR R2, [R1]
			ORR R2, R2, #0x03 ; set bit0 to enable
			STR R2, [R1]

			LDR R1, =GPIO_PORTF_DATA_LEDS; 
			MOV R0,#0x4; BLUE ON
			STR R0, [R1]


;Going for new sampling
newsamp
			MOV32 R5, #0x20000400; R5 is needed to be hold the starting adress before a new SysTick process begins
			LDR R1, =0xE000E010; adress of NVIC_ST_CTRL 
			MOV R0, #0x03
			STR R0, [R1]
			B waitsampling; go and wait the new sampling results
			

loop		B loop
			ENDP
			END