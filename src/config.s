					AREA 	sddata, READONLY, DATA
;----------------------------------------------------------------------------------------------
;SWs and LEDs INITIALIZATION 
GPIO_PORTF_DATA 	EQU 0x400253FC; inputs: PF0(SW2), PF4(SW1), outputs: PF1(RED), PF2(BLUE), PF3(GREEN); 

	
GPIO_PORTF_LOCK		EQU 0x40025520;
GPIO_PORTF_CR		EQU 0x40025524;
GPIO_PORTF_DIR 		EQU 0x40025400
GPIO_PORTF_AFSEL 	EQU 0x40025420
GPIO_PORTF_DEN 		EQU 0x4002551C
GPIO_PORTF_PUR		EQU	0x40025510
	
GPIO_PORTF_IS		EQU 0x40025404
GPIO_PORTF_IBE		EQU 0x40025408	
GPIO_PORTF_IEV		EQU 0x4002540C
GPIO_PORTF_IM		EQU 0x40025410
GPIO_PORTF_RIS		EQU 0x40025414
GPIO_PORTF_ICR		EQU 0x4002541C
	
SYSCTL_RCGCGPIO 	EQU 0x400FE608
	
IOB_F				EQU	0x0E;
	
GPIO_PORTF_DATA_SWs 	EQU 0x40025044; inputs: PF0(SW2), PF4(SW1) 
;----------------------------------------------------------------------------------------------

;ADC INITIALIZATION FOR SAMPLING
;For GPIO
GPIO_PORTE_DATA 	EQU 0x40024020; Only PE3 will be used, PE3 is analog input for mic
GPIO_PORTE_DIR 		EQU 0x40024400
GPIO_PORTE_AFSEL 	EQU 0x40024420
GPIO_PORTE_DEN 		EQU 0x4002451C
GPIO_PORTE_AMSEL 	EQU 0x40024528
GPIO_PORTE_PCTL 	EQU 0x4002452C
	
IOB_E				EQU	0x0; PE3 input is input to our analog mic signal

;For ADT
ATD_ADC0_ACTSS 		EQU 0x40038000
ATD_ADC0_EMUX 		EQU 0x40038014
ATD_ADC0_SSMUX3 	EQU 0x400380A0
ATD_ADC0_SSCTL3 	EQU 0x400380A4
ATD_ADC0_PC			EQU 0x40038FC4
ATD_ADC0_IM 		EQU 0x40038008

ATD_ADC0_PSSI 		EQU 0x40038028
ATD_ADC0_RIS 		EQU 0x40038004
ATD_ADC0_FIFO3 		EQU 0x400380A8
ATD_ADC0_ISC 		EQU 0x4003800C
	
SYSCTL_RCGCADC	 	EQU 0x400FE638
SYSCTL_PRADC		EQU 0x400FEA38
;----------------------------------------------------------------------------------------------
;
NVIC_ST_CTRL 		EQU 0xE000E010
NVIC_ST_RELOAD 		EQU 0xE000E014
NVIC_ST_CURRENT 	EQU 0xE000E018
SHP_SYSPRI3 		EQU 0xE000ED20
	
					AREA 	cfg, READONLY, CODE
					THUMB
					EXTERN 	__main
					EXTERN	DELAY100

;Port F initialization
					EXPORT	initPortF
initPortF			PROC
					PUSH {R0, R1};Saving registers to be used in initialization
					
					
					LDR R1, =SYSCTL_RCGCGPIO
					LDR R0, [R1]
					ORR R0, R0 , #0x20; only port F will be clocked and used
					STR R0, [R1]
					NOP
 					NOP
 					NOP
					
					LDR R1, =GPIO_PORTF_LOCK
					LDR R0, =0x4C4F434B; Unlocking for PF0
					STR R0, [R1]
					LDR R1, =GPIO_PORTF_CR
					LDR R0, [R1]
					ORR R0, #0x1F ; committed for pins 
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTF_DIR
					LDR R0, [R1]
					BIC R0, #0xFF;First directions are cleared to start from a clean/default point(default is all pins are inputs)
					ORR R0, #IOB_F
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTF_AFSEL
					LDR R0, [R1]
					BIC R0, #0x1F; There will be no alternate function, so AFSEL will be zero
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTF_PUR
					LDR R0, [R1]
					ORR R0, #0x11; PF4 needs PUR enabled
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTF_DEN
					LDR R0, [R1]
					ORR R0, #0x1F; We need digital configuration
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTF_IS
					LDR R0, [R1]
					ORR R0, #0x11; Level sensitive for PF4 and PF0
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTF_IBE
					LDR R0, [R1]
					BIC R0, #0xFF; Not both edges
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTF_IEV
					LDR R0, [R1]
					BIC R0, #0xFF; Low level will set the flags since 0 means the key is pressed
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTF_IM
					LDR R0, [R1]
					BIC R0, #0xFF; We will be using polling
					STR R0, [R1]
			
					POP {R0, R1}
					BX	LR
					ENDP
;End of initialization of Port F for SW0, SW1
;----------------------------------------------------------------------------------------------

;;ADC INITIALIZATION - PE3 is ANALOG INPUT
;GPIO init for ADC
					EXPORT	initPortE
initPortE			PROC
					PUSH {R0, R1};Saving registers to be used in initialization
					LDR R1, =SYSCTL_RCGCGPIO
					LDR R0, [R1] 
					ORR R0, #0x10; only port E will be clocked and used
					STR R0, [R1]
					NOP
 					NOP
 					NOP
					
					LDR R1, =GPIO_PORTE_DIR
					LDR R0, [R1]
					BIC R0, #0xFF;First directions are cleared to start from a clean/default point(default is all pins are inputs)
					ORR R0, #IOB_E
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTE_AFSEL
					LDR R0, [R1]
					BIC R0, #0xFF;
					ORR R0, #0x08; AFSEL is enabled for PE3
					STR R0, [R1]
					
					LDR R1, =GPIO_PORTE_DEN
					LDR R0, [R1]
					BIC R0, #0xFF; We need analog configuration
					STR R0, [R1]
					
					
					LDR R1, =GPIO_PORTE_AMSEL
					LDR R0, [R1]
					ORR R0, #0x08; Analog mode selected for PE3
					STR R0, [R1]
					
					
					POP {R0, R1}
					BX	LR
					ENDP
;End of initialization of Port E						

;ADC initialization for ADC0 (SS3)
					EXPORT	initADC
initADC				PROC
					PUSH {R0, R1}
					LDR R1, =SYSCTL_RCGCADC
					LDR R0, [R1] 
					ORR R0, #0x01; only ADC0 will be clocked and used
					STR R0, [R1]
					NOP
 					NOP
 					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
 					NOP
 					NOP
					NOP
					NOP
					NOP					
					NOP
 					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
 					NOP
 					NOP
					NOP
					NOP
					NOP	; 3 NOP was not enough so added extra NOP instructions to spend extra clock cycles
					
					
					LDR R1, =SYSCTL_PRADC
check				LDR R0, [R1]
					AND R0, #0x1
					CMP R0, #0x1; checking ADC0 is ready or not
					BNE check
					
					LDR R1, =ATD_ADC0_ACTSS 
					LDR R0, [R1]
					BIC R0, #0x08; Disable SS3 before configuration
					STR R0, [R1]
					
					
					LDR R1, =ATD_ADC0_EMUX 
					LDR R0, [R1] 
					BIC R0, #0xF000; 0x0 needs to be written into SS3 part of the register for process triggering 
					STR R0, [R1]		;(after iniate sample step in ADCPSSIit will begin sampling) 
					
					
					LDR R1, =ATD_ADC0_SSMUX3 
					LDR R0, [R1] 
					BIC R0, #0x0F; Write MUX0 (first sample) part 0x0 to select AIN0 (channel selection step)
					STR R0, [R1]
					
					
					LDR R1, =ATD_ADC0_SSCTL3 
					LDR R0, [R1] 
					ORR R0, #0x06; To make it be able to set interrupt flag in RIS (we will use polling), set IE0 bit (bit2)
					STR R0, [R1]	  ; To make sampling stop after one sample, set END0 bit (bit1)
					
					
					LDR R1, =ATD_ADC0_PC
					LDR R0, [R1] 
					ORR R0, #0x7; choosing sample rate as 1M samples per second. We will trigger adc module every 0.5ms to obtain 2k samples per second
					STR R0, [R1]	 
					
					
					LDR R1, =ATD_ADC0_ACTSS 
					LDR R0, [R1] 
					ORR R0, #0x08; Enabling SS3 to make it ready for sampling
					STR R0, [R1]
					
					
					LDR R1, =ATD_ADC0_IM 
					LDR R0, [R1]
					BIC R0, R0, #0x08 ; disable interrupt
					STR R0, [R1]

					POP{R0, R1}
					BX	LR
					ENDP
;End of ADC initialization for ADC0 

					END
