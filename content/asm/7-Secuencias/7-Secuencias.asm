    .include"m2560def.inc"

    .org(0x0000)
    RJMP    main
    
/*
Definición: Programa que según la entrada de un usuario decide qué secuencia mostrar entre: 
00: flasheo: Se enciende y se apaga
01: derecha: Va hacia la derecha
10: izquierda: Va hacia la izquierda
11: expandir: Del centro hacia afuera
La condición es siempre usar recursión
*/

; Definimos alias para los registros
.def cnt1 = R25
.def cnt2 = R26
.def cnt3 = R27

.equ cien= 100

main:
    ; Definir entradas
    LDI     R16,    0xCF
    OUT     DDRA,   R16

    ; Definir salida
    LDI     R16,    0xFF
    OUT     DDRC,   R16

      ; Inicializamos los contadores
    LDI     cnt1,   100
    LDI     cnt2,   255
    LDI     cnt3,   255

    LDI     R20,    0x00
    LDI     R21,    0xFF    ; el que me va a alternar en el EOR
    LDI     R22,    0x01


reset:
    LDI     R20,    0x00
    LDI     R22,    0x01

loop:

    IN      R17,    PINA
    SWAP    R17             ; 1111 1100 
    ANDI    R17,    0x03    ; ____ __00

    CPI     R17,    0x00
    BREQ    flash

    CPI     R17,    0x01
    BREQ    derecha 

    CPI     R17,    0x10
    BREQ    izquierda

    RJMP loop

    
flash:
; * Prender todos los leds (1)
; *  Hacer delay
; * Apagar todos los leds (0)
    OUT     PORTC,  R20
    RCALL   delay
    EOR     R20,    R21
    RJMP    loop

derecha:
; * Debería guardar cada led? o mirar también lo de la secuencia y va de izq a derecha
00000000
00000001
    ;! usar registro diferente
    OUT     PORTC,  R20
    RCALL   delay

izquierda:
; * Lo contrario a derecha

expandir:
; * Va en parejas, y se van alejando "cada uno" a derecha e izquierda

delay:
    DEC     cnt1
    BRNE    delay

    DEC     cnt2
    LDI     cnt1,   cien
    BRNE    delay

    DEC     cnt3
    BRNE    delay
    RET
