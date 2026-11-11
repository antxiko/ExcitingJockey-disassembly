#!/usr/bin/env python3
"""Las musicas de Exciting Jockey, EJECUTANDO su propio motor de sonido (ver
motor_musica.py).

El motor va en la interrupcion: `sonido_cuadro` (0x813A) en cada cuadro. Cada
musica la pone el juego con `pieza` (0x80DB: B el canal de la RAM, DE la pieza)
una vez por canal, despues de callar el sonido (`sonido_calla`, 0x8102). El
motor llega al PSG por la BIOS (WRTPSG y RDPSG), que aqui se atrapan.

Uso:  musica.py registros N [cuadros] | mp3 N f.mp3 | todas docs/audio | cotejo
      (N es el numero de la musica en PIEZAS)
"""
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (piezas por canal, fichero, quien la pide)
PIEZAS = [
    (((0, 0xAD9B), (1, 0xBD89)), "musica_primera.mp3", "la primera carrera, antes de elegir (0x8922)"),
    (((0, 0xBDCF), (1, 0xBE02)), "musica_fanfarria.mp3", "la fanfarria de la salida (0x8AE1)"),
    (((0, 0xBF7D), (1, 0xBF8A)), "musica_llegada.mp3", "despues de la carrera, PUSH TRIG 2 (0x8BDE)"),
    (((0, 0xBE56), (1, 0xBE6C)), "musica_game_over.mp3", "GAME OVER (0x8C4D)"),
    (((1, 0xBF32), (2, 0xBF54)), "musica_premio.mp3", "el jinete, primero o segundo (0x8D0A)"),
    (((1, 0xBF97), (2, 0xBFB9)), "musica_campeon.mp3", "el jinete, primero en la carrera 9 (0x8D23)"),
    (((0, 0xBEDC), (1, 0xBF07)), "musica_fin.mp3", "las nueve carreras hechas, RACE END (0x8A1D)"),
]

CFG = dict(rom="excitingjockey.rom", org=0x8000, sp=0xF2F0, frame=0x813A,
           ram=(0xF000, 0xF060), hz=60, max_s=300)


def arranca(n):
    rom = open(os.path.join(RAIZ, CFG["rom"]), "rb").read()
    z = motor_musica.Cartucho(CFG, rom)
    z.sp = CFG["sp"]
    z.maq.psg[7] = 0xB8
    z.corre(0x8102)
    for canal, pieza in PIEZAS[n][0]:
        z.b, z.de = canal, pieza
        z.corre(0x80DB)
    z.escrituras.clear()
    return z


def ejecuta(n, maximo=None):
    maximo = maximo or CFG["hz"] * CFG["max_s"]
    z = arranca(n)
    a, b = CFG["ram"]
    cuadros, vistos = [], {}
    for k in range(maximo):
        cuadros.append(motor_musica.cuadro(z))
        h = hashlib.sha1(bytes(z.mem[a:b])).digest()
        if h in vistos:
            return cuadros, (None if vistos[h] == k else vistos[h])
        vistos[h] = k + 1
    return cuadros, None


def mp3(n, ruta):
    hz = CFG["hz"]
    cuadros, vuelta = ejecuta(n)
    todo, fundido = motor_musica.desarrolla(cuadros, vuelta, hz)
    motor_musica.a_mp3(motor_musica.sintetiza(todo, hz), ruta, fundido, hz)
    print("%-26s %d cuadros (%.1f s), vuelve al %s" % (os.path.basename(ruta), len(cuadros),
                                                      len(cuadros) / hz, vuelta))


def estados(n, maximo):
    """Cada cuadro del motor ejecutado: la RAM de los canales (0xF000-0xF05F) y los registros del PSG."""
    z = arranca(n)
    a, b = CFG["ram"]
    regs = [0] * 16
    out = [(bytes(z.mem[a:b]), tuple(regs))]
    for k in range(maximo):
        for r, v in motor_musica.cuadro(z):
            if r < 16:
                regs[r] = v
        out.append((bytes(z.mem[a:b]), tuple(regs)))
    return out


def cotejo():
    """Los tonos y los volumenes del motor ejecutado contra los del PSG que grabo openMSX al entrar en cada
    interrupcion (work/*.bin, con la RAM 0xE000-0xF3FF). Cada cuadro grabado se empareja con el cuadro del
    motor que tiene la MISMA RAM en los canales de la musica (32 bytes cada uno, desde 0xF002): asi no
    importan los cuadros en que la interrupcion llega con la anterior aun corriendo (0xF301), que en este
    juego son muchos al montar la pantalla, y el motor no corre. La pieza empieza en el cuadro en que el
    canal de su primera pieza pasa a tenerla; se mira cada canal mientras sigue con su pieza (el canal de la
    RAM c suena en el 2 - c del PSG) y suena (+2); el primer cuadro, antes de que corra el motor, no cuenta."""
    import vdp
    out = []
    for grab in ("atraccion", "jinete", "apuesta", "musicas"):
        ruta = os.path.join(RAIZ, "work", grab + ".bin")
        if not os.path.exists(ruta):
            continue
        cs = list(vdp.cuadros(ruta))
        base = lambda k, c: cs[k]["ram"][0x1002 + 0x20 * c] | cs[k]["ram"][0x1003 + 0x20 * c] << 8
        for n, (piezas, fichero, _) in enumerate(PIEZAS):
            c0, p0 = piezas[0]
            k0 = next((k for k in range(1, len(cs)) if base(k, c0) == p0 and base(k - 1, c0) != p0), None)
            if k0 is None or any(o[0] == n for o in out):
                continue
            emu = estados(n, 60 * 120)
            canales = [c for c, _ in piezas]
            trozo = lambda ram, c: bytes(ram[2 + 0x20 * c:0x22 + 0x20 * c])
            e, malos, mirados, sueltos = 0, [], 0, 0
            for j in range(k0, len(cs)):
                vivos = [c for c, p in piezas if base(j, c) == p and cs[j]["ram"][0x1004 + 0x20 * c]]
                if not vivos:
                    break
                ram = cs[j]["ram"][0x1000:0x1060]
                hallado = next((x for x in range(e, min(e + 8, len(emu)))
                                if all(trozo(emu[x][0], c) == trozo(ram, c) for c in vivos)), None)
                if hallado is None:
                    sueltos += 1
                    continue
                e = hallado
                if e == 0:
                    continue
                mirados += 1
                regs = emu[e][1]
                if any(cs[j]["psg"][r] != regs[r] for c in vivos for r in (2 * (2 - c), 2 * (2 - c) + 1, 10 - c)):
                    malos.append(j - k0)
            out.append((n, grab, k0, mirados, malos, sueltos))
    return out


def main(argv):
    if argv and argv[0] == "cotejo":
        for n, grab, k0, mirados, malos, sueltos in cotejo():
            print("%-26s %s, empieza en el cuadro %d: %d cuadros mirados, %d distintos %s; %d sin pareja"
                  % (PIEZAS[n][1], grab, k0, mirados, len(malos), malos[:8], sueltos))
        return 0
    if argv and argv[0] == "todas":
        os.makedirs(argv[1], exist_ok=True)
        for n, (_, fichero, _) in enumerate(PIEZAS):
            mp3(n, os.path.join(argv[1], fichero))
        return 0
    if argv and argv[0] == "mp3":
        mp3(int(argv[1]), argv[2])
        return 0
    if argv and argv[0] == "registros":
        cuadros, vuelta = ejecuta(int(argv[1]), int(argv[2]) if len(argv) > 2 else None)
        for i, escr in enumerate(cuadros):
            print("%5d %s" % (i, " ".join("%X=%02X" % rv for rv in escr)))
        print("cuadros: %d, vuelve al %s" % (len(cuadros), vuelta))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
