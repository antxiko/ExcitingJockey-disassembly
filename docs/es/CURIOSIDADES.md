# Curiosidades

## Datos escondidos entre los sprites

Al arrancar, el juego manda 2 KB de 0xAC1B a los dibujos de los sprites (0x3800): 64 dibujos
de 16 x 16. Pero no los usa todos, y en los huecos hay **otros datos**:

| sprites | dirección | lo que es de verdad |
|---|---|---|
| 4-9 | 0xAC9B | las seis filas de arriba de la pantalla de la carrera (ODDS, el recuadro, el óvalo) |
| 10-11 | 0xAD5B | las dos filas de abajo (1UP-4UP, el dinero, MIN-MAX) |
| 12 | 0xAD9B | la música de la primera carrera, canal 0 |
| 62-63 | 0xB3DB | la tabla de los diez dibujos del caballo |

Ningún sprite del juego usa los dibujos 4 a 12 (0x10-0x30): los caballos, los jinetes, los
cursores y la barra tienen sus números en sus tablas. Esas filas de la pantalla y esa música
están todo el rato en la VRAM como sprites, y nadie las enseña.

## Un juego que corre en la interrupción

INIT pone el gancho H.TIMI y después el bucle principal solo llama a una rutina, el **pago**
(`pago`, 0xA2F5), que no hace nada hasta que acaba una carrera. Todo lo demás va en la
interrupción (0x805B): los sprites, la máquina de estados, la pista, los caballos, los mandos
y el sonido. Cuando un cuadro no acaba a tiempo (montar una pantalla lleva varios), las
interrupciones siguientes lo encuentran ocupado (0xF301) y solo cuentan (0xF302).

## Las cuotas, pasadas dos veces

Las seis cuotas se pasan a decimal para la pantalla (`cuotas`, 0xA1B9), y el paso se hace
**dos veces**: la primera pasada da la cifra decimal y la segunda la toma por un número en
binario y la vuelve a pasar. Una cuota de 9 se queda en 9, pero 12 sale como 18 y 18 como 24.
El pago paga lo que se ve. Y el bucle no para en seis bytes: su contador sale a cero del bucle
de antes, así que da **256 vueltas**, de 0xF0B7 a 0xF1B6; lo que cambia después de las cuotas
se vuelve a poner luego o no se usa.

## El galope sin fin

El galope de la carrera es una pieza de tres golpes de ruido y una orden 0xFD, «vuelve a la
marca», sin marca: vuelve al principio y no acaba nunca (0xBE7F). Solo se para cuando el
juego calla el sonido al final de la carrera.

## Código y bytes que nadie usa

- En 0xA150 hay una rutina de once bytes, HL = 0xF080 + B x 8, que nadie llama (ni con
  `call`, ni con `jp`, ni por tabla) y que no se ejecuta en las medidas de openMSX.
- En 0x9EE6 hay un `ret` al que no se llega: la instrucción de antes salta a otro sitio.
- Cuatro bytes en 0xA6D7 (00 02 00 06) y cuatro en 0x88F8 (50 C0 00 08) están junto a tablas
  que sí se leen: ninguna instrucción apunta a ellos, y esas tablas acaban antes.

## La demostración

La demostración es siempre la carrera 9, en tierra y de 3600 metros, la más larga, sin
apuestas; el botón 1 la corta y vuelve a la selección.
