    .include"m2560def.inc"

    .org(0x0000)
    RJMP    main
    
/*
Definición: 
Primero - Led de carreras 🏁:`
En un display siete segmentos hacer que un único led esté siempre encendido y realice un circuito completo, se recibe una entrada de un bit para seleccionar entre:
- En 0 el led hace un círculo en cualquier sentido (como el dígito 0).
- En 1 el led hace un ocho.
El led siempre vuelve a su posición original y repite la secuencia a no ser que el usuario pues cambie la entrada, el retraso para cambiar es de medio segundo.

Requisito:
- Debe usarse un único puerto.

Objetivo:
- Familiarizarse con entradas, salidas y Display 7Segmentos y subrutina de retraso.
*/
main:
    ; Configuramos los pines 4 y 5 como entradas
    LDI     r24,    0xCF  ; 1100  1111
    STS     DDRE,   r24
loop:
    ;Para los puertos fuera del rango ya no se usa IN sino LDS. Lectura / escritura cambia el orden
    LDS     r24,   PINE
    CPI     r24,   0
    BREQ    circulo
    RJMP    ocho

circulo:
    
    RJMP    loop


ocho:
    RJMP    loop
