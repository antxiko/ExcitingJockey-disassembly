#!/usr/bin/env python3
"""Los caballos y los jinetes de Exciting Jockey MONTADOS DESDE LA ROM (ninguna imagen es una captura).

Los dibujos de los sprites son los 2 KB de 0xAC1B, que `carga_dibujos` (0x8402) pone tal cual en 0x3800.

  caballos.png     los diez dibujos del caballo (0xB3DB, 9 bytes cada uno: dibujo, Y y X de sus tres sprites) en los
                   colores de los cuatro caballos (0x9713-0x9743: negro, magenta, rojo oscuro y azul)
  jinetes.png      el jinete (blanco, 0x9D49) con los cuatro numeros, sentado y con el latigo (los dibujos de 0x9D99;
                   ahi van tambien su dy y su dx sobre el caballo, que aqui no se usan: sin cotejar)
  galope.gif       las cuatro series de la animacion (0x9A20, por `tabla_umbral` 0x80BB: un dibujo cada 8 pasos):
                   el galope (2, 3, 0, 1), el salto (4, 5, 9, 6), la caida (8, 5, 7, 2) y en el suelo (7, 2, 2, 2);
                   con el paso 0x20 (la velocidad 0x60 de 0x961F: `suma_paso`, 0x80A3, da un paso cada dos cuadros),
                   un dibujo cada 16 cuadros

Uso: hojas.py docs/imagenes | hojas.py cotejo
"""
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
import vdp          # noqa: E402

ORG = 0x8000
ROM = open(os.path.join(RAIZ, "excitingjockey.rom"), "rb").read()
FONDO = (40, 96, 40)        # un verde de hierba, para que se vea el negro
COLORES = [1, 13, 6, 4]
SERIES = {"galope": 0x9A20, "salto": 0x9A28, "caida": 0x9A30, "suelo": 0x9A38}


def b(a):
    return ROM[a - ORG]


def s8(v):
    return v - 256 if v > 127 else v


def patrones():
    return ROM[0xAC1B - ORG:0xAC1B - ORG + 0x800]


def pinta(im, pat, n, x, y, color, escala=1):
    if color == 0:
        return
    d = pat[n * 8:n * 8 + 32]
    c = vdp.PALETA[color]
    for fila in range(16):
        for col in range(16):
            if (d[fila + (16 if col >= 8 else 0)] >> (7 - (col & 7))) & 1:
                for ey in range(escala):
                    for ex in range(escala):
                        px, py = (x + col) * escala + ex, (y + fila) * escala + ey
                        if 0 <= px < im.width and 0 <= py < im.height:
                            im.putpixel((px, py), c)


def caballo(dibujo, color):
    """Los tres sprites (dy, dx, dibujo, color) del dibujo del caballo."""
    a = 0xB3DB + 9 * dibujo
    return [(s8(b(a + 3 * k + 1)), s8(b(a + 3 * k + 2)), b(a + 3 * k), color) for k in range(3)]


def jinete(numero, postura):
    a = 0x9D99 + 3 * (4 * postura + numero)
    return (s8(b(a + 1)), s8(b(a + 2)), b(a), 15)


def serie(nombre):
    """Los cuatro dibujos de una serie, por tabla_umbral (umbrales 0, 8, 16, 24: el valor de +4 a +7)."""
    a = SERIES[nombre]
    return [b(a + 4 + k) for k in range(4)]


def grupo(im, pat, sprites, x0, y0, E):
    for dy, dx, n, c in reversed(sprites):
        pinta(im, pat, n, x0 + dx, y0 + dy, c, E)


def hoja_caballos(Image):
    pat, E = patrones(), 3
    im = Image.new("RGB", (10 * 40 * E, 4 * 36 * E), FONDO)
    for k, color in enumerate(COLORES):
        for d in range(10):
            grupo(im, pat, caballo(d, color), d * 40 + 20, k * 36 + 22, E)
    return im


def hoja_jinetes(Image):
    pat, E = patrones(), 3
    im = Image.new("RGB", (8 * 40 * E, 36 * E), FONDO)
    for postura in (0, 1):
        for n in range(4):
            x0, y0 = (postura * 4 + n) * 40 + 20, 24
            dy, dx, dib, color = jinete(n, postura)
            pinta(im, pat, dib, x0 - 8, y0 - 8, color, E)
    return im


def anima(Image):
    pat, E, cuadros = patrones(), 3, []
    for nombre in ("galope", "galope", "salto", "caida", "suelo"):
        for d in serie(nombre):
            im = Image.new("RGB", (4 * 40 * E, 36 * E), FONDO)
            for k, color in enumerate(COLORES):
                grupo(im, pat, caballo(d, color), k * 40 + 20, 22, E)
            cuadros += [im] * 16
    return cuadros


def guarda_gif(cuadros, ruta, ms=1000 / 60):
    imgs, durs = [], []
    for im in cuadros:
        if imgs and list(im.getdata()) == list(imgs[-1].getdata()):
            durs[-1] += ms
        else:
            imgs.append(im)
            durs.append(ms)
    imgs[0].save(ruta, save_all=True, append_images=imgs[1:], duration=[max(20, int(round(d))) for d in durs],
                 loop=0, disposal=1)


def cotejo():
    """Contra las grabaciones de openMSX (work/*.bin, la RAM 0xE000-0xF3FF):
    1) la tabla de dibujos de los sprites (VRAM 0x3800-0x3FFF) contra los 2 KB de 0xAC1B;
    2) los tres sprites de cada caballo en marcha (sus bloques 0xE07F, 0xE09F, 0xE0BF y 0xE0DF; sus sprites en la
       copia de la tabla, 0xE198, 0xE1A4, 0xE1B0 y 0xE1BC) contra `caballo()` con el dibujo (+5), la Y (+2) y el
       color (+6) del bloque: el dibujo, la Y y el color de cada sprite (la X pasa por el borde de la pantalla)."""
    pat = patrones()
    tot = dict(patrones=0, pat_mal=0, caballos=0, cab_antes=0, cab_y=0, cab_mal=0)
    antes = {}
    bloques = [(0x07F, 0x198), (0x09F, 0x1A4), (0x0BF, 0x1B0), (0x0DF, 0x1BC)]
    for grab in ("atraccion", "partida", "jinete", "apuesta", "musicas"):
        ruta = os.path.join(RAIZ, "work", grab + ".bin")
        if not os.path.exists(ruta):
            continue
        for c in vdp.cuadros(ruta):
            v, ram = c["vram"], c["ram"]
            t = v[0x3800:0x4000]
            if any(t):
                tot["patrones"] += t == pat
                tot["pat_mal"] += t != pat
            for blo, spr in bloques:
                if not (1 < ram[blo] < 8) or ram[blo + 5] > 9:
                    continue
                quiero = caballo(ram[blo + 5], ram[blo + 6])
                hay = [ram[spr + 4 * k:spr + 4 * k + 4] for k in range(3)]
                if any(h[0] >= 0xC0 for h in hay):
                    continue                     # fuera de la pantalla
                tot["caballos"] += 1
                ok = all(h[2] == q[2] and (h[3] & 15) == (q[3] & 15) and h[0] == (ram[blo + 2] + q[0]) & 0xFF
                         for h, q in zip(hay, quiero))
                if ok:
                    continue
                p = antes.get((grab, blo))
                if p is not None and p[5] <= 9 and all(h[2] == q[2] and h[0] == (p[2] + q[0]) & 0xFF
                                                        for h, q in zip(hay, caballo(p[5], p[6]))):
                    tot["cab_antes"] += 1           # compuesto con el estado del cuadro anterior
                elif all(h[2] == q[2] and (h[3] & 15) == (q[3] & 15) and abs(h[0] - ram[blo + 2] - q[0]) <= 2
                         for h, q in zip(hay, quiero)):
                    tot["cab_y"] += 1               # el mismo dibujo; la Y, movida despues de componer
                else:
                    tot["cab_mal"] += 1
            for blo, _ in bloques:
                antes[(grab, blo)] = bytes(ram[blo:blo + 8])
    return tot


def main(argv):
    if argv and argv[0] == "cotejo":
        print(cotejo())
        return 0
    from PIL import Image
    salida = argv[0]
    os.makedirs(salida, exist_ok=True)
    hoja_caballos(Image).save(os.path.join(salida, "caballos.png"))
    hoja_jinetes(Image).save(os.path.join(salida, "jinetes.png"))
    guarda_gif(anima(Image), os.path.join(salida, "galope.gif"))
    for f in ("caballos.png", "jinetes.png", "galope.gif"):
        print(f, os.path.getsize(os.path.join(salida, f)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
