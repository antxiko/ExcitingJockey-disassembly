# Secretos y fallos

Lo que se ha buscado en el código y lo que se ha encontrado. Un fallo solo entra aquí si está comprobado:
ejecutando la propia rutina del juego (`tools/bios.py`) o contra las grabaciones de openMSX.

## Secretos: ninguno escondido

- **Ninguna tecla escondida.** Los mandos se leen en un solo sitio (`mandos`, 0x9469): la palanca de los mandos 1 y 2
  o los cursores (GTSTCK), el botón 1 de los dos mandos o la barra espaciadora, y el botón 2 de los dos mandos o GRAPH,
  leída con SNSMAT en la fila 6 (0x94BC). No hay ninguna otra lectura del teclado en la ROM: ninguna tecla al
  encender, ninguna en la selección.
- **Ni modos ni carreras escondidas**: los cinco modos y las nueve carreras son los de [La partida](LA-PARTIDA.html)
  y [Las carreras](LAS-CARRERAS.html); lo único sin usar son los once bytes de código y los ocho de datos que se
  cuentan en [Curiosidades](CURIOSIDADES.html).

## Fallo: el dinero vuelve a cero pasados los 999.900

Cada jugador guarda su dinero en **tres bytes** BCD desde 0xE030 (en puntos; la pantalla les pone dos ceros detrás).
Al apostar, el punto se quita de los tres bytes (`apuesta_punto`, 0xA45C). Pero el pago (`pago`, 0xA2F5) suma la cuota
**solo a los dos primeros**, y el acarreo del segundo se pierde (0xA33D); y el marcador solo enseña cuatro cifras
(`dinero_pon`, 0xA674). Así que al pasar de 9.999 puntos el dinero vuelve a empezar.

Ejecutando aquí el pago del juego, con el jugador 1 cobrando lo apostado a la pareja ganadora:

| tenía | apostado x cuota | en pantalla después | tendría que ser |
|---|---|---|---|
| 900.000 | 10 x 50 | `950000` | 950.000 |
| 950.000 | 10 x 50 | `0` | 1.000.000 |
| 990.000 | 99 x 99 | `970100` | 1.970.100 |

Ganar puede dejar a un jugador con menos de lo que tenía, y si da justo cero y nadie más tiene dinero, la apuesta
acaba en **GAME OVER** (`apuesta_final`, 0x8BFF, mira si los dieciséis bytes del dinero son cero). Para llegar
hace falta ganar mucho: se empieza con 10.000 y cada pareja admite 99 puntos.

## Fallo: la cola del látigo con más de ocho latigazos

Cada latigazo espera 32 cuadros en una cola de 16 (0xF0D7) antes de subir la velocidad. Cuando el primero sale,
`latigo_sale` (0xAB6C) corre la cola un sitio, pero copia **16 menos los que había** en vez de los que quedan
(0xAB7B). Hasta ocho en cola sobra y no pasa nada; con más, los últimos no se corren: uno se repite y otro se pierde.
Y el sitio 16 de la cola es el byte de la barra MIN-MAX (0xF0E6), que `barra_cuenta` reescribe en cada cuadro.

Ejecutando aquí `latigo_cuentas` (0xAB5C) cuadro a cuadro, con un latigazo cada dos cuadros:

| en cola | cuadros en los que sube la velocidad |
|---|---|
| 8 | 2, 4, 6, 8, 10, 12, 14, 16 (bien) |
| 9 | 2, 4, 6, 8, 10, 12, 14, 16, **16** (el noveno sale a la vez que el octavo) |
| 12 | 2, 4, 6, 8, 10, **10**, 12, **12**, 14, **14**, 16, **16** |
| 16 | 2, 4, 6, 8, **8**, ..., 18, **18** y el último a los **257** cuadros |

Dos que salen en el mismo cuadro ponen el látigo en «sube» una sola vez (`velocidad_jugador`, 0xAA2F), así que uno se
pierde. Con la mano no se llega: más de ocho latigazos en 32 cuadros son más de quince pulsaciones por segundo; con un
mando de disparo automático, sí.

## Otras cosas que fallan, contadas en [Curiosidades](CURIOSIDADES.html)

- **Las cuotas, pasadas dos veces** a decimal: 12 sale como 18, y el bucle da 256 vueltas en vez de seis.
- **El galope sin fin**: una orden «vuelve a la marca» sin marca.
