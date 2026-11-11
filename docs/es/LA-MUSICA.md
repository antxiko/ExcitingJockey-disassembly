# La música

Siete músicas, en los tres canales del PSG. No están grabadas a mano: `tools/musica.py`
**ejecuta el propio motor de sonido de la ROM** con `tools/z80run.py` -`pieza` (0x80DB) con
cada pieza en su canal y, en cada cuadro, `sonido_cuadro` (0x813A)- y apunta lo que escribe
en el PSG a través de la BIOS (WRTPSG y RDPSG).

**Cotejadas con openMSX**: los registros de tono y de volumen coinciden con los grabados, **0
distintos** en las siete, mientras suena cada pieza. El juego monta casi todas sus pantallas
dentro de la interrupción, y mientras lo hace las interrupciones siguientes la encuentran
ocupada (0xF301) y el motor no corre; por eso cada cuadro grabado se empareja con el cuadro
del motor que tiene la **misma RAM** en los canales de la música. El premio, el campeón y
RACE END se grabaron llamando a la rutina `pieza` del propio juego desde la selección
(`tools/guiones/musicas.tcl`), porque llegar a ellas jugando lleva nueve carreras.

Los sonidos de la carrera no están: el de la salida, el galope sin fin, el salto, el látigo,
el golpe con una mata, la caída y las monedas del pago.

## El motor

Tres canales en 0xF002, 0xF022 y 0xF042, de 32 bytes, con piezas en grupos de **tres
bytes**: una nota (su número, la duración y lo que se espera a la siguiente) o una orden de
la 0xF4 a la 0xFF (fin, repetir, saltar, volumen, envolvente, tempo, transporte, ruido; la
tabla 0x8308). Las notas salen de doce periodos de la octava más grave (0x8330), a la mitad
por cada octava. El canal 0xF002 suena en el C del PSG, el 0xF022 en el B y el 0xF042 en el A.

| | Quién la pide | Dura |
|---|---|---:|
| la primera carrera | la carrera 1, antes de elegir (0x8922) | 7,0 s |
| la fanfarria | la salida de cada carrera (0x8AE1) | 3,3 s |
| la llegada | después de la carrera, con PUSH TRIG 2 (0x8BDE) | 1,4 s |
| GAME OVER | el jinete el último, o nadie con dinero (0x8C4D) | 1,2 s |
| el premio | el jinete primero o segundo (0x8D0A) | 2,7 s |
| el campeón | el jinete primero en la carrera 9 (0x8D23) | 2,1 s |
| RACE END | las nueve carreras hechas (0x8A1D) | 3,0 s |

## La primera carrera

<audio controls src="../audio/musica_primera.mp3"></audio>

## La fanfarria

<audio controls src="../audio/musica_fanfarria.mp3"></audio>

## La llegada

<audio controls src="../audio/musica_llegada.mp3"></audio>

## GAME OVER

<audio controls src="../audio/musica_game_over.mp3"></audio>

## El premio

<audio controls src="../audio/musica_premio.mp3"></audio>

## El campeón

<audio controls src="../audio/musica_campeon.mp3"></audio>

## RACE END

<audio controls src="../audio/musica_fin.mp3"></audio>
