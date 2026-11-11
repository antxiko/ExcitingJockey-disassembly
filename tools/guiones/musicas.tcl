# Para cotejar las tres musicas que una partida corta no alcanza: en la seleccion (que no suena), el bucle
# principal (0x803C) llama a `pieza` (0x80DB), la rutina del juego que pone una pieza en un canal, con las
# dos piezas de cada musica: el premio del jinete (cuadro 300: canal 1 0xBF32, canal 2 0xBF54), el primero
# de la carrera 9 (1800: 0xBF97, 0xBFB9) y las nueve carreras hechas (3300: canal 0 0xBEDC, canal 1
# 0xBF07). Arriba cada 400 cuadros, para que no empiece la demostracion. 6000 cuadros. Solo vale para el
# sonido.
set ::cola {}
proc llama {b de} {
    set sp [expr {[reg sp] - 2}]
    debug write memory $sp 0x3C
    debug write memory [expr {$sp + 1}] 0x80
    reg sp $sp
    reg b $b
    reg de $de
    reg pc 0x80DB
}
debug set_bp 0x803C {} {
    if {[llength $::cola]} {
        set p [lindex $::cola 0]
        set ::cola [lrange $::cola 1 end]
        llama [lindex $p 0] [lindex $p 1]
    }
}
proc guion {n} {
    if {$n == 300} { set ::cola {{1 0xBF32} {2 0xBF54}} }
    if {$n == 1800} { set ::cola {{1 0xBF97} {2 0xBFB9}} }
    if {$n == 3300} { set ::cola {{0 0xBEDC} {1 0xBF07}} }
    if {$n % 400 == 0} { keymatrixdown 8 0x20 }
    if {$n % 400 == 5} { keymatrixup 8 0x20 }
    return [expr {$n >= 6000}]
}
