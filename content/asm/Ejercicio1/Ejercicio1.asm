.include"m2560def.inc"

    .org(0x0000)
    RJMP    main

main:
    ; Código aquí 🤗

    ; Configurar el puerto C como salida (1)
    LDI R16,    0xFF
    OUT DDRC,   R16

    ; Configurar el puerto B como entrada (0)
    LDI R16,    0x00
    OUT DDRB,   R16


loop:
    ; Leer del puerto B el valor
    IN  R16,    PINB
    ANDI    R16,    0b00000011;      Limpiar los bits que no nos interesan
   
    CPI R16,    0X01
    BREQ    parpadeo_leds
    
    CPI R16,    0x02 
    BREQ    centro_fuera

    CPI R16,    0X03
    BREQ    izquierda_derecha

    RJMP    loop


parpadeo_leds:
    LDI R17,    0xFF ; tambien se puede SER R17
    OUT PORTC,  R17; Encender todos los leds
    RCALL   DELAY
    LDI R17,    0x00
    OUT PORTC,  R17; Apagar todos los leds
    RCALL   DELAY
    RJMP    loop;

centro_fuera:
    LDI R20,    0x18;   0001 1000
    OUT PORTC,  R20
    RCALL   DELAY
    LDI R20, 0x24 ; 0010 0100
    OUT PORTC, R20
    RCALL DELAY
    LDI R20, 0x42 ; 0100 0010
    OUT PORTC, R20
    RCALL DELAY
    LDI R20, 0x81 ; 1000 0001
    OUT PORTC, R20
    RCALL DELAY
    LDI R20, 0x42 ; 0100 0010
    OUT PORTC, R20
    RCALL DELAY
    LDI R20, 0x24 ; 0010 0100
    OUT PORTC, R20
    RCALL DELAY
    LDI R20, 0x18 ; 0001 1000
    OUT PORTC, R20
    RCALL DELAY
    
    RJMP loop ; Volver al bucle principal para verificar el valor del puerto C

izquierda_derecha:
    LDI R21, 0x80 ; 1000 0000  0100 0000   0010 0000   0001 0000   0000 1000   0000 0100   0000 0010   0000 0001  0000 0000
derecha:
    OUT PORTC, R21
    RCALL DELAY
    LSR R21
    BRNE derecha

    LDI R21, 0x01 ; 0000 0001
izquierda:
    OUT PORTC, R21
    RCALL DELAY
    LSL R21
    CPI R21, 0x00 ; Se debe comparar con 0x00 porque la bandera Z 
    BRNE izquierda

    RJMP loop

DELAY:
    LDI  R18, 41
    LDI  R19, 150
    LDI  R20, 128
L1: DEC  R20
    BRNE L1
    DEC  R19
    BRNE L1
    DEC  R18
    BRNE L1
    ret

