    .include"m2560def.inc"

    .org(0x0000)
    RJMP    main
    
/*
Definición: 
Primero - Led de carreras 🏁:`
En un display siete segmentos hacer que un único led esté siempre encendido y realice un circuito completo, se recibe una entrada de un bit para seleccionar entre:
- En 0 el led hace un círculo en cualquier sentido (como el dígito 0).
- En 1 el led hace un ocho.
El led siempre vuelve a su posición original y repite la secuencia a no ser que el usuario pues cambie la entrada, el retraso para cambiar es de medio segundo.

Requisito:
- Debe usarse un único puerto.

Objetivo:
- Familiarizarse con entradas, salidas y Display 7Segmentos y subrutina de retraso.
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

    ; Definir salida (D7S)
    LDI     R16,    0x7F
    OUT     DDRC,   R16

    LDI     R20,    0x01
    

    ; Inicializamos los contadores
    LDI     cnt1,   100
    LDI     cnt2,   255
    LDI     cnt3,   255
reset:
    LDI     R20,    0x01
loop:
    ; Leemos la entrada para saber el patrón
    IN      R17,    PINA    ; 1100 1111
    ; Intercambiamos los nibbles
    SWAP    R17             ; 1111 1100 
    ANDI    R17,    0x03    ; ____ __00

    ; SBRC INVESTIGAR
    ; SBRS

    CPI     R17,    0x01    ; 0000 0001
    BREQ    ocho
    
    ; CPI     R17,    0x02    ; 0000 0010
    ; BREQ    ocho
    RJMP    cero_dinamico

cero_recursivo:
    ; 0000.0001
    ; 0000.0010
    ; 0000.0100
    ; 0000.1000
    ; 0001.0000
    ; 0010.0000 
    ; 0100.0000 ;? caso base

    ; Versión con recursividad
    OUT     PORTC,  R20
    RCALL   delay
    LSL     R20
    CPI     R20,    0x40
    BREQ    reset
    RJMP    cero_recursivo

cero_dinamico:
    ; La idea es que cambie inmediatamente si se toma otra decisión

    OUT     PORTC,  R20
    RCALL   delay
    LSL     R20
    CPI     R20,    0x40
    BREQ    reset
    RJMP    loop


cero:
    ; Estado del led
    ; 01, 02, 04, 08, 10, 20
    ; A > B > C > D > E > F
    
    ; _____.___A
    ; __000.0001
    LDI     R20,    0x01
    OUT     PORTC,  R20
    RCALL   delay

    ; _____.__B_
    ; __000.0010
    LDI     R20,    0x02
    OUT     PORTC,  R20
    RCALL   delay

    LDI     R20,    0x04
    OUT     PORTC,  R20
    RCALL   delay

    LDI     R20,    0x08
    OUT     PORTC,  R20
    RCALL   delay

    LDI     R20,    0x10
    OUT     PORTC,  R20
    RCALL   delay

    LDI     R20,    0x20
    OUT     PORTC,  R20
    RCALL   delay

    RJMP    loop
    
ocho:
    ; Estado del led
    ; 01, 02, 40, 10, 08, 04, 40, 20
    ; A > B > G > E > D > C > G > F

    ; __GFE.DCBA
    ; __654.3210

    ; _____.___A
    ; __000.0001
    LDI     R20,    0x01
    OUT     PORTC,  R20
    RCALL   delay

    ; _____.__B_
    ; __000.0010
    LDI     R20,    0x02
    OUT     PORTC,  R20
    RCALL   delay

    ; __G__.____
    ; __100.0000
    LDI     R20,    0x40
    OUT     PORTC,  R20
    RCALL   delay

    ; ____E.____
    ; __001.0000
    LDI     R20,    0x10
    OUT     PORTC,  R20
    RCALL   delay

    LDI     R20,    0x08
    OUT     PORTC,  R20
    RCALL   delay

    LDI     R20,    0x04
    OUT     PORTC,  R20
    RCALL   delay

    LDI     R20,    0x40
    OUT     PORTC,  R20
    RCALL   delay

    LDI     R20,    0x20
    OUT     PORTC,  R20
    RCALL   delay

    RJMP    loop
delay:
    DEC     cnt1
    BRNE    delay

    DEC     cnt2
    LDI     cnt1,   cien
    BRNE    delay

    DEC     cnt3
    BRNE    delay
    RET

