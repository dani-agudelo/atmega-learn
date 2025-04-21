/*
Definición: 
Programa que cuenta en hexadecimal desde 00 hasta FF con visualización en dos displays
de 7 segmentos. Almacena valores en EEPROM y permite mostrarlos.
*/

.def contador_retardo = r19    ; Cuenta los overflows (~0.5s)
.def contador_display = r18    ; Valor actual del contador (00-FF)
.def temp = r16                ; Registro temporal
.def modo_display = r22        ; 0=contador, 1=mostrar EEPROM
.def contador_eeprom = r23     ; Número de elementos en EEPROM
.def valor_mostrado = r20      ; Valor que se muestra en el display
.def flag_antirebote = r21     ; Flag para anti-rebote de botones
.def tiempo_eeprom = r26       ; Contador para avanzar en la visualización de EEPROM

; Vectores de interrupción
.org 0x0000
rjmp inicio                    ; Reset
.org 0x0002                    ; INT0 (botón guardar)
rjmp ISR_BOTON
.org 0x0004                    ; INT1 (botón mostrar)
rjmp ISR_BOTON_MOSTRAR
.org 0x002E                    ; Timer0 overflow
rjmp ISR_TMR0

inicio:
    ; Configurar stack
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp

    ; Configurar puertos F y K como salida para los displays
    ldi temp, 0xFF
    out DDRF, temp
    sts DDRK, temp
    
    ; Configurar puerto D como entrada para los botones
    clr temp                   
    out DDRD, temp
    ldi temp, 0x03             ; Habilitar resistencias pull-ups en PD0 y PD1
    out PORTD, temp

    ; Configurar interrupciones y Timer0
    ldi temp, 0x0A             ; Flanco descendente para INT0 e INT1
    sts EICRA, temp
    ldi temp, 0x03             ; Habilitar INT0 e INT1
    out EIMSK, temp
    ldi temp, 0x05             ; Preescalador Timer0 1024
    out TCCR0B, temp
    ldi temp, 0x01             ; Habilitar interrupción por overflow
    sts TIMSK0, temp

    ; Inicializar variables (todos registros a cero)
    clr r1                     ; r1 siempre debe ser cero
    clr contador_display
    clr contador_retardo
    clr modo_display
    clr contador_eeprom
    clr valor_mostrado
    clr flag_antirebote
    clr tiempo_eeprom

    sei                        ; Habilitar interrupciones
    rjmp bucle_principal

bucle_principal:
    rcall actualizar_display
    rjmp bucle_principal

; --- Rutina para ambos botones ---
ISR_BOTON:
    push temp
    in temp, SREG
    push temp
    
    ; Anti-rebote
    tst flag_antirebote
    brne fin_isr_boton
    
    ; Guardar valor en EEPROM
    sbis EECR, EEPE    ; Esperar si EEPROM ocupada
    rcall guardar_valor
    
    ; Establecer anti-rebote
    ldi flag_antirebote, 20
    
fin_isr_boton:
    pop temp
    out SREG, temp
    pop temp
    reti

; --- Rutina para botón mostrar ---
ISR_BOTON_MOSTRAR:
    push temp
    in temp, SREG
    push temp
    
    tst flag_antirebote
    brne fin_isr_boton_mostrar
    
    ; Cambiar modo solo si hay elementos
    tst contador_eeprom
    breq fin_isr_boton_mostrar
    
    ; Activar modo EEPROM
    ldi modo_display, 1
    clr r24                     ; Puntero EEPROM bajo
    clr r25                     ; Puntero EEPROM alto
    clr tiempo_eeprom
    
    ; Leer primer valor
    rcall leer_eeprom
    
    ldi flag_antirebote, 20
    
fin_isr_boton_mostrar:
    pop temp
    out SREG, temp
    pop temp
    reti

; --- Guardar en EEPROM ---
guardar_valor:
    ; Usar contador_eeprom como dirección
    out EEARL, contador_eeprom
    clr temp
    out EEARH, temp
    
    ; Configurar dato
    out EEDR, contador_display
    
    ; Escribir
    sbi EECR, EEMPE
    sbi EECR, EEPE
    
    ; Incrementar contador (máx 255)
    cpi contador_eeprom, 255
    breq guardar_fin
    inc contador_eeprom
    
guardar_fin:
    ret

; --- Leer EEPROM ---
leer_eeprom:
    ; Configurar dirección
    out EEARH, r25
    out EEARL, r24
    
    ; Leer valor
    sbi EECR, EERE
    in valor_mostrado, EEDR
    
    ret

; --- Actualizar displays ---
actualizar_display:
    push r0
    push ZL
    push ZH
    
    ; Nibble alto (PORTK)
    mov temp, valor_mostrado
    swap temp
    andi temp, 0x0F
    ldi ZH, high(Tabla_Display << 1)
    ldi ZL, low(Tabla_Display << 1)
    add ZL, temp
    adc ZH, r1
    lpm temp, Z
    com temp
    sts PORTK, temp
    
    ; Nibble bajo (PORTF)
    mov temp, valor_mostrado
    andi temp, 0x0F
    ldi ZH, high(Tabla_Display << 1)
    ldi ZL, low(Tabla_Display << 1)
    add ZL, temp
    adc ZH, r1
    lpm temp, Z
    com temp
    out PORTF, temp
    
    pop ZH
    pop ZL
    pop r0
    ret

; --- Interrupción Timer0 ---
ISR_TMR0:
    push temp
    in temp, SREG
    push temp
    
    ; Anti-rebote
    tst flag_antirebote
    breq sin_antirebote
    dec flag_antirebote
    
sin_antirebote:
    ; Contador principal
    inc contador_retardo
    cpi contador_retardo, 10
    brne check_eeprom_mode
    
    ; Avanzar contador
    clr contador_retardo
    inc contador_display
    
    ; Actualizar si modo normal
    cpi modo_display, 0
    brne check_eeprom_mode
    mov valor_mostrado, contador_display
    rjmp fin_tmr0
    
check_eeprom_mode:
    ; Modo EEPROM
    cpi modo_display, 1
    brne fin_tmr0
    
    ; Control de tiempo
    inc tiempo_eeprom
    cpi tiempo_eeprom, 50
    brne fin_tmr0
    
    ; Avanzar al siguiente valor
    clr tiempo_eeprom
    inc r24                     ; Incrementar puntero
    
    ; Verificar fin
    cp r24, contador_eeprom
    brne leer_siguiente
    
    ; Volver a modo normal
    clr modo_display
    mov valor_mostrado, contador_display
    rjmp fin_tmr0
    
leer_siguiente:
    rcall leer_eeprom

fin_tmr0:
    pop temp
    out SREG, temp
    pop temp
    reti

; --- Tabla display 7 segmentos ---
.org 0x0100
Tabla_Display:
    .db 0b11011011, 0b00010001, 0b01001111, 0b01010111
    .db 0b10010101, 0b11010110, 0b11011110, 0b01010001
    .db 0b11011111, 0b11010111, 0b11011101, 0b10011110
    .db 0b00001110, 0b00011111, 0b11001110, 0b11001100