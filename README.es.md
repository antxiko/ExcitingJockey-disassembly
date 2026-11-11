# Exciting Jockey - desensamblado comentado

*(Also [in English](README.md).)*

El desensamblado comentado de **Exciting Jockey** (大障害競馬, Casio, 1984) para MSX: un cartucho de 16 KB en 0x8000.

- **100 %** del binario explicado: 9.039 bytes de código y 7.345 de datos con nombre, ni un byte sin asignar.
- **42,4 %** del listado comentado, 505 rutinas y etiquetas, ninguna por debajo del 10 % de comentarios.
- El listado se reensambla en la ROM original **byte a byte**.
- La selección sale de ejecutar la ROM, cotejada con openMSX; la salida, el salto, la caída, la mata, la meta, las apuestas y el pago, jugados en GIF; las siete músicas, de su propio motor de sonido e idénticas a openMSX cuadro a cuadro.

La web: <https://antxiko.github.io/ExcitingJockey-disassembly/es/>
(en inglés: <https://antxiko.github.io/ExcitingJockey-disassembly/>).

## Reproducirlo

La imagen de la ROM no se distribuye. Pon la tuya en la raíz como `excitingjockey.rom` (sha256 `2bd3078a...`) y ejecuta `make`. El detalle, en [POR DENTRO](docs/es/POR-DENTRO.md).

## Legal

El juego es de Casio y de sus titulares. La licencia de `LICENSE` cubre solo las herramientas, los comentarios, el análisis y la documentación de aquí. Mira [AVISO-LEGAL.md](AVISO-LEGAL.md).
