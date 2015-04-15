;*************************************************************** 
;* Feladat: 
;* Rövid leírás:
; 
;* Szerzők: 
;* Mérőcsoport: <merocsoport jele>
;
;***************************************************************
;* "AVR ExperimentBoard" port assignment information:
;***************************************************************
;*
;* LED0(P):PortC.0          LED4(P):PortC.4
;* LED1(P):PortC.1          LED5(P):PortC.5
;* LED2(S):PortC.2          LED6(S):PortC.6
;* LED3(Z):PortC.3          LED7(Z):PortC.7        INT:PortE.4
;*
;* SW0:PortG.0     SW1:PortG.1     SW2:PortG.4     SW3:PortG.3
;* 
;* BT0:PortE.5     BT1:PortE.6     BT2:PortE.7     BT3:PortB.7
;*
;***************************************************************
;*
;* AIN:PortF.0     NTK:PortF.1    OPTO:PortF.2     POT:PortF.3
;*
;***************************************************************
;*
;* LCD1(VSS) = GND         LCD9(DB2): -
;* LCD2(VDD) = VCC         LCD10(DB3): -
;* LCD3(VO ) = GND         LCD11(DB4): PortA.4
;* LCD4(RS ) = PortA.0     LCD12(DB5): PortA.5
;* LCD5(R/W) = GND         LCD13(DB6): PortA.6
;* LCD6(E  ) = PortA.1     LCD14(DB7): PortA.7
;* LCD7(DB0) = -           LCD15(BLA): VCC
;* LCD8(DB1) = -           LCD16(BLK): PortB.5 (1=Backlight ON)
;*
;***************************************************************

.include "m128def.inc" ; Definition file for ATmega128 
;* Program Constants 
.equ const =$00 ; Generic Constant Structure example  
;* Program Variables Definitions 
.def temp = r16 ; Temporary Register example 
.def cnt1 = r17
.def temp2 = r18
.def led = r19
.def cnt2 = r20
.def minta = r21
.def gomb = r22
.def kapcsolo = r23
;*************************************************************** 
;* Reset & Interrupt Vectors  
.cseg 
.org $0000 ; Define start of Code segment 
	jmp RESET ; Reset Handler, jmp is 2 word instruction 
	jmp DUMMY_IT	; Ext. INT0 Handler
	jmp DUMMY_IT	; Ext. INT1 Handler
	jmp DUMMY_IT	; Ext. INT2 Handler
	jmp DUMMY_IT	; Ext. INT3 Handler
	jmp DUMMY_IT	; Ext. INT4 Handler (INT gomb)
	jmp DUMMY_IT	; Ext. INT5 Handler
	jmp DUMMY_IT	; Ext. INT6 Handler
	jmp DUMMY_IT	; Ext. INT7 Handler
	jmp DUMMY_IT	; Timer2 Compare Match Handler 
	jmp DUMMY_IT	; Timer2 Overflow Handler 
	jmp DUMMY_IT	; Timer1 Capture Event Handler 
	jmp DUMMY_IT	; Timer1 Compare Match A Handler 
	jmp DUMMY_IT	; Timer1 Compare Match B Handler 
	jmp DUMMY_IT	; Timer1 Overflow Handler 
	jmp T1			; Timer0 Compare Match Handler 
	jmp DUMMY_IT	; Timer0 Overflow Handler 
	jmp DUMMY_IT	; SPI Transfer Complete Handler 
	jmp DUMMY_IT	; USART0 RX Complete Handler 
	jmp DUMMY_IT	; USART0 Data Register Empty Hanlder 
	jmp DUMMY_IT	; USART0 TX Complete Handler 
	jmp DUMMY_IT	; ADC Conversion Complete Handler 
	jmp DUMMY_IT	; EEPROM Ready Hanlder 
	jmp DUMMY_IT	; Analog Comparator Handler 
	jmp DUMMY_IT	; Timer1 Compare Match C Handler 
	jmp DUMMY_IT	; Timer3 Capture Event Handler 
	jmp DUMMY_IT	; Timer3 Compare Match A Handler 
	jmp DUMMY_IT	; Timer3 Compare Match B Handler 
	jmp DUMMY_IT	; Timer3 Compare Match C Handler 
	jmp DUMMY_IT	; Timer3 Overflow Handler 
	jmp DUMMY_IT	; USART1 RX Complete Handler 
	jmp DUMMY_IT	; USART1 Data Register Empty Hanlder 
	jmp DUMMY_IT	; USART1 TX Complete Handler 
	jmp DUMMY_IT	; Two-wire Serial Interface Handler 
	jmp DUMMY_IT	; Store Program Memory Ready Handler 

.org $0046

;****************************************************************
;* DUMMY_IT interrupt handler -- CPU hangup with LED pattern
;* (This way unhandled interrupts will be noticed)

;< többi IT kezelő a fájl végére! >

DUMMY_IT:	
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< többi IT kezelő a fájl végére! >

;*************************************************************** 
;* MAIN program, Initialisation part
.org $004B;
RESET: 
;* Stack Pointer init, 
;  Set stack pointer to top of RAM 
	ldi temp, LOW(RAMEND) ; RAMEND = "max address in RAM"
	out SPL, temp 	      ; RAMEND value in "m128def.inc" 
	ldi temp, HIGH(RAMEND) 
	out SPH, temp 

M_INIT:
;< ki- és bemenetek inicializálása stb >

	ldi		temp,0b00001111
			;	   0.......		; FOC=0
			;	   .0..1...		; WGM=10 (CTC mod)
			;	   ..00....		; COM=00 (kimenet tiltva)
			;	   .....111		; CS0=111 (CLK/1024)
	out		TCCR0,temp			; Timer 0 TCCR0 regiszter
	ldi		temp,108			; 11059200Hz/1024 = 108*100
	out		OCR0,temp			; Timer 0 OCR0 regiszter
	ldi		temp,0b00000010
			;	   000000..		; Timer2,1 IT tiltva
			;	   ......1.		; OCIE0=1
			;	   .......0		; TOIE0=0
	out		TIMSK,temp			; Timer IT Mask regiszter
	sei
	
	ldi temp, 0b11010000
	out DDRE, temp
	
	ldi temp, 0x00
	out TCNT0, temp
	
	ldi led, 0xFF
	out DDRC, led
	
RETURN:
	ldi led, 0x18
	out PORTC, led 
	
	ldi cnt1, 0x00
	ldi cnt2, 0x00
;*************************************************************** 
;* MAIN program, Endless loop part
 
Z_P2SEC_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	in gomb, PINE
	bst gomb, 5	
	lsl minta
	bld minta, 0	
	andi minta, 0b00001111
	cpi minta, 0b00001100
	breq GOMB_MEGNYOMVA
	cpi cnt1, 0xC8		; ~2sec
	brne Z_P2SEC_LOOP
	cli
	out TCNT0, temp
	ldi cnt1, 0x00
	sei

Z_P1SEC_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0x64		; ~1sec
	brne Z_P1SEC_LOOP
	cli
	ldi led, 0x14
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	sei
	
S_P_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0x64		; ~1sec
	brne S_P_LOOP
	cli
	ldi led, 0x11
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	sei

P_P6sec_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0x58		; ~6sec
	brne P_P6sec_LOOP
	cpi cnt2, 0x02
	brne P_P6sec_LOOP
	cli
	ldi led, 0x15
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	ldi cnt2, 0x00
	sei

PS_P_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0x64		; ~1sec
	brne PS_P_LOOP
	cli
	ldi led, 0x18
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	sei
	jmp Z_P2SEC_LOOP
	
GOMB_MEGNYOMVA:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0xC8		; ~2sec
	brne GOMB_MEGNYOMVA
	cli
	ldi led, 0x14
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	sei
	
S_P_GOMB_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0x64		; ~1sec
	brne S_P_GOMB_LOOP
	cli
	ldi led, 0x11
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	sei
	
P_P_GOMB_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0x64		; ~1sec
	brne P_P_GOMB_LOOP
	cli
	ldi led, 0x81
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	sei
	
P_Z_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0xC8		; ~2sec
	brne P_Z_LOOP
	cli
	ldi led, 0x01
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	sei
	
P_ZVILLOG_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0x16
	brne P_ZVILLOG_LOOP
	cli
	com led
	ori led, 0b00000001
	andi led, 0b10000001
	out PORTC, led
	ldi cnt1, 0x00
	out TCNT0, temp
	inc cnt2
	cpi cnt2, 0x07
	sei
	brne P_ZVILLOG_LOOP
	cli
	ldi led, 0x11
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	ldi cnt2, 0x00
	sei

P_P1SEC_LOOP:
	lds kapcsolo, PING
	sbrc kapcsolo, 0
	jmp ESTE_LOOP
	cpi cnt1, 0x64		; ~1sec
	brne P_P1SEC_LOOP
	cli
	ldi led, 0x15
	out PORTC, led
	out TCNT0, temp
	ldi cnt1, 0x00
	sei
	jmp PS_P_LOOP

ESTE_LOOP:
	cli
	ldi led, 0x4
	out PORTC, led
	ldi cnt1, 0x00
	ldi cnt2, 0x00
	out TCNT0, temp
	sei
LOOP:
	lds kapcsolo, PING
	sbrs kapcsolo, 0
	jmp RETURN
	cpi cnt1, 0x32
	brne LOOP
	cli
	com led
	andi led, 0b00000100
	out PORTC, led
	ldi cnt1, 0x00
	out TCNT0, temp
	sei
	jmp LOOP
;*************************************************************** 
;* Subroutines, Interrupt routines


T1:
	push temp2
	in temp2, SREG
	push temp2
	inc cnt1
	cpi cnt1, 0x00
	brne skip
	inc cnt2
skip:
	pop temp2
	out SREG, temp2
	pop temp2
	reti
