    .include"m2560def.inc"

    .org(0x0000)
    RJMP    main
/*
Programa que almacena tres datos en tres registros y aplica operaciones booleanas entre ellos.
*/
main:
    ; Cargar 1010 1010 en r18
    LDI r18,    0xAA
    ; Cargar 1100 1100
    LDI r19,    0xCC
    ; Cargar 1111 0000
    LDI r20,    0xF0
    ; Seteo de salida
    LDI r21,    0xFF
    OUT DDRC,   r21

loop:
    ; Guardar registro
    MOV r21,    r18
    ; Operación OR entre r18 - r20
    OR  r21,    r20

    ; Guardar lo de r19 en r22
    MOV r22,    r19
    ; operación and entre r19 - r20
    AND r22,    r20

    ; Guardar registro r18
    MOV r23,    r18
    ; Operación not al registro r18
    COM r23

    ; Guardar registro r18 en r24
    MOV r24,    r18
    ; Operación XOR entre r18 - r19
    EOR r24,    r19

    ; Guardar r18 en r25
    MOV     r25,    r18
    ; Limpiar el nibble bajo (dejar en cero)
    ANDI    r25,    0xF0

    ; Guardar r18 en r26
    MOV     r26,    r18
    ; Llenar el nibble bajo (dejar en uno)
    ORI    r26,    0x0F  

    ; Resultado: 0110 0110
    OUT PORTC,  r26
    

    RJMP    loop
; Nota: Se puede usar un XOR para negar un patrón específico
; 1010 1010
; 1100 1100
; 0110 0110
