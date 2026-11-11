# Por dentro

## Rehacer la ROM

`make verify` ensambla `src/excitingjockey.asm` con pasmo y sale la ROM de 16 KB **byte a
byte**. `make sanity` comprueba lo que el reensamblado no cubre: que ningún byte declarado
como dato se lea como código, que ninguna entrada caiga en datos y que estén explicados los
16.384 bytes. `make test` pasa los tests. La ROM no está en el repositorio: hay que ponerla en
la raíz como `excitingjockey.rom` (el volcado de GoodMSX, `[!]`, sha1 `5b17cb69...`).

| | bytes |
|---|---|
| código trazado | 9.039 |
| datos con nombre | 7.345 |
| sin explicar | 0 |

El listado tiene 1.918 comentarios en 4.521 instrucciones (42,4 %), 505 rutinas y etiquetas,
ninguna por debajo del 10 % comentado, y ninguna rutina llamada sin nombre.

## El cartucho

16 KB en la **página 2** (0x8000-0xBFFF), con INIT en 0x8010 y el resto de la cabecera a
cero. Algo más de la mitad es código; el resto, los dibujos (2 KB de sprites y 2 KB de
casillas con sus colores), el título, las tablas de la pista y de los obstáculos y la música.

## La BIOS que usa

WRTVDP para los ocho registros de SCREEN 2 (no usa INIGRP), DISSCR y ENASCR para apagar y
encender la pantalla, FILVRM, LDIRVM, WRTVRM y RDVRM para la VRAM (RDVRM para leer la casilla
que pisa cada caballo), GTSTCK, GTTRIG y SNSMAT para los mandos y el teclado, y WRTPSG y
RDPSG para el sonido.

## La interrupción y la máquina de estados

El juego pone en el gancho H.TIMI (0xFD9F) un `jp` a 0x805B y no lo vuelve a cambiar. En cada
cuadro, si el anterior ha acabado: los sprites, la máquina de estados (0x83E2), la carrera y
el sonido. El estado son dos bytes, 0xE05E y su paso 0xE05F:

| estado | qué | pasos |
|---:|---|---|
| 1 | la carga de los dibujos | 1 |
| 2 | la selección | 3: la pantalla, la espera, la elección |
| 3 | el jinete | 5: la carrera nueva, HORSE SELECT, RACE END, su espera, la salida |
| 4 | las apuestas y la carrera | 9: la salida, las apuestas, la fanfarria, la espera, la carrera, el final, la siguiente, RACE END, el pago |
| 5 | la demostración | 3 |

Casi todas las elecciones pasan por `salta_tabla` (0x8083): detrás del `call` va una tabla de
direcciones y A dice a cuál saltar. Hay quince tablas así (los estados, los pasos, los
obstáculos, los estados de los caballos y de los jinetes). El trazador no las puede seguir
solo: están declaradas en `src/excitingjockey.nocode` y sus destinos en
`src/excitingjockey.entries`.

## Los caballos

Cada caballo es un bloque de 32 bytes (0xE07F, 0xE09F, 0xE0BF, 0xE0DF) y tres sprites, con su
propio estado: 1 la salida, 2 corre, 3 tropieza, 4 salta, 5 cae, 6 en el suelo, 7 después de
la meta (0x974E). Cada jinete es un bloque de 8 bytes (0xE0FF) y un sprite: 1 monta, 2
cabalga, 3 sale despedido, 4 gana (0x9D37). Los cuatro grupos de tres sprites de los caballos
cambian de orden en cada cuadro (`sprites_gira`, 0x83B3): cuando se juntan más de cuatro
sprites en una línea, parpadean por turnos en vez de desaparecer siempre el mismo.

## Cómo se ha hecho

El trazado sigue el código desde INIT, la interrupción y las quince tablas de saltos. El resto
se ha **medido en openMSX** (`tools/omsx_cobertura.tcl`: una condición en cada instrucción
apunta cada dirección nueva de la ROM), jugando y esperando a la demostración, en un Philips
VG 8020 y en C-BIOS.

## La RAM

| | |
|---|---|
| 0xE000 / 0xE001 / 0xE002 | la carrera, el modo, el caballo del jugador |
| 0xE003-0xE00C | la palanca y los dos botones, lo recién pulsado y la repetición |
| 0xE011 | las seis cuotas |
| 0xE017 | las apuestas: seis por jugador |
| 0xE02F | el dinero de cada jugador (4 bytes) |
| 0xE03F | la fuerza de cada caballo y su paso (4 bytes) |
| 0xE05E / 0xE05F | el estado y su paso |
| 0xE06C-0xE073 | la pista: su estado, su velocidad, lo que queda de carrera |
| 0xE07F | los cuatro caballos (32 bytes) |
| 0xE0FF | los cuatro jinetes (8 bytes) |
| 0xE180 | la tabla de sprites, que va a 0x1B00 en cada cuadro |
| 0xED00 | la pista, 16 filas de 32 |
| 0xF002-0xF05F | el motor de sonido |
| 0xF080 | las cuentas de la carrera de cada caballo (8 bytes) |
| 0xF0B0-0xF0EA | las cuotas, las apuestas, el pago y el látigo |
| 0xF300 | la interrupción: trabajando y ocupada |
