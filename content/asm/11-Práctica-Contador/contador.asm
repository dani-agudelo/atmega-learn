.include "m2560def.inc"

.def delay_counter = r19     ; Cuenta los overflows (~0.5s)
.def display_counter = r18   ; Valor mostrado en el display
.def switch_state = r17      ; Guarda el estado del botón

.org 0x0000
rjmp start

.org 0x002E                  ; Vector de interrupción Timer0
rjmp ISR_TMR0

start:
    ; Configurar stack
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    clr r1                   ; r1 siempre debe ser cero

    ; Puerto A como salida (display), B como entrada (botón)
    ldi r16, 0xFF
    out DDRA, r16
    clr r16
    out DDRB, r16

    ; Timer0 modo normal, preescalador 1024, interrupción ON
    out TCCR0A, r16
    ldi r16, 0x05
    out TCCR0B, r16
    ldi r16, 0x01
    sts TIMSK0, r16

    clr display_counter      ; Mostrar 0
    clr delay_counter
    rcall actualizar_display

    sei                      ; Habilitar interrupciones

main_loop:
    rjmp main_loop           ; Espera activa

; --- Muestra el valor del contador en el display ---
actualizar_display:
    push r0
    push ZL
    push ZH

    ldi ZH, high(Display << 1)
    ldi ZL, low(Display << 1)
    add ZL, display_counter
    adc ZH, r1
    lpm r16, Z
    com r16                  ; Inversión para display cátodo común
    out PORTA, r16

    pop ZH
    pop ZL
    pop r0
    ret

; --- Interrupción por overflow (~16ms c/u) ---
ISR_TMR0:
    push r16
    inc delay_counter
    cpi delay_counter, 30    ; ~0.5s
    brne fin_ISR

    clr delay_counter
    in switch_state, PINB
    sbrc switch_state, 0     ; Si PB0 está en 1 → contar ascendente
    rjmp inc_counter

    dec display_counter
    brpl no_wrap_dec
    ldi display_counter, 0x0F
    
no_wrap_dec:
    rjmp actualizar

inc_counter:
    inc display_counter
    cpi display_counter, 0x10
    brlo actualizar
    clr display_counter

actualizar:
    rcall actualizar_display

fin_ISR:
    pop r16
    reti

; --- Tabla para display 7 segmentos ---
Display:
    .db 0b00111111, 0b00000110, 0b01011011, 0b01001111
    .db 0b01100110, 0b01101101, 0b01111101, 0b00000111
    .db 0b01111111, 0b01101111, 0b01110111, 0b01111100
    .db 0b00111001, 0b01011110, 0b01111001, 0b01110001
