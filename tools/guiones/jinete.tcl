# Una partida en el modo A (el jinete): la barra (boton 1) en el cuadro 200 elige el modo y en el 700 el
# caballo 1, y desde el 760 GRAPH (el boton 2 en el teclado, fila 6 0x04) cada 40 cuadros: sale y salta.
# Arriba o abajo cada 90. 12000 cuadros.
proc guion {n} {
    if {$n == 200 || $n == 700} { keymatrixdown 8 0x01 }
    if {$n == 206 || $n == 706} { keymatrixup 8 0x01 }
    if {$n > 760} {
        if {$n % 40 == 0} { keymatrixdown 6 0x04 }
        if {$n % 40 == 5} { keymatrixup 6 0x04 }
        if {$n % 90 == 0} {
            keymatrixup 8 0xF0
            keymatrixdown 8 [lindex {0x20 0x00 0x40 0x00} [expr {($n / 90) % 4}]]
        }
    }
    return [expr {$n >= 12000}]
}
