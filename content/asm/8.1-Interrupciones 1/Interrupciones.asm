.include "m2560def.inc"

.org 0x0000
RJMP start

.org 0x0002
RJMP ISR_0 ; INT0 está en 0002, ISR Interrupt Service Routine

.org 0x0004
RJMP ISR_1 ; INT1 está en 0004

.org 0x0006
RJMP ISR_2 ; INT2 está en 0006


start:
	ldi r16, 0x00
	out DDRD, r16	; Configura el puerto D como entrada

	ldi r16, high(RAMEND) ; Se configura el puntero al stack en la última dirección de la RAM
	out SPH, r16		  ; SPH es el registro que apunta al stack, parte alta

	ldi r16, low(RAMEND)
	out SPL, r16          ; SPL es el registro que apunta al stack, parte baja

	ldi r16, 0x01         
	out EIMSK, r16  ; le da 'energia' solo al interruptor INT0 ya que es 01


	ldi r16, 0x03
	sts EICRA, r16  ; flanco ascendente, de low a high, rising. Ya que es 11
    ldi r18, 0x00   ; Se inicializa en 0 el contador
	sei             ; activa las interrupciones globales

ciclo:

	rjmp ciclo   ; Se queda en un ciclo infinito, esperando a que ocurra una interrupción

ISR_0:
    inc r18
    reti    ; reti es un return de la interrupción, es decir, que regresa a la instrucción que se estaba ejecutando 

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
;EIFR External Interrupt Flag Register, IN /OUT. Indica si hubo una interrupción externa, cada bit es una interrupción (INT0, INT1, INT2)
;EIMSK External Interrupt Mask Register, enable, le da 'energia' al tiembre IN /OUT. Habilita las interrupciones externas
;EICRA  Activa la forma en la que se va a detectar las interrupciones, de low a high rising, falling, etc. LDS, STS
;EICRB Si se usan las interrupciones 4 a 7, LDS, STS


; El stack es una estructura de datos que se usa para guardar la dirección de retorno de las subrutinas. 
; RAMEND es la dirección de la última dirección de la memoria RAM, que es 0x21FF.
; Se carga en los registros SPH y SPL para que el stack apunte a la dirección de la última dirección de la memoria RAM.


; En AVR, los vectores de interrupción son direcciones fijas donde el micro salta cuando ocurre una interrupción.