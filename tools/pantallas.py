#!/usr/bin/env python3
"""Las pantallas de Exciting Jockey.

  - la seleccion: EJECUTANDO la ROM (tools/bios.py: el Z80 con la BIOS que usa): los registros del VDP
    (0x8042), los dibujos (`carga_dibujos`, 0x83F6) y la pantalla de la seleccion (0x8656);
  - logotipo.png, la cabecera de la web: CASIO y el titulo (大障害競馬) de la seleccion;
  - la pantalla de la carrera, del cuadro que grabo openMSX (work/jinete.bin): el suelo y las cuotas se
    echan al azar con el registro R (0x8636), y cada partida sale distinta.

La seleccion se coteja con la VRAM que grabo openMSX (work/atraccion.bin, cuadro 400): la imagen sin
sprites punto a punto, la tabla de nombres y los registros.

Uso: pantallas.py <dir> [cotejo]
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import vdp                  # noqa: E402
from bios import Msx        # noqa: E402

RAIZ = os.path.dirname(AQUI)
COTEJO = ("atraccion", 400)
CARRERA = ("jinete", 660)


def cuadro(grab, n):
    for i, c in enumerate(vdp.cuadros(os.path.join(RAIZ, "work", grab + ".bin"))):
        if i == n:
            return c


def seleccion():
    rom = open(os.path.join(RAIZ, "excitingjockey.rom"), "rb").read()
    m = Msx(rom, 0x8000)
    m.sp = 0xF300
    for r in (0x8042, 0x83F6, 0x8656, 0x86AD):
        m.llama(r, sp=0xF2F0)
    return bytes(m.vdp.vram), bytes(m.vdp.regs)


def cotejo(v, regs):
    suya = cuadro(*COTEJO)
    nombres = [a - 0x1800 for a in range(0x1800, 0x1B00) if v[a] != suya["vram"][a]]
    t1, t2 = vdp.tela(v, regs, False), vdp.tela(suya["vram"], suya["regs"], False)
    puntos = [(x, y) for y in range(192) for x in range(256) if t1[y][x] != t2[y][x]]
    print("seleccion contra %s/%d: puntos distintos %d de 49152; nombres distintos %d; registros %s"
          % (COTEJO[0], COTEJO[1], len(puntos), len(nombres),
             "iguales" if regs == bytes(suya["regs"]) else "%s / %s" % (regs.hex(), bytes(suya["regs"]).hex())))
    return len(puntos), len(nombres)


def main(argv):
    v, regs = seleccion()
    vdp.imagen(v, regs, 2, con_sprites=False).save(os.path.join(argv[0], "seleccion.png"))
    vdp.imagen(v, regs, 4, con_sprites=False).crop((280, 0, 744, 192)).save(os.path.join(argv[0], "logotipo.png"))
    c = cuadro(*CARRERA)
    vdp.imagen(c["vram"], c["regs"], 2).save(os.path.join(argv[0], "carrera.png"))
    if len(argv) > 1:
        cotejo(v, regs)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
