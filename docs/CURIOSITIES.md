# Curiosities

## Data hidden among the sprites

When it starts, the game sends 2 KB from 0xAC1B to the sprite drawings (0x3800): 64 drawings
of 16 x 16. But it does not use them all, and in the holes there is **other data**:

| sprites | address | what it really is |
|---|---|---|
| 4-9 | 0xAC9B | the top six rows of the race screen (ODDS, the box, the oval) |
| 10-11 | 0xAD5B | the bottom two rows (1UP-4UP, the money, MIN-MAX) |
| 12 | 0xAD9B | the tune of the first race, channel 0 |
| 62-63 | 0xB3DB | the table of the ten drawings of the horse |

No sprite of the game uses drawings 4 to 12 (0x10-0x30): the horses, the jockeys, the
cursors and the bar all have their numbers in their tables. Those rows of the screen and that
tune are in the VRAM as sprites the whole time, and nobody shows them.

## A game that runs in the interrupt

INIT sets up the H.TIMI hook and then the main loop only calls one routine, the **payout**
(`pago`, 0xA2F5), which does nothing until a race ends. Everything else runs in the
interrupt (0x805B): the sprites, the state machine, the track, the horses, the joysticks and
the sound. When a frame does not finish in time (putting a screen together takes several),
the next interrupts find it busy (0xF301) and only count (0xF302).

## Odds converted twice

The six odds are turned into decimal for the screen (`cuotas`, 0xA1B9), and the conversion is
done **twice**: the first pass gives the decimal figure and the second takes it as a binary
number and converts it again. An odds of 9 stays 9, but 12 comes out as 18 and 18 as 24. The
payout pays what the screen shows. And the loop does not stop after six bytes: its counter
comes out at zero from the loop before, so it goes round **256 times**, from 0xF0B7 to 0xF1B6;
what it changes after the odds is either set again afterwards or not used.

## The endless gallop

The gallop of the race is a piece of three beats of noise and an order 0xFD, "back to the
mark", without a mark: it goes back to the start and never ends (0xBE7F). It only stops when
the game silences the sound at the end of the race.

## Code and bytes nobody uses

- At 0xA150 there is an eleven-byte routine, HL = 0xF080 + B x 8, that nobody calls (with
  `call`, `jp` or a table) and that does not run in the openMSX measurements.
- At 0x9EE6 there is a `ret` that is never reached: the instruction before it jumps away.
- Four bytes at 0xA6D7 (00 02 00 06) and four at 0x88F8 (50 C0 00 08) sit next to tables
  that are read: no instruction points at them, and those tables end before.

## The demonstration

The demonstration is always race 9, dirt and 3600 metres, the longest, with no bets; button 1
ends it and goes back to the selection.
