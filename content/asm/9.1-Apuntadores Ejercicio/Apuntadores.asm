.include "m2560def.inc"

.org 0x0000
RJMP main

main:
    ; Configurar el puerto D como salida (1)
    ser R17
    OUT DDRD, R17

    ; Configurar el puerto B como entrada (0), para saber qué leer
    LDI R16, 0x00
    OUT DDRB, R16

loop:
    ; Leer la entrada del puerto B para definir qué leer, si el nombre o el teléfono
    IN R16, PINB
    CPI R16, 0x01  ; Si la entrada es 1, leer el nombre
    BREQ leer_nombre
    CPI R16, 0x02  ; Si la entrada es 2, leer el teléfono
    BREQ leer_telefono
    RJMP loop

leer_nombre:
    LDI ZH, HIGH(Nombre<<1) ; Cargar la dirección de la tabla de segmentos en Z
    LDI ZL, LOW(Nombre<<1)
    RJMP mostrar_nombre

leer_telefono:
    LDI ZH, HIGH(Telefono<<1) ; Cargar la dirección de la tabla de segmentos en Z
    LDI ZL, LOW(Telefono<<1)
    RJMP mostrar_telefono

mostrar_nombre:
    LPM R17, Z
    CPI R17, 0x00  ; Verificar si es el carácter de terminación
    BREQ loop
    OUT PORTD, R17
    INC ZL
    RJMP mostrar_nombre

mostrar_telefono:
    LPM R17, Z
    CPI R17, 'F'  ; Verificar si es el carácter de terminación
    BREQ loop
    OUT PORTD, R17
    INC ZL
    RJMP mostrar_telefono

.org 0x0100
Nombre:
    .db 'D', 'A', 'N', 'I', 'E', 'L', 'A', 0
Telefono:
    .db 3, 2, 3, 3, 2, 0, 7, 6, 8, 3, 'F' ;  'F' como carácter de terminación
