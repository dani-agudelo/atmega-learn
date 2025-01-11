    .include"m2560def.inc"

    .org(0x0000)
    RJMP    main

/*
Programa que por el pin A tiene todos sus bits como entradas y las guarda en un registro que luego escribirá en todos los bits del puerto C
*/
main:
    ; Definir el comportamiento del pin A como entrada
    LDI r16,    0x00   ;0xFF = 0b1111 1111
    OUT DDRA,   r16

    ; Definir el comportamiento del puerto C como salida
    LDI r16,    0xFF
    OUT DDRC,   r16

loop:
    ; Leer la entrada del usuario
    IN  r17,    PINA

    ; Escribir la información del usuario
    OUT PORTC,  r17

    RJMP    loop
