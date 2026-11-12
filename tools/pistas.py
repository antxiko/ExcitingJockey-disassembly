"""Las pistas de las nueve carreras de Exciting Jockey, PINTADAS EJECUTANDO LA ROM, enteras de la salida a la meta:
pista_monta (0x8D7D) monta la salida (la pista en la RAM, 0xED00: 16 filas de 32 casillas) y despues, una y otra vez,
la parte de pista_corre que corre la pista una casilla (0x911A: todo un byte a la derecha, la columna nueva por la
izquierda, y cada cinco columnas el paso siguiente con sus arbustos, carteles y obstaculos) hasta que el paso llega
al ultimo (0xBB) y la pista se para. Las columnas que van entrando se ponen a la izquierda: la salida a la derecha y
la meta a la izquierda, como se ve correr. Sobre la RAM y la VRAM de un cuadro grabado de una carrera
(work/apuesta.bin: las casillas); los colores de hierba o tierra los pone pista_pinta.

El suelo lo echa al azar el juego con el registro R del Z80 (suelo_azar, 0x901C): aqui sale el de esta ejecucion,
como saldria en una carrera cualquiera; los arbustos, los carteles, la valla y los obstaculos son los de la carrera.

Uso: pistas.py docs/imagenes
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import vdp                  # noqa: E402
from bios import Msx        # noqa: E402
from PIL import Image       # noqa: E402

RAIZ = os.path.dirname(AQUI)
ROM = open(os.path.join(RAIZ, "excitingjockey.rom"), "rb").read()


def pista(c, carrera):
    m = Msx(ROM, 0x8000)
    m.mem[0xE000:0xF000] = c["ram"]
    m.vdp.vram[:] = c["vram"]
    m.mem[0xE000] = carrera
    m.ix = 0xE06C
    m.llama(0x8D7D)                         # pista_monta
    cols = [bytes(m.mem[0xED00 + 32 * f + k] for f in range(16)) for k in range(32)]
    for _ in range(2000):
        m.ix = 0xE06C
        m.mem[0xE06C] = 2
        m.llama(0x911A)                     # una casilla
        cols.insert(0, bytes(m.mem[0xED00 + 32 * f] for f in range(16)))
        if m.mem[0xE071] == 0xBB:
            break
    return cols, bytes(m.vdp.vram)


def main(salida):
    base = None
    for c in vdp.cuadros(os.path.join(RAIZ, "work", "apuesta.bin")):
        if c["regs"][1] & 0x40 and c["ram"][0x05E] == 4:
            base = c
            break
    tiras = []
    for carrera in range(1, 10):
        cols, vram = pista(base, carrera)
        tira = Image.new("RGB", (8 * len(cols), 128))
        for k in range(0, len(cols), 32):
            trozo = cols[k:k + 32]
            v = bytearray(vram)
            for f in range(16):
                fila = bytes(col[f] for col in trozo) + bytes(32 - len(trozo))
                v[0x18C0 + 32 * f:0x18C0 + 32 * f + 32] = fila
            pant = vdp.imagen(bytes(v), base["regs"], 1, con_sprites=False)
            tira.paste(pant.crop((0, 48, 8 * len(trozo), 176)), (8 * k, 0))
        tiras.append(tira)
        print("carrera %d: %d columnas" % (carrera, len(cols)))
    hoja = Image.new("RGB", (max(t.size[0] for t in tiras), 9 * 136 - 8), (0, 0, 0))
    for i, t in enumerate(tiras):
        hoja.paste(t, (hoja.size[0] - t.size[0], i * 136))     # todas con la salida a la derecha
    hoja = hoja.resize((hoja.size[0] // 2, hoja.size[1] // 2), Image.NEAREST)
    ruta = os.path.join(salida, "pistas.png")
    hoja.save(ruta, optimize=True)
    print(ruta, hoja.size)


if __name__ == "__main__":
    main(sys.argv[1])
