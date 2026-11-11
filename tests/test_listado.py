"""Lo que se afirma de la ROM, comprobado contra sus bytes.

Corre con la ROM delante y sin ella: cuando no esta, la imagen se rehace desde
las filas defb/defw del listado, que si viaja con el repositorio. Sin la ROM
solo se comprueba lo que cae en datos.
"""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "excitingjockey.rom")
ASM = os.path.join(RAIZ, "src", "excitingjockey.asm")
NOTAS = os.path.join(RAIZ, "src", "excitingjockey.notes")
ORG = 0x8000
TAM = 16384

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")


def imagen_desde_el_listado():
    img = bytearray(TAM)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()
    return imagen_desde_el_listado()


def b(a):
    return lee()[a - ORG]


def w(a):
    rom = lee()
    return rom[a - ORG] | (rom[a - ORG + 1] << 8)


def instruccion(dirr):
    """La instruccion del listado en esa direccion (sin el comentario)."""
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = re.match(r"^\t(\S.*?)\s*;([0-9a-f]{4})", ln)
            if m and int(m.group(2), 16) == dirr:
                return m.group(1).replace("\t", " ").strip()
    return None


class Cabecera(unittest.TestCase):
    def test_ab_e_init_en_0x8010(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(w(0x8002), 0x8010)
        self.assertEqual(rom[4:16], bytes(12))

    def test_son_16_kb(self):
        self.assertEqual(len(lee()), TAM)


class LaInterrupcion(unittest.TestCase):
    def test_una_sola_interrupcion_en_h_timi(self):
        self.assertEqual([instruccion(0x8016), instruccion(0x8019)], ["ld hl,0805bh", "ld (0fda0h),hl"])
        with open(ASM, encoding="utf-8") as f:
            self.assertEqual(f.read().count("ld (0fda0h),hl"), 1)

    def test_los_registros_del_vdp_son_screen_2(self):
        self.assertEqual(list(lee()[0x8053 - ORG:0x805B - ORG]), [0x02, 0xA2, 0x06, 0xFF, 0x03, 0x36, 0x07, 0x01])


class LasTablasDeSaltos(unittest.TestCase):
    TABLAS = {0x83EC: 5, 0x8650: 3, 0x886C: 5, 0x8A73: 9, 0x8D3B: 3, 0x8D79: 2, 0x91B2: 5, 0x974E: 7,
              0x979E: 2, 0x9B2C: 2, 0x9BA0: 3, 0x9C18: 2, 0x9C55: 2, 0x9D37: 4, 0x9E45: 2}

    def test_cada_call_0x8083_lleva_detras_su_tabla(self):
        rom = lee()
        llamadas = [i + 3 + ORG for i in range(len(rom) - 3) if rom[i:i + 3] == bytes([0xCD, 0x83, 0x80])]
        self.assertEqual(sorted(llamadas), sorted(self.TABLAS))
        for t, n in self.TABLAS.items():
            for k in range(n):
                self.assertTrue(0x8000 <= w(t + 2 * k) < 0xAC1B, hex(t))


class LaCarrera(unittest.TestCase):
    def test_nueve_carreras_de_hierba_o_tierra(self):
        c = list(lee()[0x8DA3 - ORG:0x8DAC - ORG])
        self.assertEqual(c[0], 0x80)          # la 1: hierba, sin obstaculos, 1200 m
        self.assertEqual(c[8], 0x64)          # la 9: tierra, serie 6, 3600 m
        self.assertEqual(sum(1 for x in c if x & 0x80), 5)

    def test_las_distancias_de_25_en_25_metros(self):
        pasos = [w(0xA0FB + 2 * k) for k in range(5)]
        self.assertEqual([p * 25 for p in pasos], [1200, 1600, 2400, 3200, 3600])

    def test_la_pareja_ganadora_por_la_suma_de_los_dos_primeros(self):
        valores = list(lee()[0x988F - ORG:0x9893 - ORG])
        parejas = list(lee()[0x9865 - ORG:0x986B - ORG])
        orden = [(1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        for a, b_ in orden:
            s = valores[a - 1] + valores[b_ - 1]
            self.assertEqual(parejas[(s - 0x20) // 2 - 1], 0x80 + orden.index((a, b_)))

    def test_los_premios_del_jinete(self):
        p = list(lee()[0xAC01 - ORG:0xAC13 - ORG])
        self.assertEqual(p[0:2], [0x10, 0x05])
        self.assertEqual(p[16:18], [0x90, 0x45])
        self.assertEqual(list(lee()[0x88E6 - ORG:0x88EF - ORG]), p[0::2])


class LosMandos(unittest.TestCase):
    def test_el_boton_2_del_teclado_es_graph(self):
        self.assertEqual([instruccion(a) for a in (0x94BC, 0x94BE, 0x94C1, 0x94C2)],
                         ["ld a,006h", "call 00141h", "cpl", "and 004h"])

    def test_los_textos(self):
        rom = lee()
        self.assertEqual(rom[0x851A - ORG:0x8527 - ORG], b"PLAYER SELECT")
        self.assertEqual(rom[0x8794 - ORG:0x87A1 - ORG], b"DEMONSTRATION")
        self.assertEqual(rom[0x8C44 - ORG:0x8C4D - ORG], b"GAME" + bytes([0xE2]) + b"OVER")


class Sonido(unittest.TestCase):
    def test_doce_ordenes_con_el_tempo_y_el_transporte(self):
        t = [w(0x8308 + 2 * k) for k in range(12)]
        self.assertEqual(t[7], 0x82A0)   # 0xF8: el tempo
        self.assertEqual(t[8], 0x82A4)   # 0xF7: el transporte

    def test_doce_periodos_de_mas_grave_a_mas_agudo(self):
        t = [w(0x8330 + 2 * k) for k in range(12)]
        self.assertTrue(all(x > y for x, y in zip(t, t[1:])))


class LoQueNadieUsa(unittest.TestCase):
    def test_la_rutina_de_0xa150_no_la_llama_nadie(self):
        rom = lee()
        for op in (0xCD, 0xC3, 0xC4, 0xCC, 0xD4, 0xDC, 0xC2, 0xCA, 0xD2, 0xDA):
            self.assertNotIn(bytes([op, 0x50, 0xA1]), rom)
        self.assertNotIn(bytes([0x50, 0xA1]), rom[0x83EC - ORG:0x9E49 - ORG])

    def test_el_ret_suelto_de_0x9ee6(self):
        self.assertEqual(instruccion(0x9EE4), "jr meta_color")
        self.assertEqual(b(0x9EE6), 0xC9)


class ElListado(unittest.TestCase):
    def test_densidad_y_flojas(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertGreaterEqual(int(m.group(2)) * 100, 40 * int(m.group(1)))
        self.assertIn("---- 0 rutinas por debajo del 10 %", salida)

    def test_ningun_call_sin_nombre(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "sin_bautizar.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        self.assertTrue(salida.startswith("0 rutinas sin bautizar"), salida[:200])

    def test_cada_comentario_en_su_instruccion(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "valida_c.py"), ASM, NOTAS],
            capture_output=True, text=True, check=True).stdout
        self.assertIn("0 fuera de sitio, 0 repetidos", salida)


if __name__ == "__main__":
    unittest.main()
