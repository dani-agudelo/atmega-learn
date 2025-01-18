    .include"m2560def.inc"

    .org(0x0000)
    RJMP    main
    
/*
Definición: Programa que cada segundo muestra un contador binario. Mostrar por el puerto K
*/
main:
    ; Configuramos los puertos de salida (1)
    LDI     r24,    0xFF
    STS     DDRK,   r24     ;? Ya no se usa OUT, sino STS
loop:
    ; Mostramos el contador
    ADIW    r24,    1
    STS     PORTK,  r24
    LDI     r25,    0xFF
    LDI     r26,    0x46
    LDI     r27,    0X46
    LDI     r28,    0X46
    RJMP    ciclo
delay:
    ; Operaciones que se ejecuten en un segundo
    ; Contador que pare cuando llegue a cero
    ; * En microcontroladores, es más fácil hacer un contador descendente
    SUBI    r25,    1  

    CPI     r25,    0  
    BREQ    loop  
    RJMP    delay   

ciclo:
    SUBI    r26,    1   ; tener en cuenta: se debe reiniciar según Nubia
    BRNE    ciclo

    SUBI    r27,    1
    LDI     r26,    0x46
    BRNE    ciclo

    SUBI    r28,    1
    LDI     r27,    0x46
    BRNE    ciclo

    RJMP    loop

/*
LLamamos el delay y se hacen 255 operaciones, el objetivo es anidar otro contador hasta llegar a los 16 millones de operaciones.
El primer contador debe valer 255, el segundo 255 y el tercero con 246
*/
