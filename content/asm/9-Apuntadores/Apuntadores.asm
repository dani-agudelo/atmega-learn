.include "m2560def.inc"

    .org 0x0000
    RJMP main

main:
    ser R17
    OUT DDRD, R17
    LDI ZH, HIGH(Display<<1) ; Cargar la dirección de la tabla de segmentos en Z
    LDI ZL, LOW(Display<<1)

loop:
    call mostrar
    inc ZL
    RJMP loop

mostrar:
    LPM R17, Z
    OUT PORTD, R17

.org 0x100
Display:
    .db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13



    