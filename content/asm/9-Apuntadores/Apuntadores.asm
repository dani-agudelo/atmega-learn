.include "m2560def.inc"

    .org 0x0000       ; Dirección de inicio   
    RJMP main

main:
    ser R17         ; R17 = 0xFF
    OUT DDRD, R17   ; Configura el puerto D como salida
    LDI ZH, HIGH(Display<<1) ; Cargar la *dirección* de la tabla Display en Z, 
    LDI ZL, LOW(Display<<1)

loop:
    call mostrar    ; Llama a la subrutina mostrar
    inc ZL          ; Incrementa el puntero Z para que apunte al siguiente elemento de la tabla
    RJMP loop

mostrar:
    LPM R17, Z      ; Lee datos de la memoria de programa, la tabla Display y los guarda en R17
    OUT PORTD, R17  ; Muestra el valor en el puerto D

.org 0x100          ; Dirección de la tabla Display
Display:
    .db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13

    ; db define un byte de datos

; En la primera iteración, Z apunta a la dirección 0x200, porque se multiplicó por 2 por ser de 16, donde se encuentra el valor 0
; En la segunda iteración, Z apunta a la dirección 0x201, donde se encuentra el valor 1

        