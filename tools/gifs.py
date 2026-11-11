#!/usr/bin/env python3
"""Los GIF de la web: tramos de las grabaciones de openMSX (tools/guiones/*.tcl, grabados con
tools/lanza_graba.ps1 en C-BIOS_MSX1_JP, -ram "0xE000 0x1400"), pintados con tools/vdp.py.

Los tramos salen de la RAM grabada: 0xE05E/0xE05F el estado y su paso, 0xE000 la carrera, el estado de
cada caballo (0xE07F, 0xE09F, 0xE0BF, 0xE0DF: 4 salta, 3 tropieza, 5 cae, 6 en el suelo), 0xE07D la
pareja ganadora y el dinero de los jugadores (0xE030, 0xE034).

  atraccion  sin tocar nada: la demostracion, la carrera 9 (tierra, 3600 m)
  jinete     el modo A: el caballo 1, la barra cada 10 cuadros (el latigo), GRAPH cada 40 (el salto)
  apuesta    el modo C: dos jugadores apuestan a las seis parejas; la carrera 1 y la 2

Uso: gifs.py docs/imagenes
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vdp          # noqa: E402

# (fichero, grabacion, desde, hasta, cada)
TRAMOS = [
    ("apuesta.gif", "apuesta", 770, 1640, 2),     # BET MODE: tres puntos en cada pareja; GRAPH (1621)
    ("salida.gif", "jinete", 990, 1290, 2),       # la salida (1000) y los caballos corren (1032)
    ("salto.gif", "atraccion", 1880, 2060, 2),    # los cuatro saltan la valla (1941-2032)
    ("caida.gif", "atraccion", 8230, 8480, 2),    # el 4 cae en la ria (8264), el jinete sale despedido y vuelve (8449)
    ("mata.gif", "apuesta", 7120, 7260, 2),       # el 1 tropieza con una mata (7177), en la carrera 2
    ("meta.gif", "jinete", 3330, 3500, 2),        # la meta: llegan los cuatro
    ("pago.gif", "apuesta", 4130, 4330, 2),       # la pareja 2-3 gana (4162): el jugador 2 cobra 3 x 24
]


def main(salida):
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for fichero, grab, desde, hasta, cada in TRAMOS:
        n, s = vdp.gif(os.path.join(raiz, "work", grab + ".bin"),
                       os.path.join(salida, fichero), desde, hasta, cada=cada, tope_ms=4000)
        print("%-20s %4d imagenes, %5.1f s, %8d bytes" % (
            fichero, n, s, os.path.getsize(os.path.join(salida, fichero))))


if __name__ == "__main__":
    main(sys.argv[1])
