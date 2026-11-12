# Secrets and bugs

What was searched for in the code and what was found. A bug only goes here if it has been checked: by running the
game's own routine (`tools/bios.py`) or against the openMSX recordings.

## Secrets: none hidden

- **No hidden keys.** The controls are read in a single place (`mandos`, 0x9469): the stick of joysticks 1 and 2 or
  the cursor keys (GTSTCK), button 1 of either joystick or the space bar, and button 2 of either joystick or GRAPH,
  read with SNSMAT on row 6 (0x94BC). There is no other keyboard read in the ROM: no key at power-on, none on the
  selection screen.
- **No hidden modes or races**: the five modes and nine races are the ones in [The game](THE-GAME.html) and
  [The races](THE-RACES.html); the only unused things are the eleven bytes of code and eight of data described in
  [Curiosities](CURIOSITIES.html).

## Bug: the money goes back to zero past 999,900

Each player keeps their money in **three** BCD bytes from 0xE030 (in points; the screen adds two zeros after them).
When betting, the point is taken from all three bytes (`apuesta_punto`, 0xA45C). But the payout (`pago`, 0xA2F5) adds
the odds **to the first two only**, and the carry out of the second is lost (0xA33D); and the scoreboard only shows
four digits (`dinero_pon`, 0xA674). So past 9,999 points the money starts again.

Running the game's payout here, with player 1 collecting what was bet on the winning pair:

| had | bet x odds | on screen after | should be |
|---|---|---|---|
| 900,000 | 10 x 50 | `950000` | 950,000 |
| 950,000 | 10 x 50 | `0` | 1,000,000 |
| 990,000 | 99 x 99 | `970100` | 1,970,100 |

Winning can leave a player with less than before, and if it lands exactly on zero and nobody else has money, the
betting ends in **GAME OVER** (`apuesta_final`, 0x8BFF, checks whether the sixteen money bytes are zero). Getting there
takes a lot of winning: everyone starts with 10,000 and each pair takes up to 99 points.

## Bug: the whip queue with more than eight lashes

Each lash waits 32 frames in a queue of 16 (0xF0D7) before raising the speed. When the first one comes out,
`latigo_sale` (0xAB6C) shifts the queue one place, but copies **16 minus how many there were** instead of how many are
left (0xAB7B). Up to eight in the queue it copies more than needed and nothing happens; with more, the last ones are not
shifted: one is repeated and another is lost. And slot 16 of the queue is the MIN-MAX bar byte (0xF0E6), which
`barra_cuenta` rewrites every frame.

Running `latigo_cuentas` (0xAB5C) here frame by frame, with one lash every two frames:

| queued | frames in which the speed goes up |
|---|---|
| 8 | 2, 4, 6, 8, 10, 12, 14, 16 (right) |
| 9 | 2, 4, 6, 8, 10, 12, 14, 16, **16** (the ninth comes out with the eighth) |
| 12 | 2, 4, 6, 8, 10, **10**, 12, **12**, 14, **14**, 16, **16** |
| 16 | 2, 4, 6, 8, **8**, ..., 18, **18** and the last one after **257** frames |

Two coming out in the same frame set the whip to "up" only once (`velocidad_jugador`, 0xAA2F), so one is lost. By hand
it cannot be reached: more than eight lashes in 32 frames is more than fifteen presses per second; with an autofire
joystick, it can.

## Other things that go wrong, told in [Curiosities](CURIOSITIES.html)

- **The odds, converted twice** to decimal: 12 shows as 18, and the loop runs 256 times instead of six.
- **The endless gallop**: a "go back to the mark" order with no mark.
