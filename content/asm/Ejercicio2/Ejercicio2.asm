.include "m2560def.inc"

    .org 0x0000
    RJMP main

main:
    ; Configurar el puerto B como salida (1)
    LDI R16, 0xFF
    OUT DDRB, R16

    ; Configurar el puerto C como entrada (0)
    LDI R16, 0x00
    OUT DDRC, R16

    ; Inicializar estado (0 = bajando, 1 = subiendo)
    LDI R17, 0x00  ; Estado inicial: bajando

loop:
    ; Leer el nivel del depósito desde el puerto C
    IN R16, PINC   ; 00001111

    ; Mostrar el nivel en la barra de LEDs (4 bits menos significativos)
    ANDI R16, 0x0F
    OUT PORTB, R16   

    ; Determinar si el nivel está subiendo o bajando
    CPI R16, 0x0F   ; ¿Nivel máximo?
    BREQ set_bajando

    CPI R16, 0x00   ; ¿Nivel mínimo?
    BREQ set_subiendo

    ; Control de la bomba según el estado
    CPI R17, 0x01  ; Si está subiendo
    BREQ check_bomba_encendida

    ; Si está bajando, la bomba debe estar apagada
    RJMP bomba_apagada

set_subiendo:
    LDI R17, 0x01   ; Cambiar estado a subiendo
    RJMP bomba_encendida

set_bajando:
    LDI R17, 0x00   ; Cambiar estado a bajando
    RJMP bomba_apagada

check_bomba_encendida:
    ; La bomba solo se enciende en 0000, 0001, 0011, 0111 si está subiendo
    CPI R16, 0x00
    BREQ bomba_encendida

    CPI R16, 0x01
    BREQ bomba_encendida

    CPI R16, 0x03
    BREQ bomba_encendida

    CPI R16, 0x07
    BREQ bomba_encendida

    RJMP bomba_apagada

bomba_encendida:
    SBI PORTB, 4   ; Encender bomba (LED en PB4)
    RJMP loop

bomba_apagada:
    CBI PORTB, 4   ; Apagar bomba (LED en PB4)

    ; Si el nivel es 1111, parpadear LED de indicación en PB5
    CPI R16, 0x0F
    BREQ parpadear_led

    RJMP loop

parpadear_led:
    SBI PORTB, 5
    RCALL DELAY
    CBI PORTB, 5
    RCALL DELAY
    RJMP loop

delay:
    ldi  r18, 41
    ldi  r19, 150
    ldi  r20, 128
l1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    ret
