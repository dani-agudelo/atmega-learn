;===============================================================
; CONTADOR HEXADECIMAL CON VISUALIZACIÓN EN DISPLAYS 7 SEGMENTOS
; Para ATmega2560
;===============================================================
; Descripción:
; - Cuenta de 00 a FF en hexadecimal
; - Muestra en dos displays de 7 segmentos conectados a puertos F y K
; - Almacena valores en EEPROM al pulsar botón 1
; - Cambia entre mostrar secuencia y valores almacenados al pulsar botón 2
;===============================================================

.include "m2560def.inc"   ; Incluir definiciones específicas del ATmega2560

; Definición de constantes
.equ DISPLAY_PORT_F = PORTF  ; Puerto para primer display
.equ DISPLAY_DDR_F = DDRF
.equ DISPLAY_PORT_K = PORTK  ; Puerto para segundo display
.equ DISPLAY_DDR_K = DDRK
.equ BUTTON_PORT = PORTA     ; Puerto para botones
.equ BUTTON_PIN = PINA       ; Registro para leer botones
.equ BUTTON_DDR = DDRA
.equ BUTTON1 = 0             ; Pin para botón 1 (almacenar en EEPROM)
.equ BUTTON2 = 1             ; Pin para botón 2 (cambiar visualización)
.equ EEPROM_SIZE = 100       ; Tamaño máximo de almacenamiento en EEPROM

; Vector de interrupción corregido - ATmega2560
; La tabla de vectores de interrupción comienza en 0x0000
.org 0x0000
    jmp main                 ; Reset vector (0x0000)

.org 0x0046                  ; Vector para Timer0 Overflow (consultar datasheet para dirección correcta)
    jmp timer_interrupt      ; Timer0 OVF interrupt

; Sección de datos en SRAM
.dseg
counter:        .byte 1      ; Contador actual (0-255)
eeprom_count:   .byte 1      ; Cantidad de valores almacenados en EEPROM
display_mode:   .byte 1      ; Modo de visualización (0=contador, 1=EEPROM)
eeprom_index:   .byte 1      ; Índice actual al mostrar valores de EEPROM
debounce_count: .byte 1      ; Contador para anti-rebote

; Código principal - Asegúrate de que empiece después de la tabla de vectores
.cseg
.org 0x0100                  ; Comenzar código después de la tabla de vectores

; Tabla de conversión de hexadecimal a 7 segmentos
; Bits de 7 segmentos: gfedcba (activo bajo)
; Pines asignados:     4653721
seg7_table:
    .db 0b00000001, 0b01001111  ; 0, 1 (complemento para activo bajo)
    .db 0b00010010, 0b00000110  ; 2, 3 (complemento para activo bajo)
    .db 0b01001100, 0b00100100  ; 4, 5 (complemento para activo bajo)
    .db 0b00100000, 0b00001111  ; 6, 7 (complemento para activo bajo)
    .db 0b00000000, 0b00000100  ; 8, 9 (complemento para activo bajo)
    .db 0b00001000, 0b01100000  ; A, B (complemento para activo bajo)
    .db 0b01110010, 0b01000010  ; C, D (complemento para activo bajo)
    .db 0b00110000, 0b00111000  ; E, F (complemento para activo bajo)

; Programa principal
main:
    ; Inicialización de la pila
    ldi r16, high(RAMEND)
    out SPH, r16             ; Usar sts en lugar de out para ATmega2560
    ldi r16, low(RAMEND)
    out SPL, r16             ; Usar sts en lugar de out para ATmega2560
    
    ; Configurar puertos para los displays como salida
    ldi r16, 0xFF
    sts DISPLAY_DDR_F, r16   ; Puerto F como salida
    sts DISPLAY_DDR_K, r16   ; Puerto K como salida
    
    ; Configurar puertos para los botones como entrada con pull-up
    ldi r16, 0
    sts BUTTON_DDR, r16      ; Configurar como entrada
    ldi r16, (1<<BUTTON1) | (1<<BUTTON2)
    sts BUTTON_PORT, r16     ; Activar resistencias pull-up
    
    ; Inicializar variables
    clr r16
    sts counter, r16         ; Contador inicia en 0
    sts eeprom_count, r16    ; No hay valores almacenados en EEPROM
    sts display_mode, r16    ; Modo de visualización = contador
    sts eeprom_index, r16    ; Índice de EEPROM en 0
    sts debounce_count, r16  ; Contador anti-rebote en 0
    
    ; Configurar Timer0 para interrupción periódica
    ldi r16, (1<<CS02) | (1<<CS00)  ; Prescaler 1024
    sts TCCR0B, r16
    ldi r16, (1<<TOIE0)      ; Habilitar interrupción por desbordamiento
    sts TIMSK0, r16
    
    ; Habilitar interrupciones globales
    sei
    
; Bucle principal
main_loop:
    ; Incrementar contador (continúa contando independientemente del modo)
    lds r16, counter
    inc r16
    sts counter, r16
    
    ; Verificar botón 1 - Almacenar en EEPROM
    lds r17, BUTTON_PIN
    sbrs r17, BUTTON1        ; Omitir siguiente instrucción si el bit está a 1 (no presionado)
    rcall button1_pressed
    
    ; Verificar botón 2 - Cambiar modo de visualización
    lds r17, BUTTON_PIN
    sbrs r17, BUTTON2        ; Omitir siguiente instrucción si el bit está a 1 (no presionado)
    rcall button2_pressed
    
    ; Retardo para la velocidad del conteo
    ldi r16, 255
delay_loop1:
    ldi r17, 255
delay_loop2:
    dec r17
    brne delay_loop2
    dec r16
    brne delay_loop1
    
    rjmp main_loop

; Rutina para cuando se presiona el botón 1 (guardar en EEPROM)
button1_pressed:
    ; Anti-rebote
    lds r16, debounce_count
    cpi r16, 0
    brne button1_end
    
    ; Establecer contador anti-rebote
    ldi r16, 10
    sts debounce_count, r16
    
    ; Almacenar valor actual en EEPROM
    lds r16, counter         ; Obtener valor actual
    lds r17, eeprom_count    ; Obtener cantidad almacenada
    
    ; Verificar si hay espacio en EEPROM
    cpi r17, EEPROM_SIZE
    brsh button1_end         ; Si está lleno, no guardar más
    
    ; Calcular dirección en EEPROM
    ldi ZL, low(EEPROM_START)
    ldi ZH, high(EEPROM_START)
    add ZL, r17
    brcc no_carry1
    inc ZH
no_carry1:
    
    ; Escribir en EEPROM
    rcall eeprom_write
    
    ; Incrementar contador de EEPROM
    inc r17
    sts eeprom_count, r17
    
button1_end:
    ret

; Rutina para cuando se presiona el botón 2 (cambiar modo visualización)
button2_pressed:
    ; Anti-rebote
    lds r16, debounce_count
    cpi r16, 0
    brne button2_end
    
    ; Establecer contador anti-rebote
    ldi r16, 10
    sts debounce_count, r16
    
    ; Cambiar modo de visualización
    lds r16, display_mode
    ldi r17, 1
    eor r16, r17             ; Alternar entre 0 y 1
    sts display_mode, r16
    
    ; Si cambiamos a modo EEPROM, iniciar desde el primer valor
    cpi r16, 1
    brne button2_end
    clr r16
    sts eeprom_index, r16
    
button2_end:
    ret

; Interrupción del timer para actualizar displays
timer_interrupt:
    push r16
    push r17
    push r18
    push r19
    push r20
    in r16, SREG
    push r16
    
    ; Decrementar contador anti-rebote si es necesario
    lds r16, debounce_count
    cpi r16, 0
    breq no_debounce
    dec r16
    sts debounce_count, r16
no_debounce:
    
    ; Determinar qué valor mostrar según el modo
    lds r16, display_mode
    cpi r16, 0
    breq show_counter        ; Si modo=0, mostrar contador
    
    ; Modo=1: Mostrar valores de EEPROM
    lds r16, eeprom_index
    lds r17, eeprom_count
    cp r16, r17
    brlo show_eeprom         ; Si hay valores para mostrar
    
    ; Si no hay más valores, volver a modo contador
    clr r16
    sts display_mode, r16
    rjmp show_counter
    
show_eeprom:
    ; Leer valor de EEPROM según índice actual
    ldi ZL, low(EEPROM_START)
    ldi ZH, high(EEPROM_START)
    lds r16, eeprom_index
    add ZL, r16
    brcc no_carry2
    inc ZH
no_carry2:
    
    rcall eeprom_read        ; r16 contiene el valor leído
    
    ; Incrementar índice para la próxima vez
    lds r17, eeprom_index
    inc r17
    sts eeprom_index, r17
    
    rjmp display_value
    
show_counter:
    ; Mostrar valor actual del contador
    lds r16, counter
    
display_value:
    ; Separar dígitos hexadecimales
    mov r18, r16             ; Guardar valor original
    swap r16                 ; Intercambiar nibbles
    andi r16, 0x0F           ; Aislar dígito más significativo
    mov r19, r18
    andi r19, 0x0F           ; Aislar dígito menos significativo
    
    ; Convertir a códigos de 7 segmentos
    ldi ZL, low(2*seg7_table)
    ldi ZH, high(2*seg7_table)
    add ZL, r16
    brcc no_carry3
    inc ZH
no_carry3:
    lpm r16, Z               ; Obtener patrón para dígito MSB
    
    ldi ZL, low(2*seg7_table)
    ldi ZH, high(2*seg7_table)
    add ZL, r19
    brcc no_carry4
    inc ZH
no_carry4:
    lpm r17, Z               ; Obtener patrón para dígito LSB
    
    ; Remapear bits según la asignación de pines dada
    ; Pines: a=3, b=2, c=1, d=7, e=5, f=6, g=4
    rcall remap_segments
    
    ; Sacar en puertos F y K
    sts DISPLAY_PORT_F, r16  ; MSB en puerto F
    sts DISPLAY_PORT_K, r17  ; LSB en puerto K
    
    ; Restaurar registros
    pop r16
    out SREG, r16
    pop r20
    pop r19
    pop r18
    pop r17
    pop r16
    reti

; Remapea los bits del patrón de 7 segmentos según los pines asignados
; Entrada: r16, r17 = patrones originales (gfedcba)
; Salida:  r16, r17 = patrones remapeados según pines (a=3, b=2, c=1, d=7, e=5, f=6, g=4)
remap_segments:
    ; Guardar valores originales
    mov r20, r16             ; MSB
    clr r16                  ; Limpiar destino
    
    ; Remapear MSB
    sbrc r20, 0              ; a (original bit 0 -> pin 3)
    ori r16, (1<<3)
    sbrc r20, 1              ; b (original bit 1 -> pin 2)
    ori r16, (1<<2)
    sbrc r20, 2              ; c (original bit 2 -> pin 1)
    ori r16, (1<<1)
    sbrc r20, 3              ; d (original bit 3 -> pin 7)
    ori r16, (1<<7)
    sbrc r20, 4              ; e (original bit 4 -> pin 5)
    ori r16, (1<<5)
    sbrc r20, 5              ; f (original bit 5 -> pin 6)
    ori r16, (1<<6)
    sbrc r20, 6              ; g (original bit 6 -> pin 4)
    ori r16, (1<<4)
    
    ; Lo mismo para LSB (r17)
    mov r20, r17             ; LSB
    clr r17                  ; Limpiar destino
    
    ; Remapear LSB
    sbrc r20, 0              ; a (original bit 0 -> pin 3)
    ori r17, (1<<3)
    sbrc r20, 1              ; b (original bit 1 -> pin 2)
    ori r17, (1<<2)
    sbrc r20, 2              ; c (original bit 2 -> pin 1)
    ori r17, (1<<1)
    sbrc r20, 3              ; d (original bit 3 -> pin 7)
    ori r17, (1<<7)
    sbrc r20, 4              ; e (original bit 4 -> pin 5)
    ori r17, (1<<5)
    sbrc r20, 5              ; f (original bit 5 -> pin 6)
    ori r17, (1<<6)
    sbrc r20, 6              ; g (original bit 6 -> pin 4)
    ori r17, (1<<4)
    
    ret

; Rutina para escribir en EEPROM - ATmega2560 específico
; Entrada: Z = dirección en EEPROM, r16 = valor a escribir
eeprom_write:
    ; Esperar que la EEPROM esté lista
eeprom_write_wait:
    lds r18, EECR
    sbrc r18, EEPE
    rjmp eeprom_write_wait
    
    ; Configurar dirección y dato
    sts EEARH, ZH
    sts EEARL, ZL
    sts EEDR, r16
    
    ; Iniciar escritura
    ldi r18, (1<<EEMPE)
    sts EECR, r18            ; Habilitar escritura
    ldi r18, (1<<EEPE)
    sts EECR, r18            ; Iniciar escritura
    
    ret

; Rutina para leer de EEPROM - ATmega2560 específico
; Entrada: Z = dirección en EEPROM
; Salida: r16 = valor leído
eeprom_read:
    ; Esperar que la EEPROM esté lista
eeprom_read_wait:
    lds r18, EECR
    sbrc r18, EEPE
    rjmp eeprom_read_wait
    
    ; Configurar dirección
    sts EEARH, ZH
    sts EEARL, ZL
    
    ; Iniciar lectura
    ldi r18, (1<<EERE)
    sts EECR, r18
    
    ; Leer dato
    lds r16, EEDR
    
    ret

; Constantes
.equ EEPROM_START = 0        ; Dirección inicial en EEPROM