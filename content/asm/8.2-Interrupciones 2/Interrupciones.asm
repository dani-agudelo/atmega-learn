.include "m2560def.inc"

.org 0x0000
RJMP start

.org 0x0002
RJMP ISR_0 ; INT0 está en 0002, ISR Interrupt Service Routine

.org 0x0004
RJMP ISR_1

.org 0x0006
RJMP ISR_2


start:
	ldi r16, 0x00
	out DDRD, r16
	ldi r16, high(RAMEND) ; apuntador al stack
	out SPH, r16
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, 0x01
	out EIMSK, r16 ; le da 'energia' al interruptor INT0 ya que es 01
	ldi r16, 0x03
	sts EICRA, r16  ; Se detecta de low a high, rising
    ldi r18, 0x00
	sei

ciclo:

	rjmp ciclo

ISR_0:
    inc r18
    reti    ; reti es 

ISR_1:
    nop
    nop
    reti

ISR_2:
    nop
    nop
    reti


; Se guarda en el stack los saltos para que sepa a dónde regresar
; Se guarda el estado del procesador
; SPL y SPH son los registros que apuntan al stack, se usan dos registros porque el stack es de 16 bits (direcciones)
; sei es un interruptor global


; Las interrupciones Externas necesitan 4 registros:
;EIFR External interruption Flag Register, IN /OUT  cada bit nos dice int flag, si es 1 hay una interrupción,  la marca
;EIMSK External interrupt mask register, enable, le da 'energia' al tiembre IN /OUT
;EICRA  Activa la forma en la que se va a detectar, LDS, STS, de low a high rising, al contrario 
;EICRB


