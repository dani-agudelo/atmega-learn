

.org 0x000
rjmp    start
.org 0x002E              ; define la dirección de la interrupción del timer 0
rjmp   ISR_TMR0

start: 
    ; inicializador del stack
	ldi r16, high(RAMEND) 
	out SPH, r16
	ldi r16, low(RAMEND)
    out SPL, r16

    ; configuración del modo de operación del timer
    ldi r20, 0x00
    out TCCR0A, r20 ; modo normal (de 0 a 255 y se desborda), se le envía 0x00

    ; configuración del preescalador
    ldi r21, 0x01  
    out TCCR0B, r21 ; Preescalador de 1 (se cuenta cada ciclo de reloj)

    ; habilitar la interrupción por desbordamiento
    sts TIMSK0, r21 ; 0x01 activa la interrupción por overflow del timer 0

    ; habilitar la interrupción global
    sei            

ciclo:
    ; ciclo infinito esperando la interrupción por desbordamiento
    rjmp ciclo

ISR_TMR0:
    ; se registra el estado del procesador
    reti



; Los timers son contadores que se incrementan en cada ciclo de reloj
; Se pueden configurar para que generen una interrupción cuando llegan a un valor específico
; Un preescalador es un divisor de frecuencia que se puede configurar para que el timer cuente a una frecuencia menor, es
; decir, que cuente cada n ciclos de reloj
; El timer 0 es de 8 bits, el timer 1 y 2 son de 16 bits
; Se puede usar eventos externos y del mismo microcontrolador para que se activen los timers, por 
; ejemplo, un cambio de estado en un pin, o un overflow de otro timer


; El desborde puede generar una bandera

; Necesitamos manejar el 
;TCCR0A, contador normal
;TCCR0B, Modo preescalador, de 1 en 1, 2 en 2...
;TIMSK0, Evento que activa
;OCR0A ; Este es el valor de comparación que se va a comparar con el contador
; TIFR0, bandera de desborde
; TCNT0, contador
; ´pag 128



; codigo: buscamos donde está el timer 0 overflow, está en 0x002E, desde ahi llamo el timer con 
; org, luego configuro los registros  TCCR0A, TCCR0B, TIMSK0, OCR0A, TIFR0, TCNT0, sabiendo que hay
; unos que se ponen con out y otros con sts, ldi, etc. Luego hago un loop infinito para que no se detenga
; el programa, y finalmente hago la rutina de interrupción, que en este caso es un reti, que es un return
; de la interrupción, es decir, que regresa a la instrucción que se estaba ejecutando antes de la interrupción