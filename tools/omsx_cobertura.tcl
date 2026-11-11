# omsx_cobertura.tcl - que direcciones de la ROM se ejecutan jugando: una condicion en cada instruccion apunta
# cada PC nuevo entre COB_DESDE y COB_HASTA. Las teclas: la barra al principio y luego, cada 15 cuadros, una
# direccion al azar (srand fijo) y el disparo cada 7. COB_T segundos emulados; COB_SALIDA el fichero.
set throttle off
expr {srand(1)}
set ::d [expr {$::env(COB_DESDE)}]
set ::h [expr {$::env(COB_HASTA)}]
set ::n 0
proc cuadro {} {
    incr ::n
    if {[info exists ::env(COB_QUIETO)]} return
    if {$::n % 7 == 0} { keymatrixdown 8 0x01 }
    if {$::n % 7 == 3} { keymatrixup 8 0x01 }
    if {$::n % 15 == 0} {
        keymatrixup 8 0xF0
        set k [lindex {0x10 0x20 0x40 0x80 0x00 0x50 0x90} [expr {int(rand() * 7)}]]
        if {$k} { keymatrixdown 8 $k }
    }
    if {[info exists ::env(COB_TECLA)] && $::n % 200 == 100} { keymatrixdown {*}$::env(COB_TECLA) }
    if {[info exists ::env(COB_TECLA)] && $::n % 200 == 105} { keymatrixup {*}$::env(COB_TECLA) }
}
debug set_bp 0x0038 {} { cuadro }
debug set_condition "\[reg pc\] >= $::d && \[reg pc\] < $::h && !\[info exists ::v(\[reg pc\])\]" {set ::v([reg pc]) 1}
proc fin {} {
    set f [open $::env(COB_SALIDA) w]
    foreach k [lsort -integer [array names ::v]] { puts $f [format 0x%04X $k] }
    close $f
    exit
}
after time $::env(COB_T) fin
