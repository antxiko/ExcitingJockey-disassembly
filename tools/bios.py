#!/usr/bin/env python3
"""Un MSX1 lo justo para EJECUTAR los cartuchos de Casio y que pinten su VRAM: el Z80 de z80run.py
con las rutinas de la BIOS que usan, hechas a mano (los Casio dibujan casi todo con la BIOS).

    m = Msx(rom, org)          la ROM en su sitio; RAM de 0xC000 a 0xFFFF
    m.llama(dir)               call dir, hasta que vuelve
    m.hasta(dir, parada, ganchos={pc: funcion})
    m.vdp.vram, m.vdp.regs     lo pintado

Lo que no esta aqui revienta (ParadaZ80): nada se supone.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from z80run import Z80, ParadaZ80   # noqa: E402  (se copia z80run.py a comun/casio/ desde un proyecto)

# los registros que deja CHGMOD en SCREEN 2 (tablas del MSX: nombres 0x1800, colores 0x2000,
# patrones 0x0000, atributos 0x1B00, dibujos de sprites 0x3800)
SCREEN2 = bytes([0x02, 0xE0, 0x06, 0xFF, 0x03, 0x36, 0x07, 0x00])


class Msx(Z80):
    def __init__(self, rom, org):
        super().__init__()
        self.carga(rom, org)
        self.org, self.fin = org, org + len(rom)
        self.mem[0xF3E9:0xF3EC] = bytes([15, 4, 7])       # FORCLR, BAKCLR, BDRCLR (los de C-BIOS)
        self.teclas = bytearray([0xFF] * 11)
        self.stick = 0
        self.trig = 0
        self.psg = bytearray(16)
        self.fuente = None          # los 2 KB de la fuente de la BIOS, para INIT32

    def _escribir(self, d, v):
        d &= 0xFFFF
        if self.org <= d < self.fin:
            return
        self.mem[d] = v & 0xFF

    def _bios(self):
        pc, v = self.pc, self.vdp
        if pc == 0x0047:                                  # WRTVDP: C el registro, B el valor
            v.regs[self.c & 7] = self.b
        elif pc == 0x004A:                                # RDVRM
            self.a = v.vram[self.hl & 0x3FFF]
        elif pc == 0x004D:                                # WRTVRM
            v.vram[self.hl & 0x3FFF] = self.a
        elif pc == 0x0053:                                # SETWRT
            v.dir = self.hl & 0x3FFF
        elif pc == 0x0050:                                # SETRD
            v.dir = self.hl & 0x3FFF
        elif pc == 0x0056:                                # FILVRM: HL, BC bytes de A
            for i in range(self.bc):
                v.vram[(self.hl + i) & 0x3FFF] = self.a
        elif pc == 0x0059:                                # LDIRMV: VRAM HL -> RAM DE, BC bytes
            for i in range(self.bc):
                self._escribir(self.de + i, v.vram[(self.hl + i) & 0x3FFF])
        elif pc == 0x005C:                                # LDIRVM: RAM HL -> VRAM DE, BC bytes
            for i in range(self.bc):
                v.vram[(self.de + i) & 0x3FFF] = self.mem[(self.hl + i) & 0xFFFF]
        elif pc == 0x005F:                                # CHGMOD
            assert self.a == 2, "CHGMOD %d" % self.a
            v.regs[:] = SCREEN2
            v.regs[7] = self.mem[0xF3EB]
        elif pc == 0x006F:                                # INIT32: SCREEN 1 con la fuente de la BIOS
            v.regs[:] = bytes([0x00, 0xE0, 0x06, 0x80, 0x00, 0x36, 0x07, self.mem[0xF3E9] << 4 | self.mem[0xF3EB]])
            assert self.fuente, "INIT32 necesita la fuente de la BIOS (Msx.fuente)"
            v.vram[0:0x800] = self.fuente
            v.vram[0x1800:0x1B00] = bytes([0x20]) * 0x300
            v.vram[0x2000:0x2020] = bytes([self.mem[0xF3E9] << 4 | self.mem[0xF3EA]]) * 32
        elif pc == 0x0072:                                # INIGRP: SCREEN 2, nombres 0-255 en cada tercio
            v.regs[:] = SCREEN2
            v.regs[7] = self.mem[0xF3E9] << 4 | self.mem[0xF3EB]
            v.vram[0x1800:0x1B00] = bytes(range(256)) * 3
            v.vram[0:0x1800] = bytes(0x1800)
            v.vram[0x2000:0x3800] = bytes([self.mem[0xF3E9] << 4 | self.mem[0xF3EA]]) * 0x1800
        elif pc == 0x0062:                                # CHGCLR
            v.regs[7] = self.mem[0xF3EB] & 0x0F
        elif pc == 0x0041:                                # DISSCR
            v.regs[1] &= 0xBF
        elif pc == 0x0044:                                # ENASCR
            v.regs[1] |= 0x40
        elif pc == 0x0069:                                # CLRSPR: atributos fuera (Y = 209)
            for i in range(32):
                v.vram[0x1B00 + 4 * i] = 209
        elif pc in (0x0090, 0x0138):                      # GICINI, RSLREG (no se usa lo que deja)
            pass
        elif pc == 0x0093:                                # WRTPSG
            self.psg[self.a & 15] = self.e
        elif pc == 0x0096:                                # RDPSG
            self.a = self.psg[self.a & 15]
        elif pc == 0x00D5:                                # GTSTCK
            self.a = self.stick
        elif pc == 0x00D8:                                # GTTRIG
            self.a = self.trig
        elif pc == 0x0141:                                # SNSMAT
            self.a = self.teclas[self.a]
        else:
            raise ParadaZ80("llamada a la BIOS 0x%04X" % pc)
        self.pc = self._pop()

    def hasta(self, desde, parada, ganchos=None, tope=60_000_000):
        self.pc = desde
        n = 0
        ganchos = ganchos or {}
        while self.pc != parada:
            if self.pc in ganchos:
                ganchos[self.pc](self)
                if self.pc == parada:
                    break
            if self.pc < 0x4000:
                self._bios()
                continue
            n += 1
            if n > tope:
                raise ParadaZ80("no se llego a 0x%04X" % parada)
            self._una()

    def llama(self, d, ganchos=None, sp=0xF380):
        self.sp = sp
        self._escribir16(self.sp, 0xFFF0)
        self.hasta(d, 0xFFF0, ganchos)
