#!/usr/bin/env python3
"""EL CONTENIDO de la web de esta ROM: lo unico que es de este juego.

jekyll.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.

Todas las cifras de aqui estan medidas sobre esta ROM, con las herramientas
de tools/: CODIGO y DATOS los imprime tools/presupuesto.py (make sanity),
INSTRUCCIONES, COMENTARIOS y RUTINAS los da tools/densidad.py (make densidad:
"de N" rutinas, "N instrucciones, M comentarios").
"""

NOMBRE = "Exciting Jockey"
EDITOR = "Casio"
ANIO = 1984
REPOSITORIO = "https://github.com/antxiko/ExcitingJockey-disassembly"
SHA1 = "5b17cb69697cf55dff1f0b8777e19d5abc1771fc"

CODIGO = 9039
DATOS = 7345
RUTINAS = 505
INSTRUCCIONES = 4521
COMENTARIOS = 1919


def densidad(idioma):
    """El porcentaje comentado, con la coma o el punto de cada idioma."""
    d = "%.1f" % (100.0 * COMENTARIOS / INSTRUCCIONES)
    return d.replace(".", ",") if idioma == "es" else d


PIE_LEGAL = {
    "es": "<em>Exciting Jockey</em> (大障害競馬) es un juego de Casio para MSX, de 1984, en un "
          "cartucho de 16 KB. Todos los derechos sobre el juego siguen siendo de sus titulares. "
          "Este trabajo es de preservaci&oacute;n, estudio y documentaci&oacute;n, y la imagen de "
          "la ROM no se distribuye.",
    "en": "<em>Exciting Jockey</em> (大障害競馬) is a 1984 Casio game for the MSX, on a 16 KB "
          "cartridge. All rights in the game remain with their holders. This is preservation, "
          "study and documentation work, and the ROM image is not distributed.",
}

PORTADA = {
    "es": dict(
        titulo="Exciting Jockey - desensamblado comentado",
        claim="Carreras de obst&aacute;culos con cuatro caballos: llevar uno con el l&aacute;tigo "
              "y el salto, o apostar entre uno y cuatro jugadores a las parejas que llegan "
              "primero y segundo. Las nueve carreras, las vallas, las r&iacute;as y las matas, "
              "las ca&iacute;das y el jinete despedido, las cuotas que salen de la fuerza de "
              "cada caballo; la pantalla desde los bytes de la ROM, cotejada con openMSX; las "
              "carreras en GIF y las siete m&uacute;sicas de su propio motor, id&eacute;nticas "
              "a openMSX cuadro a cuadro.",
        ficha=["Casio - <b>(c) 1984</b>",
               "Cartucho de <b>16 KB</b> en 0x8000",
               "<b>MSX</b>", "Volcado <b>5b17cb69...</b>"],
        aviso="<b>Aqu&iacute; no hay capturas del juego.</b> El logotipo y la "
              "selecci&oacute;n salen de ejecutar la ROM (cotejadas con openMSX), y los "
              "GIF son la ROM <b>funcionando en openMSX</b>: en cada cuadro se "
              "apuntan la VRAM y los registros del VDP, y <b>c&oacute;digo nuestro "
              "los pinta</b>.",
    ),
    "en": dict(
        titulo="Exciting Jockey - commented disassembly",
        claim="Steeplechase with four horses: riding one with the whip and the jump, or betting "
              "between one and four players on the pairs that finish first and second. The nine "
              "races, the fences, the water jumps and the shrubs, the falls and the thrown "
              "jockey, the odds that come from each horse's strength; the screen from the ROM's "
              "bytes, checked against openMSX; the races in GIF and the seven tunes from its own "
              "engine, identical to openMSX frame by frame.",
        ficha=["Casio - <b>(c) 1984</b>",
               "<b>16 KB</b> cartridge at 0x8000",
               "<b>MSX</b>", "Dump <b>5b17cb69...</b>"],
        aviso="<b>There are no screenshots of the game here.</b> The logo and the "
              "selection come from running the ROM (checked against openMSX), and the "
              "GIFs are the ROM <b>running in openMSX</b>: on every frame the VRAM and "
              "the VDP registers are logged, and <b>our own code paints them</b>.",
    ),
}

PAGINAS = [
    [("THE-GAME.html", "LA-PARTIDA.html", "The game", "La partida",
      "the five modes, the controls, the jockey's whip and jump, the horses of the computer and "
      "the nine races, as the code has them",
      "los cinco modos, los mandos, el l&aacute;tigo y el salto del jinete, los caballos del "
      "ordenador y las nueve carreras, como los tiene el c&oacute;digo"),
     ("THE-RACES.html", "LAS-CARRERAS.html", "The races", "Las carreras",
      "the screens, the nine races and their obstacles, played in GIF: the start, the jump, the "
      "fall, the shrub and the finish",
      "las pantallas, las nueve carreras y sus obst&aacute;culos, jugadas en GIF: la salida, el "
      "salto, la ca&iacute;da, la mata y la meta"),
     ("THE-BETS.html", "LAS-APUESTAS.html", "The bets", "Las apuestas",
      "the odds, how to bet and how the winners are paid, in GIF",
      "las cuotas, c&oacute;mo se apuesta y c&oacute;mo se paga, en GIF"),
     ("THE-SPRITES.html", "LOS-SPRITES.html", "The sprites", "Los sprites",
      "the ten drawings of the horse in the four colours, its animations and the jockey, put together from the ROM "
      "tables",
      "los diez dibujos del caballo en los cuatro colores, sus animaciones y el jinete, montados desde las tablas de "
      "la ROM"),
     ("THE-TEXTS.html", "LOS-TEXTOS.html", "The texts", "Los textos",
      "every text in the ROM, with its translation",
      "todos los textos de la ROM, con su traducci&oacute;n"),
     ("THE-MUSIC.html", "LA-MUSICA.html", "The music", "La m&uacute;sica",
      "the seven tunes, from its own sound engine and checked against openMSX",
      "las siete m&uacute;sicas, de su propio motor de sonido y cotejadas con openMSX")],
    [("CURIOSITIES.html", "CURIOSIDADES.html", "Curiosities", "Curiosidades",
      "data hidden among the sprites, a game run from the interrupt, the endless gallop and the "
      "code nobody calls",
      "datos escondidos entre los sprites, un juego que corre en la interrupci&oacute;n, el "
      "galope sin fin y el c&oacute;digo que nadie llama"),
     ("SECRETS-AND-BUGS.html", "SECRETOS-Y-FALLOS.html", "Secrets and bugs", "Secretos y fallos",
      "what was searched for: no hidden keys, the money that goes back to zero past 999,900 and the whip queue",
      "lo que se ha buscado: ninguna tecla escondida, el dinero que vuelve a cero pasados los 999.900 y la cola del "
      "l&aacute;tigo")],
    [("UNDER-THE-HOOD.html", "POR-DENTRO.html", "Under the hood", "Por dentro",
      "rebuilding the ROM, the BIOS it uses, the interrupt, the state machine, the RAM and the "
      "tools",
      "rehacer la ROM, la BIOS que usa, la interrupci&oacute;n, la m&aacute;quina de estados, "
      "la RAM y las herramientas")],
]

# Repositorio nuevo: no hay paginas viejas que redirigir.
VIEJAS = {}

LOGOTIPO = "logotipo.png"

