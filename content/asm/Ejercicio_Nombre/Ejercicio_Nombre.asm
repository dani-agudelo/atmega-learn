.include "m2560def.inc" 

.org(0x0000)
RJMP main             
; Configuración del vector de interrupción para el Timer0 Compare Match A
.org OC0Aaddr
RJMP isr_t0              

; -------------------------------
; Programa principal
; -------------------------------
main:
    ; Habilitar interrupciones globales
    SEI                     

    ; Configurar Puerto A y Puerto C como salidas
    LDI R16, 0xFF           
    OUT DDRA, R16           
    OUT DDRC, R16           

    ; Configurar Timer0 en modo CTC (Clear Timer on Compare Match)
    LDI R16, 0x02           ; WGM01 = 1, modo CTC
    OUT TCCR0A, R16         

    ; Establecer el valor máximo en OCR0A
    LDI R16, 125            ; Valor de comparación: 125
    OUT OCR0A, R16          

    ; Configurar el prescaler en 1024
    LDI R16, 0x05           ; CS02 = 1, CS01 = 0, CS00 = 1 (prescaler de 1024)
    OUT TCCR0B, R16         

    ; Habilitar la interrupción de comparación para el Timer0
    LDI R16, 0x02           ; OCIE0A = 1 (habilitar interrupción de comparación)
    STS TIMSK0, R16         

    ; Inicializar el contador de interrupciones
    LDI R20, 0              ; Inicializar el contador de interrupciones en 0
    LDI R17, 62             ; Configurar 62 interrupciones para contar 1 segundo

reset:
    ; Inicializar el puntero Z para acceder a la tabla de datos
    LDI ZH, 0x00            ; Parte alta 
    LDI ZL, 0x60            ; Parte baja 
    LSL ZL                  ; Multiplicar por 2 para acceder correctamente
    ROL ZH

    ; Calcular el límite de la tabla
    LDI R16, 14             ; Número de bytes en la tabla (7 letras x 2 bytes cada una)
    MOV R25, ZL             ; Copiar ZL en R25
    ADD R25, R16            ; Calcular el límite de la tabla

loop:
    ; Leer datos de la tabla
    LPM R20, Z+             ; Leer el byte alto del carácter y avanzar el puntero Z
    LPM R21, Z              ; Leer el byte bajo del carácter
    DEC ZL

    ; Invertir los bits de los datos (opcional, depende del hardware del display)
    COM R20
    COM R21

    ; Verificar si se alcanzó el final de la tabla
    CP ZL, R25              ; Comparar ZL con el límite de la tabla
    BREQ reset              ; Si son iguales, reiniciar el puntero

    ; Enviar los datos al display
    OUT PORTA, R20          ; Enviar el byte alto al Puerto A
    OUT PORTC, R21          ; Enviar el byte bajo al Puerto C

    RJMP loop               ; Repetir el bucle

; -------------------------------
; Rutina de interrupción del Timer0
; -------------------------------
isr_t0:
    DEC R17                 ; Decrementar el contador de interrupciones
    BRNE reti_isr_t0        ; Si no llega a 0, salir de la interrupción

    ; Reiniciar el contador de interrupciones
    LDI R17, 62             ; Configurar 62 interrupciones para contar 1 segundo

    ; Avanzar el puntero Z para mostrar el siguiente carácter
    INC ZL                  ; Incrementar la parte baja del puntero Z
    INC ZL                  ; Incrementar nuevamente (cada carácter ocupa 2 bytes)

reti_isr_t0:
    RETI                    ; Retornar de la interrupción

; -------------------------------
; Tabla de datos para el nombre "DANIELA"
; -------------------------------
.org(0x0060)
table:
    ; Letras en formato de 14 segmentos
    ; D: 0x 0000 1000 1000 1111   
    ; D: 0x 0001 0010 0000 1111   abcdil
    ; A: 0x10 0010 0011 0111    
    ; N: 0x0000010001110110
    ; I: 0x0000100010001001
    ; E: 0x10001000111001
    ; L: 0x0000000000111000
    ; A: 0x10001000110111
    .dw 0x088F, 0x2237, 0x0476, 0x0889, 0x2239, 0x0038, 0x2237
