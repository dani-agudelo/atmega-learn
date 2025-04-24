/*
Definición:
Se desea realizar un programa que permita controlar un sistema de dosificacion de alimento para mascottas.
Al encender el sistema, se debe realizar el conteo de un temporizador que al cumplirse se procederá
a dispensar el alimento y se iniciará el ciclo nuevamente. El tiempo par dispensar estará almacenado en memoria EEPROM (valor
entre 0x0A y 0x1E)

Al cumplirse el tiempo, la cantidad de alimento se debe dosificar en gramos, representado por el parpadeo de
un led cada medio segundo (cada parpadeo corresponde a un gramo). La cantidad de alimento a dispensar tambien
estará almacenada en memoria EEPROM (valores de 0x01 a 0x0A gramos)

EL valor de la cuenta de temporizacion se visualizará en dos displays de 7 segmentos, conectados a los
siguientes pines de los puertos F y K

a. 5
b. 2
c. 3
d. 7
e. 4
f. 1
g. 0

Cuando la temporizacion termine, en los displays de 7 segmentos se visualizara la cuenta de cantidad de
alimento en forma descendente, al terminar la dosificacion, se regeresara al ciclo de temporizacin en el
tiempo que lleve

Para controlar la cantidad de tiempo y alimento, el usuario podrá modificarla usando 2 puLsadores externos,
que permitirán aumentar o disminuir respectivamente. Después de modificada la cantidad, deberá actualizarse
nuevamente el valor de la memoria EEPROM (no se puede dispensar ni temporizar una cantidad superior al
maximo ni inferior al minimo)

Para seleccionar el valor a modificar, tiempo o cantidad de alimento, se utilizará otra entrada adicional
(SELEC, 0 tiempo, 1 cantidad)


Para la inicializaxion del sistema se debe contar con un pulsador RESET para colocar
valores de inicializacion por defecto (0x0F segundos, 0x05 gramos)
*/
; Definición de registros
.def temp = r16         ; Registro temporal
.def temp2 = r17        ; Registro temporal adicional
.def contador_tiempo = r18     ; Contador de tiempo actual (segundos)
.def contador_retardo = r19     ; Contador para medio segundo
.def tiempo_total = r20       ; Tiempo total configurado (de EEPROM)
.def cantidad_alimento = r21   ; Cantidad de alimento configurada (de EEPROM)
.def estado_sistema = r22       ; 0=temporizando, 1=dosificando
.def cantidad_actual = r23     ; Cantidad actual en dosificación
.def flag_antirebote = r24     ; Flag para anti-rebote de botones
.def modo_config = r25       ; 0=normal, 1=configurando tiempo, 2=configurando cantidad
.def estado_led = r26         ; Estado del LED durante dosificación
.def zero = r1           ; Siempre mantener en cero

; Direcciones EEPROM
.equ DIR_TIEMPO = 0x00       ; Dirección para tiempo en EEPROM
.equ DIR_CANTIDAD = 0x01     ; Dirección para cantidad en EEPROM

; Definiciones de pines
.equ LED_PIN = 0           ; Pin para LED de dosificación (Puerto B)
.equ BTN_AUMENTAR = 0        ; Pin para botón aumentar (Puerto D)
.equ BTN_DISMINUIR = 1       ; Pin para botón disminuir (Puerto D)
.equ BTN_SELEC = 2         ; Pin para botón selector (Puerto D)
.equ BTN_RESET = 3         ; Pin para botón reset (Puerto D)

; Vectores de interrupción
.org 0x0000
rjmp inicio             ; Reset
.org 0x0002             ; INT0 (botón aumentar)
rjmp ISR_BTN_AUMENTAR
.org 0x0004             ; INT1 (botón disminuir)
rjmp ISR_BTN_DISMINUIR
.org 0x0006             ; INT2 (botón selector)
rjmp ISR_BTN_SELEC
.org 0x0008             ; INT3 (botón reset)
rjmp ISR_BTN_RESET
.org 0x002E             ; Timer0 overflow
rjmp ISR_TMR0

inicio:
    ; Configurar stack
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp

    ; Inicializar registros
    clr zero            ; r1 siempre debe ser cero
    clr contador_tiempo
    clr contador_retardo
    clr estado_sistema
    clr modo_config
    clr flag_antirebote
    clr estado_led

    ; Configurar puertos F y K como salida para los displays
    ldi temp, 0xFF
    out DDRF, temp
    sts DDRK, temp

    ; Configurar puerto B como salida para LED
    ldi temp, (1 << LED_PIN)
    out DDRB, temp

    ; Configurar puerto D como entrada para los botones
    clr temp
    out DDRD, temp
    ldi temp, 0x0F       ; Habilitar resistencias pull-ups en PD0-PD3
    out PORTD, temp

    ; Configurar interrupciones
    ldi temp, 0x0A       ; Flanco descendente para INT0 e INT1 (00001010)
    sts EICRA, temp
    ldi temp, 0x0A       ; Flanco descendente para INT2 e INT3 (00001010)
    sts EICRB, temp
    ldi temp, 0x0F       ; Habilitar INT0-INT3
    out EIMSK, temp

    ; Configurar Timer0
    ldi temp, 0x05       ; Preescalador Timer0 1024
    out TCCR0B, temp
    ldi temp, 0x01       ; Habilitar interrupción por overflow
    sts TIMSK0, temp

    ; Leer configuraciones de EEPROM o usar valores por defecto
    rcall leer_configuracion

    sei                 ; Habilitar interrupciones
    rjmp bucle_principal

bucle_principal:
    rcall actualizar_display   ; Actualizar visualización en displays
    rjmp bucle_principal

; --- Leer configuración desde EEPROM ---
leer_configuracion:
    ; Leer tiempo
    ldi temp, DIR_TIEMPO
    out EEARL, temp
    clr temp
    out EEARH, temp
    sbi EECR, EERE
    in tiempo_total, EEDR

    ; Verificar límites de tiempo
    cpi tiempo_total, 0x0A
    brsh tiempo_ok_min
    ldi tiempo_total, 0x0A

tiempo_ok_min:
    cpi tiempo_total, 0x1F     ; Si es >= 0x1F
    brlo tiempo_ok_max
    ldi tiempo_total, 0x1E
tiempo_ok_max:

    ; Leer cantidad
    ldi temp, DIR_CANTIDAD
    out EEARL, temp
    clr temp
    out EEARH, temp
    sbi EECR, EERE
    in cantidad_alimento, EEDR

    ; Verificar límites de cantidad
    cpi cantidad_alimento, 0x01
    brsh cantidad_ok_min
    ldi cantidad_alimento, 0x01

cantidad_ok_min:
    cpi cantidad_alimento, 0x0B     ; Si es >= 0x0B
    brlo cantidad_ok_max
    ldi cantidad_alimento, 0x0A

cantidad_ok_max:

    ; Inicializar contador a cero para cuenta ascendente
    clr contador_tiempo
    ret

; --- Guardar configuración en EEPROM ---
guardar_configuracion:
    ; Guardar tiempo
    ldi temp, DIR_TIEMPO
    out EEARL, temp
    clr temp
    out EEARH, temp
    out EEDR, tiempo_total
    sbi EECR, EEMPE
    sbi EECR, EEPE
    
guardar_tiempo_espera:
    sbic EECR, EEPE
    rjmp guardar_tiempo_espera

    ; Guardar cantidad
    ldi temp, DIR_CANTIDAD
    out EEARL, temp
    clr temp
    out EEARH, temp
    out EEDR, cantidad_alimento
    sbi EECR, EEMPE
    sbi EECR, EEPE
    ret

; --- Reset a valores por defecto ---
reset_valores:
    ldi tiempo_total, 0x0F       ; 15 segundos por defecto
    ldi cantidad_alimento, 0x05   ; 5 gramos por defecto
    clr contador_tiempo          ; Inicializar contador a cero
    clr estado_sistema
    rcall guardar_configuracion
    ret

; --- Actualizar displays ---
actualizar_display:
    ; Decidir qué valor mostrar según el estado
    cpi estado_sistema, 0
    brne mostrar_dosificacion

    ; Mostrar tiempo
    mov temp, contador_tiempo
    rjmp continuar_display

mostrar_dosificacion:
    ; Mostrar cantidad
    mov temp, cantidad_actual

continuar_display:
    ; Verificar modo configuración (parpadeo)
    cpi modo_config, 0
    breq sin_parpadeo

    ; En modo config, usar contador_retardo para parpadeo ~1Hz
    mov temp2, contador_retardo
    andi temp2, 0x08
    breq hacer_parpadeo

    ; Si estamos en modo configuración del valor que se muestra
    cpi modo_config, 1
    breq sin_parpadeo
    cpi estado_sistema, 0
    brne sin_parpadeo       ; Si configuramos cantidad pero mostramos tiempo, no parpadea
    rjmp sin_parpadeo

hacer_parpadeo:
    cpi modo_config, 1
    brne check_modo2
    cpi estado_sistema, 0
    brne sin_parpadeo
    clr temp             ; Apagar display para parpadeo
    rjmp sin_parpadeo

check_modo2:
    cpi modo_config, 2
    brne sin_parpadeo
    cpi estado_sistema, 1   ; Solo parpadea si estamos dosificando y en config 2
    brne sin_parpadeo
    clr temp             ; Apagar display para parpadeo

sin_parpadeo:
    ; Nibble alto (PORTK) - Decenas
    push temp
    swap temp
    andi temp, 0x0F
    ldi ZH, high(Tabla_Display << 1)
    ldi ZL, low(Tabla_Display << 1)
    add ZL, temp
    adc ZH, zero
    lpm temp, Z
    com temp
    sts PORTK, temp

    ; Nibble bajo (PORTF) - Unidades
    pop temp
    andi temp, 0x0F
    ldi ZH, high(Tabla_Display << 1)
    ldi ZL, low(Tabla_Display << 1)
    add ZL, temp
    adc ZH, zero
    lpm temp, Z
    com temp
    out PORTF, temp

    ret

; --- Interrupción Timer0 (cada ~16ms) ---
ISR_TMR0:
    push temp
    in temp, SREG
    push temp

    ; Anti-rebote
    tst flag_antirebote
    breq sin_antirebote
    dec flag_antirebote

sin_antirebote:
    ; Incrementar contador de retardo
    inc contador_retardo
    cpi contador_retardo, 15     ; 
    brne fin_tmr0

    ; Reiniciar contador de retardo
    clr contador_retardo

    ; Verificar estado del sistema
    cpi estado_sistema, 0
    brne estado_dosificacion

    ; Estado temporizando: incrementar contador
    inc contador_tiempo
    cp contador_tiempo, tiempo_total ; Verificar si se alcanzó el tiempo total
    brne fin_tmr0

    ; Tiempo cumplido, cambiar a dosificación
    ldi estado_sistema, 1
    mov cantidad_actual, cantidad_alimento
    clr estado_led           ; Asegurar que el LED comienza apagado
    rjmp fin_tmr0

estado_dosificacion:
    ; Alternar LED para indicar dosificación
    ldi temp, (1 << LED_PIN)
    in estado_led, PORTB
    eor estado_led, temp
    out PORTB, estado_led

    ; Si el LED se acaba de encender, decrementar cantidad
    sbrc estado_led, LED_PIN
    rjmp check_cantidad

    ; Si el LED se ha apagado y la cantidad es > 0, decrementar
check_cantidad:
    tst cantidad_actual
    breq dosificacion_completa
    dec cantidad_actual
    tst cantidad_actual
    brne fin_tmr0

dosificacion_completa:
    ; Apagar LED al terminar
    clr temp
    out PORTB, temp

    ; Dosificación completa, volver a temporizador y resetear contador
    cpi cantidad_actual, 0
    brne fin_tmr0
    ldi estado_sistema, 0
    clr contador_tiempo      ; Reiniciar contador de tiempo para el siguiente ciclo

fin_tmr0:
    pop temp
    out SREG, temp
    pop temp
    reti

; --- Botón Aumentar ---
ISR_BTN_AUMENTAR:
    push temp
    in temp, SREG
    push temp

    ; Anti-rebote
    tst flag_antirebote
    brne fin_btn_aumentar
    ldi flag_antirebote, 10

    ; Verificar modo configuración
    cpi modo_config, 0
    breq fin_btn_aumentar

    ; Configurando tiempo
    cpi modo_config, 1
    brne config_cantidad_aumentar

    ; Aumentar tiempo si no excede máximo
    cpi tiempo_total, 0x1E
    breq fin_btn_aumentar
    inc tiempo_total
    mov contador_tiempo, tiempo_total ; Actualizar también el tiempo actual si se está configurando
    rcall guardar_configuracion
    rjmp fin_btn_aumentar

config_cantidad_aumentar:
    ; Aumentar cantidad si no excede máximo
    cpi cantidad_alimento, 0x0A
    breq fin_btn_aumentar
    inc cantidad_alimento
    rcall guardar_configuracion

fin_btn_aumentar:
    pop temp
    out SREG, temp
    pop temp
    reti

; --- Botón Disminuir ---
ISR_BTN_DISMINUIR:
    push temp
    in temp, SREG
    push temp

    ; Anti-rebote
    tst flag_antirebote
    brne fin_btn_disminuir
    ldi flag_antirebote, 10

    ; Verificar modo configuración
    cpi modo_config, 0
    breq fin_btn_disminuir

    ; Configurando tiempo
    cpi modo_config, 1
    brne config_cantidad_disminuir

    ; Disminuir tiempo si no es menor que mínimo
    cpi tiempo_total, 0x0B     ; 0x0A + 1
    brlo fin_btn_disminuir
    dec tiempo_total
    mov contador_tiempo, tiempo_total ; Actualizar también el tiempo actual si se está configurando
    rcall guardar_configuracion
    rjmp fin_btn_disminuir

config_cantidad_disminuir:
    ; Disminuir cantidad si no es menor que mínimo
    cpi cantidad_alimento, 0x02     ; 0x01 + 1
    brlo fin_btn_disminuir
    dec cantidad_alimento
    rcall guardar_configuracion

fin_btn_disminuir:
    pop temp
    out SREG, temp
    pop temp
    reti

; --- Botón Selector ---
ISR_BTN_SELEC:
    push temp
    in temp, SREG
    push temp

    ; Anti-rebote
    tst flag_antirebote
    brne fin_btn_selec
    ldi flag_antirebote, 10

    ; Cambiar modo configuración
    inc modo_config
    cpi modo_config, 3
    brlo fin_btn_selec
    clr modo_config       ; Volver a modo normal (0)

fin_btn_selec:
    pop temp

; --- Botón Reset ---
ISR_BTN_RESET:
    push temp
    in temp, SREG
    push temp
    
    ; Anti-rebote
    tst flag_antirebote
    brne fin_btn_reset
    ldi flag_antirebote, 10
    
    ; Resetear a valores por defecto
    rcall reset_valores
    
fin_btn_reset:
    pop temp
    out SREG, temp
    pop temp
    reti

; --- Tabla display 7 segmentos ---
; Formato: dhaecbfg
; La tabla está en catodo común pero en proteus se usa ANODO COMUN
.org 0x0300
Tabla_Display:
    .db 0b10111110, 0b00001100, 0b10110101, 0b10101101
    .db 0b00001111, 0b10101011, 0b10111011, 0b00101100
    .db 0b11111111, 0b11101111, 0b01111111, 0b11011011
    .db 0b10010001, 0b11011101, 0b11110011, 0b01110011