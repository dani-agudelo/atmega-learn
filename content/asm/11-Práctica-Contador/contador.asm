.org 0x000
rjmp start

.org 0x002E              ; Dirección de la interrupción del Timer 0 (overflow)
rjmp ISR_TMR0

start:
    ; Configuración del stack
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; Configuración del puerto D como salida (para el display de 7 segmentos)
    ldi r16, 0xFF
    out DDRD, r16

    ; Configuración del Timer 0
    ldi r20, 0x00
    out TCCR0A, r20       ; Modo normal
    ldi r21, 0x05         ; Preescalador de 1024
    out TCCR0B, r21
    ldi r22, 0x01
    sts TIMSK0, r22       ; Habilitar interrupción por desbordamiento

    ; Inicialización del contador
    ldi r18, 0x00         ; Contador inicializado en 0

    sei                   ; Habilitar interrupciones globales

ciclo:
    rjmp ciclo            ; Bucle infinito

; Rutina de servicio de interrupción del Timer 0
ISR_TMR0:
    inc r18               ; Incrementar el contador
    cpi r18, 0x10         ; ¿El contador llegó a 16 (0x10)?
    brne continuar        ; Si no, continuar
    ldi r18, 0x00         ; Reiniciar el contador a 0
continuar:
    ldi ZH, high(Display<<1) ; Cargar la dirección de la tabla en Z
    ldi ZL, low(Display<<1)
    add ZL, r18           ; Apuntar al valor correspondiente en la tabla
    lpm r16, Z            ; Leer el valor de la tabla
    out PORTD, r16        ; Mostrar el valor en el display
    reti                  ; Retornar de la interrupción

; Tabla de valores para el display de 7 segmentos (cátodo común)
.org 0x100
Display:
    .db 0b00111111  ; 0
    .db 0b00000110  ; 1
    .db 0b01011011  ; 2
    .db 0b01001111  ; 3
    .db 0b01100110  ; 4
    .db 0b01101101  ; 5
    .db 0b01111101  ; 6
    .db 0b00000111  ; 7
    .db 0b01111111  ; 8
    .db 0b01101111  ; 9
    .db 0b01110111  ; A
    .db 0b01111100  ; b
    .db 0b00111001  ; C
    .db 0b01011110  ; d
    .db 0b01111001  ; E
    .db 0b01110001  ; F

