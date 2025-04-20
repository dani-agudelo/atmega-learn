.include "m2560def.inc"

.def delay_counter = r19      ; Cuenta los overflows (~0.5s)
.def display_counter = r18    ; Índice de la letra a mostrar
.def tempL = r20              ; Parte baja de la palabra leída
.def tempH = r21              ; Parte alta de la palabra leída
.def temp = r22               ; Registro temporal para índice

.org 0x0000
rjmp start

.org 0x002E                   ; Vector de interrupción Timer0
rjmp ISR_TMR0

start:
    ; Configurar stack
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    clr r1                    ; r1 siempre en cero

    ; Puerto A y C como salida (para los 16 bits del display)
    ldi r16, 0xFF
    out DDRA, r16
    out DDRC, r16

    ; Timer0 en modo normal, preescalador 1024
    clr r16
    out TCCR0A, r16
    ldi r16, 0x05
    out TCCR0B, r16
    ldi r16, 0x01
    sts TIMSK0, r16           ; Habilita interrupción de overflow

    clr delay_counter
    clr display_counter
    rcall actualizar_display

    sei                       ; Habilita interrupciones

main_loop:
    rjmp main_loop            ; Espera activa

; --- Mostrar letra según índice ---
actualizar_display:
    push r0
    push r1
    push ZL
    push ZH
    push temp

    ; Copiar display_counter a temp para no modificarlo
    mov temp, display_counter
    lsl temp                  ; temp = display_counter * 2

    ; Dirección a la tabla table
    ldi ZH, high(table << 1)
    ldi ZL, low(table << 1)
    add ZL, temp
    adc ZH, r1

    ; Leer parte baja y alta de la palabra
    lpm tempL, Z+
    lpm tempH, Z

    ; Invertimos si es cátodo común
    com tempL
    com tempH

    ; Mostrar en puertos
    out PORTA, tempL
    out PORTC, tempH

    ; Restaurar registros
    pop temp
    pop ZH
    pop ZL
    pop r1
    pop r0
    ret

; --- Interrupción de Timer0 (~0.5s por letra) ---
ISR_TMR0:
    push r16
    inc delay_counter
    cpi delay_counter, 30
    brne fin_ISR

    clr delay_counter
    inc display_counter
    cpi display_counter, 7     ; 7 letras en "DANIELA"
    brlo actualizar
    clr display_counter        ; Vuelve a mostrar desde la D

actualizar:
    rcall actualizar_display

fin_ISR:
    pop r16
    reti

; --- Tabla de letras en 14 segmentos (formato de 16 bits)
table:
    .dw 0x088F, 0x2237, 0x0476, 0x0889, 0x2239, 0x0038, 0x2237

