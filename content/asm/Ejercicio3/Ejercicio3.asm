.include "m2560def.inc"

    .org 0x0000
    RJMP main

main:
    ; Configurar el puerto B como entrada (0)
    LDI R16, 0x00
    OUT DDRB, R16

    ; Configurar los 4 bits menos significativos del puerto C como salida y los 2 bits más significativos como entrada 0 1111
    ; Nota: En el taller decía que se usara D pero se usará C ya que no encontré en Proteus el puerto D6
    LDI R16, 0x0F
    OUT DDRC, R16

loop:
    ; Leer los datos de 4 bits del puerto B   
    IN R16, PINB
    ANDI R16, 0x0F ; Primer dato en los 4 bits menos significativos    
    MOV R17, R16   ; Guardar el primer dato en R17

    ; Leer el segundo dato de 4 bits del puerto B
    IN R18, PINB
    SWAP R18       ; Intercambiar los 4 bits altos y bajos       
    ANDI R18, 0x0F ; Segundo dato en los 4 bits menos significativos    

   ; Leer los 2 bits más significativos del puerto C 
    IN R19, PINC
    ANDI R19, 0xC0 ; Aislar los 2 bits más significativos (1100 0000)
    LSR R19        ; Desplazar a la derecha 6 veces para obtener los 2 bits en los bits 0 y 1
    LSR R19
    LSR R19
    LSR R19
    LSR R19
    LSR R19

;    ; Leer los 2 bits más significativos del puerto C 
;     IN R19, PINC
;     SWAP R19        ; Intercambiar los 4 bits altos y bajos
;     LSR R19         ; 1100 -> 0110 
;     LSR R19         ; 0110 -> 0011 
      

    ; Realizar la operación
    CPI R19, 0x00
    BREQ suma
    CPI R19, 0x01
    BREQ resta
    CPI R19, 0x02
    BREQ and_op
    CPI R19, 0x03
    BREQ or_op

suma:
    ADD R17, R18
    RJMP mostrar_resultado

resta:
    SUB R17, R18
    RJMP mostrar_resultado

and_op:
    AND R17, R18
    RJMP mostrar_resultado

or_op:
    OR R17, R18

mostrar_resultado:
    ; Mostrar el resultado en los 4 bits menos significativos del puerto C
    ANDI R17, 0x0F
    OUT PORTC, R17
    RJMP loop


