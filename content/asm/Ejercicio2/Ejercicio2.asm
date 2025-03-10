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

loop:
    ; Leer el nivel del depósito desde el puerto C
    IN R16, PINC   ; 00001111

    ; Mostrar el nivel en la barra de LEDs (4 bits menos significativos)
    ANDI R16, 0x0F
    OUT PORTB, R16   

    ; Controlar la bomba de agua
    CPI R16, 0x00 ; Nivel mínimo
    BREQ bomba_encendida

    CPI R16, 0x01 ; Nivel medio
    BREQ bomba_encendida

    CPI R16, 0x03 ; Nivel alto
    BREQ bomba_encendida

    CPI R16, 0x07 ; Nivel muy alto
    BREQ bomba_encendida

    CPI R16, 0x0F ; Nivel máximo
    BREQ bomba_apagada

    RJMP loop

bomba_encendida:
    ; Encender la bomba (LED en PB4)
    SBI PORTB, 4   ; Ponemos en 1 indicando que la bomba está encendida
    RJMP loop

bomba_apagada:
    ; Apagar la bomba (LED en PB4) y parpadear el LED (PB5)
    CBI PORTB, 4
    RCALL parpadear_led
    RJMP loop

parpadear_led:
    SBI PORTB, 5
    RCALL DELAY
    CBI PORTB, 5
    RCALL DELAY
    RET

DELAY:
    LDI R18, 41
    LDI R19, 150
    LDI R20, 128
L1: DEC R20
    BRNE L1
    DEC R19
    BRNE L1
    DEC R18
    BRNE L1
    RET



