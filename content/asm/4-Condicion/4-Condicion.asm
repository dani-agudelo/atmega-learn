    .include"m2560def.inc"

    .org(0x0000)
    RJMP    main

/*
Definición: Programa que con dos datos de 4 bits cada uno de los pines de A, y una entrada de 8 bits por el pin B con la que decide si aplica operaciones aritméticas.
00: Suma
01: Resta
10: Producto
11: Mitad
*/

main:
    ; Definir el comportamiento de los pines (entradas-salidas)
    LDI     r16,    0x00
    OUT     DDRA,   r16
    OUT     DDRB,   r16

    COM     r16
    OUT     DDRC,   r16

loop:
    ; Recibir los datos y condiciones
    IN      r17,    PINA
    IN      r18,    PINB
    MOV     r20,    r17

    ; Separar los datos para operar luego
    MOV     r19,    r17
    ANDI    r19,    0x0F
    ANDI    r17,    0xF0
    SWAP    r17

    ; Condicionales branch para decidir, la diferencia con el RJMP, es que en el primero se tiene en cuenta las banderas de estado.
    CPI     r18,    0
    BREQ    sumar


    CPI     r18,    1
    BREQ    restar

    CPI     r18,    2
    BREQ    multiplicar

    OUT     PORTC,  r17
    RJMP    mitad


sumar:
    ADD     r17,    r19
    RJMP    loop

restar:
    SUB     r17,    r19     
    RJMP    loop

multiplicar:
    MUL     r17,    r19
    RJMP    loop

mitad:
    LSR     r20
    MOV     r17,    r20
    RJMP    loop
