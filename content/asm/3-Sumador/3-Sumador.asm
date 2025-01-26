    .include"m2560def.inc"

    .org(0x0000)
    RJMP    main
/*
Definición: Programa que recibe un primer dato y un segundo dato de 4 bits por un mismo pin -A, y mostrará el resultado de la suma por el puerto C. El resultado se almacena en la memoria RAM y se lee para mostrarse.
*/
main:
    ; Configurar las entradas y salidas
    LDI     r16,    0x00
    OUT     DDRA,   r16

    LDI     r17,    0xFF
    OUT     DDRC,   r17

loop:
    ; Leer el primer dato en el nibble alto y el segundo, en el bajo

    LDI     r18,    0
    IN      r18,    PINA
    ; Primero se limpia el segundo nibble, y se guarda en un temporal
    ; Luego se limpia el primero y por último se invierte para que la información quede en el nibble bajo y no se desborde.

    MOV     r19,    r18
    ANDI    r19,    0xF0

    MOV     r20,    r18
    ANDI    r20,    0x0F

    SWAP    r19

    ADD     r20,    r19

    OUT     PORTC,  r20

    ; Guardar el dato en memoria 
    ; STS     0x0100, r20

    ; ; Leer dato desde memoria
    ; LDS     r21,    0x0100
    ; OUT     PORTC,  r21
    ; OUT     PORTC,  r16
    
    ; STS     0x0100, r16

    RJMP    loop

