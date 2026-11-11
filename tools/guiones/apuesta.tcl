# Una partida en el modo C (dos jugadores apuestan): abajo dos veces y la barra (boton 1) eligen el modo. En
# BET MODE el jugador 1 pone tres puntos en 1-2, 1-3 y 1-4, y el 2 en 2-3, 2-4 y 3-4: la barra pasa de mover
# a apostar, cada toque arriba es un punto, derecha y abajo mueven el cursor. GRAPH (el boton 2, fila 6 0x04)
# sale; despues, GRAPH cada 120 cuadros (la carrera siguiente). 9000 cuadros.
proc pulsa {n a f b} {
    if {$n == $a} { keymatrixdown $f $b }
    if {$n == $a + 5} { keymatrixup $f $b }
}
proc apuesta {n a} {
    pulsa $n $a 8 0x01
    pulsa $n [expr {$a + 20}] 8 0x20
    pulsa $n [expr {$a + 40}] 8 0x20
    pulsa $n [expr {$a + 60}] 8 0x20
    pulsa $n [expr {$a + 80}] 8 0x01
}
proc guion {n} {
    pulsa $n 200 8 0x40
    pulsa $n 215 8 0x40
    pulsa $n 240 8 0x01
    apuesta $n 780
    pulsa $n 890 8 0x80
    apuesta $n 920
    pulsa $n 1030 8 0x80
    apuesta $n 1060
    pulsa $n 1170 8 0x40
    pulsa $n 1200 8 0x80
    apuesta $n 1230
    pulsa $n 1340 8 0x80
    apuesta $n 1370
    pulsa $n 1480 8 0x80
    apuesta $n 1510
    pulsa $n 1620 6 0x04
    if {$n > 3300 && $n % 120 == 0} { keymatrixdown 6 0x04 }
    if {$n > 3300 && $n % 120 == 5} { keymatrixup 6 0x04 }
    return [expr {$n >= 9000}]
}
