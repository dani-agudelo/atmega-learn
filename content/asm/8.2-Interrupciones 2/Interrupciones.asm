.org 0x0000
rjmp start
.org 0x0002
rjmp ISR_0
.org 0x0004
rjmp ISR_1
.org 0x0006
rjmp ISR_2

start:
    ldi r16, 0x00
	out DDRD, r16
	ldi r16,high(RAMEND)   ;apuntador a stack
	out SPH,r16
	ldi r16,low(RAMEND)
	out SPL,r16
	ldi r16, 0x03
	out EIMSK, r16         ; habilita la interrupción externa INT0 y INT1 (11)
	ldi r16, 0x0F          
	sts EICRA, r16         ; INT0 y INT1 se activan de low a high, rising 11 11
	ldi r18, 0x00          ; se inicializa en 0 el contador
	sei     

ciclo:
	;casa
    rjmp ciclo

ISR_0:
	inc r18
	reti
ISR_1:
	dec r18
	reti

ISR_2:
	nop
	nop
	reti