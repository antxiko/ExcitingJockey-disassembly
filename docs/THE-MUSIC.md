# The music

Seven tunes, on the three channels of the PSG. They are not recorded by hand:
`tools/musica.py` **runs the ROM's own sound engine** with `tools/z80run.py` -`pieza`
(0x80DB) with each piece on its channel and, every frame, `sonido_cuadro` (0x813A)- and logs
what it writes to the PSG through the BIOS (WRTPSG and RDPSG).

**Checked against openMSX**: the tone and volume registers match the recorded ones, **0
different** in all seven, for as long as each piece plays. The game puts most of its screens
together inside the interrupt, and while it does so the next interrupts find it busy
(0xF301) and the engine does not run; so each recorded frame is paired with the engine frame
that has the **same RAM** in the channels of the tune. The prize, the champion and the RACE
END tunes were recorded by calling the game's own `pieza` routine from the selection
(`tools/guiones/musicas.tcl`), because reaching them by playing takes nine races.

The sounds of the race are not here: the starting sound, the endless gallop, the jump, the
whip, the bump against a shrub, the fall and the coins of the payout.

## The engine

Three channels at 0xF002, 0xF022 and 0xF042, 32 bytes each, with pieces in **three-byte**
groups: a note (its number, the duration and how long to wait for the next one) or an order
from 0xF4 to 0xFF (end, repeat, jump, volume, envelope, tempo, transpose, noise; the table
0x8308). The notes come from twelve periods of the lowest octave (0x8330), halved for every
octave. Channel 0xF002 plays on the PSG's C, 0xF022 on B and 0xF042 on A.

| | Who asks for it | Length |
|---|---|---:|
| the first race | race 1, before choosing (0x8922) | 7.0 s |
| the fanfare | the start of every race (0x8AE1) | 3.3 s |
| the arrival | after the race, with PUSH TRIG 2 (0x8BDE) | 1.4 s |
| GAME OVER | the jockey last, or nobody with money (0x8C4D) | 1.2 s |
| the prize | the jockey first or second (0x8D0A) | 2.7 s |
| the champion | the jockey first in race 9 (0x8D23) | 2.1 s |
| RACE END | the nine races over (0x8A1D) | 3.0 s |

## The first race

<audio controls src="audio/musica_primera.mp3"></audio>

## The fanfare

<audio controls src="audio/musica_fanfarria.mp3"></audio>

## The arrival

<audio controls src="audio/musica_llegada.mp3"></audio>

## GAME OVER

<audio controls src="audio/musica_game_over.mp3"></audio>

## The prize

<audio controls src="audio/musica_premio.mp3"></audio>

## The champion

<audio controls src="audio/musica_campeon.mp3"></audio>

## RACE END

<audio controls src="audio/musica_fin.mp3"></audio>
