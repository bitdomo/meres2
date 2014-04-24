;*************************************************************** 
;* Feladat: 
;* Rövid leírás:
; 
;* Szerzok: 
;* Mérocsoport: <merocsoport jele>
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
.def temp =r16 ; Temporary Register example 
.def lux = r17 ; Fényérzékelo
.def led = r18 ; led
.def sotet = r19
.def counter = r20
.def counter2 = r21
.def counter3 = r22
.def pwm = r23
.def flag = r24
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
	jmp T2CM_IT		; Timer2 Compare Match Handler 
	jmp DUMMY_IT	; Timer2 Overflow Handler 
	jmp DUMMY_IT	; Timer1 Capture Event Handler 
	jmp DUMMY_IT	; Timer1 Compare Match A Handler 
	jmp DUMMY_IT	; Timer1 Compare Match B Handler 
	jmp DUMMY_IT	; Timer1 Overflow Handler 
	jmp T0CM_IT		; Timer0 Compare Match Handler 
	jmp T0OF_IT		; Timer0 Overflow Handler 
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

;< többi IT kezelo a fájl végére! >

DUMMY_IT:	
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< többi IT kezelo a fájl végére! >

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
	
	
	ldi flag, 0 ; Ha TCNT2 0xFF akkor 1 ha 0x00 akkor 0
	
	ldi sotet, 0b11000000	; Ennél az értéknél kisebb már sötét
	
	;Fényérzékelo init

	ldi temp, 0b11100010
		  ;			  11......... Az összehasonlításhoz a belsõ 2.56V referenciaérték lesz használva
		  ;			  ..1........ Balra igazított bitek az ADC dupla regiszterben. Lásd man 246. oldal alja.
		  ;			  ...00010... 2. pin, vagyis fényérzékelõ kiválasztva
		  out ADMUX, temp
		  ldi temp, 0b11100111
		  ;			  1.......... ADEN: ADC Enable
		  ;			  .1......... ADSC: ADC Start Conversion
		  ;			  ..1........ ADFR: ADC Free Running Select
		  ;			  ...0....... ADIF: ADC Interrupt Flag
		  ;			  ....0...... ADIE: ADC Interrupt Enable (akarsz -e interrupot)
		  ;			  .....111... ADPS2:0: ADC Prescaler Select Bits (128-as osztó)
		  out ADCSR, temp

	;LED init

	ldi temp, 0xFF
	out DDRC, temp
	ldi temp, 0b00000000
	out PORTC, temp
	mov led, temp
	
	;PWM
	
	ldi pwm, 0x00 ; kis kitöltési tényezõjû jel 
	out OCR0, pwm  
	
	ldi temp, 0xFF
	out OCR2, temp	

	sei ; globális IT engedélyezése
	
	
	
	ldi counter, 0x80 	; 
DELAY:					; Várakozás fényérzékelõre	
	dec counter			;
	brne DELAY 			;
	
	call LUX_M		;
	cp lux, sotet	; Ha kellõen sötét van akkor esti üzemmód
	brlo ESTE		;
;*************************************************************** 
;* MAIN program, Endless loop part
 
NAPPAL:  

	;Lámpa1	Lámpa2
	;ZSPP	ZSPP
	;1000	0011 	Z_PP ( Zöld-PirosPiros )
	;0100	0011	S_PP
	;0011	0011	PP_PP
	;0011	0111	PP_PPS
	;0011	1000	PP_Z
	;0011	0100	PP_S
	;0011	0011	PP_PP
	;0111	0011	PPS_PP
	
	ldi temp, 0 		;
	out TCCR0, temp		;
	out TCNT0, temp		;
	out TCCR2, temp		; Timer/Counter reset és leállítás
	out TCNT2, temp		;
	out TIMSK, temp		;
	ldi pwm, 0x00		;
	out OCR0, pwm		;
	
NAPPAL_LOOP:
	cpi led, 0b00000000
	breq Z_PP			; Ha semmi
	
	cpi led, 0b01000100
	breq Z_PP			; Ha S_S
	
	cpi led, 0b01110011
	breq Z_PP			; Ha PPS_PP
	
	cpi led, 0b10000011
	breq S_PP			; Ha Z_PP
	
	cpi led, 0b01000011
	breq PP_PP			; Ha S_PP

	cpi led, 0b00110011
	brts UGRIK			; PP_PP állapotban 2 irányba lehet váltani. PP_PP vagy PPS_PP.
	breq PP_PPS			; Ha PP_PP
UGRIK:
	cpi led, 0b00110111
	breq PP_Z			; Ha PP_PPS
	
	cpi led, 0b00111000
	breq PP_S			; Ha PP_Z

	cpi led, 0b00110100
	breq PP_PP			; Ha PP_S

	cpi led, 0b00110011
	breq PPS_PP			; Ha PP_PP

	jmp NAPPAL ; Endless Loop  


;*************************************************************** 
;* Subroutines, Interrupt routines

Z_PP:

	ldi led, 0b10000011
	out PORTC, led
	
	ldi counter, 0xFF 	;
	ldi counter2, 0xFF 	; Idõzítés
	ldi counter3, 0x28 	;
	jmp LOOP

S_PP:
	
	ldi led, 0b01000011
	out PORTC, led
	
	ldi counter, 0xFF 
	ldi counter2, 0xFF 
	ldi counter3, 0x28 
	jmp LOOP

PP_PP:

	ldi led, 0b00110011
	out PORTC, led
	
	ldi counter, 0xFF 
	ldi counter2, 0xFF 
	ldi counter3, 0x28 
	jmp LOOP

PP_PPS:

	ldi led, 0b00110111
	out PORTC, led
	set					; T flag, hogy NAPPAL_LOOP-ban átugorja PP_PPS-t
	
	ldi counter, 0xFF 
	ldi counter2, 0xFF 
	ldi counter3, 0x28 
	jmp LOOP

ESTE:
	clt
	
	ldi temp, 0b01001100 ; Fast PWM mód, 64-es elõosztó 
	out TCCR0, temp
	
	ldi temp, 0b00001101 ; CNT mód, 1024-es osztó
	out TCCR2, temp
 						
	ldi temp, 0b10000011 	; Timer/Counter0 komparáláskor és túlcsorduláskor megszakítás. Timer/Counter2 komparáláskor megszakítás	
	out TIMSK, temp		
	
ESTE_LOOP:	
	call LUX_M
	cp lux, sotet	;
	brlo ESTE_LOOP	; Ha még sötétvan akkor maradunk
	jmp NAPPAL		; De ha már világos van akkor váltunk nappalra
	
PP_Z:

	ldi led, 0b00111000
	out PORTC, led
	
	ldi counter, 0xFF 
	ldi counter2, 0xFF 
	ldi counter3, 0x28 
	jmp LOOP

PP_S:

	ldi led, 0b00110100
	out PORTC, led
	
	ldi counter, 0xFF 
	ldi counter2, 0xFF 
	ldi counter3, 0x28 
	jmp LOOP

PPS_PP:
	
	ldi led, 0b01110011
	out PORTC, led
	clt					; T flag, hogy ne hagyja ki PP_PPS állapotot
	
	ldi counter, 0xFF 
	ldi counter2, 0xFF 
	ldi counter3, 0x28 
	jmp LOOP

LUX_M:
	in lux, ADCH	; Fényerõ
	ret
	
LOOP:

	call LUX_M		;	
	cp lux, sotet	; Hogy ne kelljen várni újabb fényerõ vizsgálatra
	brlo ESTE		; amíg a LOOP lejár
	
	dec counter
	brne LOOP 
	dec counter2 
	brne LOOP	
	dec counter3
	brne LOOP
	
	jmp NAPPAL_LOOP

T0CM_IT: 					; ha TCNT0 == OCR0, akkor LED kikapcsolása 

	push temp 
	in temp, SREG 
	push temp
	
	ldi led, 0b00000000 
	
	jmp END_IT 				; a megszakításból való visszatérés azonos 

T0OF_IT:					; ha TCNT0 == TOP, akkor LED bekapcsolása 

	push temp 
	in temp, SREG 
	push temp 
	
	ldi led, 0b01000100 

END_IT: 					; megszakításból visszatérés 

	out PORTC, led

	pop temp 
	out SREG, temp 
	pop temp 
	reti
	
T2CM_IT: 				; Ha végzett a számolással Timer/Counter2 

	push temp 
	in temp, SREG 
	push temp 

	cpi pwm, 0xFF		; Ha pwm elérte 0xFF-et akkor csökkenjen 
	breq CSOKKEN		;
	
	cpi pwm, 0			; Ha pwm elérte 0x00-át akkor nõjjön
	breq NO
	
	jmp SZAMOL			; Ha nincs végkitérés akkor folytassa aszámolást
	
CSOKKEN:
	ldi flag, 1			; 0xFF-nél flag=1
	jmp SZAMOL
NO:
	ldi flag, 0			; 0x00-náll flag=0
SZAMOL:
	sbrc flag, 0		; Ha flag=1 akkor csökkent
	dec pwm
	
	sbrs flag, 0		; Ha flag=0 akkor növel 
	inc pwm
	
	out OCR0, pwm		; OCR0 érték frissítése
	
	pop temp 
	out SREG, temp 
	pop temp 
	reti
