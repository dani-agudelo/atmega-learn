.include    "m2560def.inc"

.org        (0x0000)
RJMP    main

; Etiqueta para interrupción del Timer0 Compare Match A (0x002A)
.org        OC0Aaddr
RJMP    isr_t0

main:
    SEI  ; Habilitar interrupciones globales

    ; Configurar Puerto A como salida 
    LDI     R16, 0xFF  
    OUT     DDRA, R16

    ; Configurar Puerto B como entrada (para el switch)
    LDI     R16, 0x00  
    OUT     DDRB, R16

    ; Habilitar pull-up en PB0
    LDI     R16, 0x01  
    OUT     PORTB, R16

    ; Configurar Timer0 en modo CTC (Clear Timer on Compare Match)
    LDI     R16, 0x02  
    OUT     TCCR0A, R16

    ; Establecer el valor máximo en OCR0A (contar hasta 125)
    LDI     R16, 125
    OUT     OCR0A, R16

    ; Configurar el prescaler en 1024 (CS02 = 1, CS01 = 0, CS00 = 1)
    LDI     R16, 0x05  
    OUT     TCCR0B, R16

    ; Habilitar la interrupción de comparación para el Timer0 (OCIE0A)
    LDI     R16, 0x02  
    STS     TIMSK0, R16

    ; Inicializar el puntero Z al inicio de la tabla
    LDI     ZH, HIGH(table<<1)
    LDI     ZL, LOW(table<<1)

    ; Inicializar el contador de interrupciones
    LDI     R17, 125  

loop:
    ; Mostrar el valor actual en PORTA
    LPM     R20, Z
    COM     R20
    OUT     PORTA, R20

    RJMP    loop

isr_t0:
    DEC     R17  
    BRNE    reti_isr_t0

    LDI     R17, 125  

    ; Leer el estado del switch (PB0)
    IN      R18, PINB   
    ANDI    R18, 0x01   ; Obtener solo el bit 0

    CPI     R18, 0x01
    BREQ    ascender

descender:
    CPI     ZL, LOW(table<<1)  ; Verificar límite inferior (0)
    BRNE    decrementar
    ; Si está en el límite inferior, ir al máximo (F)
    LDI     ZL, LOW(table<<1) + 15
    RJMP    reti_isr_t0

decrementar:
    DEC     ZL
    RJMP    reti_isr_t0

ascender:
    CPI     ZL, LOW(table<<1) + 15  ; Verificar límite superior (F)
    BRNE    incrementar
    ; Si está en el límite superior, ir al mínimo (0)
    LDI     ZL, LOW(table<<1)
    RJMP    reti_isr_t0

incrementar:
    INC     ZL

reti_isr_t0:
    RETI
;
.org (0x0060) 
table:
    .dw 0x063F, 0x4F5B, 0x6D66, 0x077D, 0x6F7F
    .dw 0x7C77, 0x5E58, 0x7179
