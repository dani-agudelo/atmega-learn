.include "m2560def.inc"

; cuenta los overflows para crear un retardo de 0.5 segundos
.def delay_counter = r19
; guarda el número a mostrar en el display
.def display_counter = r18

.org 0x0000
rjmp start

.org 0x002E            ; Vector de interrupción por overflow de Timer0
rjmp ISR_TMR0

start:
    ; Configuración del stack
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; r1 es un registro auxiliar, se usa para asegurar que el valor de Z no se corrompa
    ; se usa r1 por el acarreo de la suma
    clr r1               ; Asegurar que r1 es siempre cero

    ; Configurar puerto A como salida (display)
    ldi r16, 0xFF
    out DDRA, r16

    ; Configurar Timer0 en modo normal, preescalador 1024
    ldi r16, 0x00
    out TCCR0A, r16      ; Modo normal
    ldi r16, 0x05
    out TCCR0B, r16      ; CS02=1, CS00=1 → preescalador 1024
    ldi r16, 0x01
    sts TIMSK0, r16      ; Habilitar interrupción por overflow (TOIE0)

    ; Inicializar contadores
    clr display_counter
    clr delay_counter
    
    ; Mostrar el valor inicial (0) en el display
    rcall actualizar_display

    sei                  ; Habilitar interrupciones globales

main_loop:
    rjmp main_loop       ; Bucle infinito

; ========================================================
; Subrutina para actualizar el display
; ========================================================
actualizar_display:
    ; Guardar el estado de los registros para no perder datos
    push r0
    push ZL
    push ZH
    
    ; Obtener el valor correspondiente desde la tabla
    ldi ZH, high(Display << 1)  
    ldi ZL, low(Display << 1)
    
    mov r0, display_counter
    add ZL, r0           ; Sumar offset
    adc ZH, r1           ; Añadir posible carry
    
    lpm r16, Z           ; Cargar valor del display desde la tabla
    com r16              ; Negar los bits para Proteus (invertir lógica)
    out PORTA, r16       ; Mostrar en el display
    
    ; Restaurar el estado de los registros en orden inverso
    pop ZH
    pop ZL
    pop r0
    ret

; ========================================================
; RUTINA DE INTERRUPCIÓN - Timer0 overflow (~15.6 Hz)
; ========================================================
ISR_TMR0:
    push r16
    
    ; A 16MHz con preescalador 1024, cada overflow toma aproximadamente 16.4ms
    inc delay_counter
    cpi delay_counter, 30     ; ¿Han pasado 30 overflows? (~0.5 seg)
    brne fin_ISR

    clr delay_counter         ; Reiniciar delay
    inc display_counter       ; Aumentar número en display
    cpi display_counter, 0x10 ; ¿Llegó a 16?
    brne continuar
    clr display_counter       ; Volver a 0 si pasa de F

continuar:
    rcall actualizar_display  ; Actualizar display con nuevo valor

fin_ISR:
    pop r16
    reti

; ========================================================
; TABLA PARA DISPLAY DE 7 SEGMENTOS (CÁTODO COMÚN)
; (Valores originales, serán negados en actualizar_display)
; ========================================================
; .cseg
Display:
    .db 0b00111111, 0b00000110  ; 0, 1
    .db 0b01011011, 0b01001111  ; 2, 3
    .db 0b01100110, 0b01101101  ; 4, 5
    .db 0b01111101, 0b00000111  ; 6, 7
    .db 0b01111111, 0b01101111  ; 8, 9
    .db 0b01110111, 0b01111100  ; A, b
    .db 0b00111001, 0b01011110  ; C, d
    .db 0b01111001, 0b01110001  ; E, F