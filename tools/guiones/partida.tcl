# Una partida en el modo A (el jinete): la A en el cuadro 150 y el boton en el 200; despues, la barra cada 12
# cuadros y una direccion distinta cada 60 (fila 8: 0x10 izquierda, 0x20 arriba, 0x40 abajo, 0x80 derecha).
# 9000 cuadros.
proc guion {n} {
    if {$n == 150} { keymatrixdown 2 0x40 }
    if {$n == 156} { keymatrixup 2 0x40 }
    if {$n == 200} { keymatrixdown 8 0x01 }
    if {$n == 206} { keymatrixup 8 0x01 }
    if {$n > 300} {
        if {$n % 12 == 0} { keymatrixdown 8 0x01 }
        if {$n % 12 == 4} { keymatrixup 8 0x01 }
        if {$n % 60 == 0} {
            keymatrixup 8 0xF0
            keymatrixdown 8 [lindex {0x20 0x80 0x40 0x10 0x20 0x80} [expr {($n / 60) % 6}]]
        }
    }
    return [expr {$n >= 9000}]
}
