;*************************************************************** 
;* Feladat: 
;* R�vid le�r�s:
; 
;* Szerzok: 
;* M�rocsoport: <merocsoport jele>
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
.def lux = r17 ; F�ny�rz�kelo
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

;< t�bbi IT kezelo a f�jl v�g�re! >

DUMMY_IT:	
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< t�bbi IT kezelo a f�jl v�g�re! >

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
;< ki- �s bemenetek inicializ�l�sa stb > 
	
	
	ldi flag, 0 ; Ha TCNT2 0xFF akkor 1 ha 0x00 akkor 0
	
	ldi sotet, 0b11000000	; Enn�l az �rt�kn�l kisebb m�r s�t�t
	
	;F�ny�rz�kelo init

	ldi temp, 0b11100010
		  ;			  11......... Az �sszehasonl�t�shoz a bels� 2.56V referencia�rt�k lesz haszn�lva
		  ;			  ..1........ Balra igaz�tott bitek az ADC dupla regiszterben. L�sd man 246. oldal alja.
		  ;			  ...00010... 2. pin, vagyis f�ny�rz�kel� kiv�lasztva
		  out ADMUX, temp
		  ldi temp, 0b11100111
		  ;			  1.......... ADEN: ADC Enable
		  ;			  .1......... ADSC: ADC Start Conversion
		  ;			  ..1........ ADFR: ADC Free Running Select
		  ;			  ...0....... ADIF: ADC Interrupt Flag
		  ;			  ....0...... ADIE: ADC Interrupt Enable (akarsz -e interrupot)
		  ;			  .....111... ADPS2:0: ADC Prescaler Select Bits (128-as oszt�)
		  out ADCSR, temp

	;LED init

	ldi temp, 0xFF
	out DDRC, temp
	ldi temp, 0b00000000
	out PORTC, temp
	mov led, temp
	
	;PWM
	
	ldi pwm, 0x00 ; kis kit�lt�si t�nyez�j� jel 
	out OCR0, pwm  
	
	ldi temp, 0xFF
	out OCR2, temp	

	sei ; glob�lis IT enged�lyez�se
	
	
	
	ldi counter, 0x80 	; 
DELAY:					; V�rakoz�s f�ny�rz�kel�re	
	dec counter			;
	brne DELAY 			;
	
	call LUX_M		;
	cp lux, sotet	; Ha kell�en s�t�t van akkor esti �zemm�d
	brlo ESTE		;
;*************************************************************** 
;* MAIN program, Endless loop part
 
NAPPAL:  

	;L�mpa1	L�mpa2
	;ZSPP	ZSPP
	;1000	0011 	Z_PP ( Z�ld-PirosPiros )
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
	out TCCR2, temp		; Timer/Counter reset �s le�ll�t�s
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
	brts UGRIK			; PP_PP �llapotban 2 ir�nyba lehet v�ltani. PP_PP vagy PPS_PP.
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
	ldi counter2, 0xFF 	; Id�z�t�s
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
	set					; T flag, hogy NAPPAL_LOOP-ban �tugorja PP_PPS-t
	
	ldi counter, 0xFF 
	ldi counter2, 0xFF 
	ldi counter3, 0x28 
	jmp LOOP

ESTE:
	clt
	
	ldi temp, 0b01001100 ; Fast PWM m�d, 64-es el�oszt� 
	out TCCR0, temp
	
	ldi temp, 0b00001101 ; CNT m�d, 1024-es oszt�
	out TCCR2, temp
 						
	ldi temp, 0b10000011 	; Timer/Counter0 kompar�l�skor �s t�lcsordul�skor megszak�t�s. Timer/Counter2 kompar�l�skor megszak�t�s	
	out TIMSK, temp		
	
ESTE_LOOP:	
	call LUX_M
	cp lux, sotet	;
	brlo ESTE_LOOP	; Ha m�g s�t�tvan akkor maradunk
	jmp NAPPAL		; De ha m�r vil�gos van akkor v�ltunk nappalra
	
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
	clt					; T flag, hogy ne hagyja ki PP_PPS �llapotot
	
	ldi counter, 0xFF 
	ldi counter2, 0xFF 
	ldi counter3, 0x28 
	jmp LOOP

LUX_M:
	in lux, ADCH	; F�nyer�
	ret
	
LOOP:

	call LUX_M		;	
	cp lux, sotet	; Hogy ne kelljen v�rni �jabb f�nyer� vizsg�latra
	brlo ESTE		; am�g a LOOP lej�r
	
	dec counter
	brne LOOP 
	dec counter2 
	brne LOOP	
	dec counter3
	brne LOOP
	
	jmp NAPPAL_LOOP

T0CM_IT: 					; ha TCNT0 == OCR0, akkor LED kikapcsol�sa 

	push temp 
	in temp, SREG 
	push temp
	
	ldi led, 0b00000000 
	
	jmp END_IT 				; a megszak�t�sb�l val� visszat�r�s azonos 

T0OF_IT:					; ha TCNT0 == TOP, akkor LED bekapcsol�sa 

	push temp 
	in temp, SREG 
	push temp 
	
	ldi led, 0b01000100 

END_IT: 					; megszak�t�sb�l visszat�r�s 

	out PORTC, led

	pop temp 
	out SREG, temp 
	pop temp 
	reti
	
T2CM_IT: 				; Ha v�gzett a sz�mol�ssal Timer/Counter2 

	push temp 
	in temp, SREG 
	push temp 

	cpi pwm, 0xFF		; Ha pwm el�rte 0xFF-et akkor cs�kkenjen 
	breq CSOKKEN		;
	
	cpi pwm, 0			; Ha pwm el�rte 0x00-�t akkor n�jj�n
	breq NO
	
	jmp SZAMOL			; Ha nincs v�gkit�r�s akkor folytassa asz�mol�st
	
CSOKKEN:
	ldi flag, 1			; 0xFF-n�l flag=1
	jmp SZAMOL
NO:
	ldi flag, 0			; 0x00-n�ll flag=0
SZAMOL:
	sbrc flag, 0		; Ha flag=1 akkor cs�kkent
	dec pwm
	
	sbrs flag, 0		; Ha flag=0 akkor n�vel 
	inc pwm
	
	out OCR0, pwm		; OCR0 �rt�k friss�t�se
	
	pop temp 
	out SREG, temp 
	pop temp 
	reti
