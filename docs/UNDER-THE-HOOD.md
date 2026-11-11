# Under the hood

## Rebuilding the ROM

`make verify` assembles `src/excitingjockey.asm` with pasmo and the 16 KB ROM comes out
**byte for byte**. `make sanity` checks what reassembling does not cover: that no byte
declared as data is read as code, that no entry point falls in data and that all 16,384
bytes are explained. `make test` runs the tests. The ROM is not in the repository: it has to
be placed in the root as `excitingjockey.rom` (the GoodMSX dump, `[!]`, sha1 `5b17cb69...`).

| | bytes |
|---|---|
| traced code | 9,039 |
| named data | 7,345 |
| unexplained | 0 |

The listing has 1,918 comments on 4,521 instructions (42.4%), 505 routines and labels, none
below 10% commented, and no called routine without a name.

## The cartridge

16 KB in **page 2** (0x8000-0xBFFF), with INIT at 0x8010 and the rest of the header at zero.
A little over half is code; the rest is the drawings (2 KB of sprites and 2 KB of tiles with
their colours), the title, the tables of the track and of the obstacles, and the music.

## The BIOS it uses

WRTVDP for the eight registers of SCREEN 2 (it does not use INIGRP), DISSCR and ENASCR to
turn the screen off and on, FILVRM, LDIRVM, WRTVRM and RDVRM for the VRAM (RDVRM to read the
tile under each horse), GTSTCK, GTTRIG and SNSMAT for the joysticks and the keyboard, and
WRTPSG and RDPSG for the sound.

## The interrupt and the state machine

The game puts a `jp` to 0x805B in the H.TIMI hook (0xFD9F) and does not change it again. Each
frame, if the previous one is over: the sprites, the state machine (0x83E2), the race and the
sound. The state is two bytes, 0xE05E and its step 0xE05F:

| state | what | steps |
|---:|---|---|
| 1 | loading the drawings | 1 |
| 2 | the selection | 3: the screen, the wait, the choice |
| 3 | the jockey | 5: the new race, HORSE SELECT, RACE END, its wait, the start |
| 4 | the bets and the race | 9: the start, the bets, the fanfare, the wait, the race, the end, the next one, RACE END, the payout |
| 5 | the demonstration | 3 |

Almost every choice goes through `salta_tabla` (0x8083): the `call` is followed by a table of
addresses and A says which one to jump to. There are fifteen of these tables (the states, the
steps, the obstacles, the states of the horses and of the jockeys). The tracer cannot follow
them on its own: they are declared in `src/excitingjockey.nocode` and their targets in
`src/excitingjockey.entries`.

## The horses

Each horse is a block of 32 bytes (0xE07F, 0xE09F, 0xE0BF, 0xE0DF) and three sprites, with a
state of its own: 1 the start, 2 running, 3 stumbling, 4 jumping, 5 falling, 6 on the ground,
7 after the finish (0x974E). Each jockey is a block of 8 bytes (0xE0FF) and one sprite: 1
mounting, 2 riding, 3 thrown, 4 winning (0x9D37). The four groups of three sprites of the
horses change order every frame (`sprites_gira`, 0x83B3), so that when more than four sprites
meet on a line they take turns to blink instead of one of them disappearing.

## How it was done

The trace follows the code from INIT, the interrupt and the fifteen jump tables. The rest has
been **measured in openMSX** (`tools/omsx_cobertura.tcl`: a condition on every instruction
logs every new ROM address), playing and waiting for the demonstration, on a Philips VG 8020
and on C-BIOS.

## The RAM

| | |
|---|---|
| 0xE000 / 0xE001 / 0xE002 | the race, the mode, the player's horse |
| 0xE003-0xE00C | the joystick and the two buttons, the new presses and the repeat |
| 0xE011 | the six odds |
| 0xE017 | the bets: six per player |
| 0xE02F | the money of each player (4 bytes) |
| 0xE03F | the strength of each horse and its pace (4 bytes) |
| 0xE05E / 0xE05F | the state and its step |
| 0xE06C-0xE073 | the track: its state, its speed, what is left of the race |
| 0xE07F | the four horses (32 bytes) |
| 0xE0FF | the four jockeys (8 bytes) |
| 0xE180 | the sprite table, sent to 0x1B00 every frame |
| 0xED00 | the track, 16 rows of 32 |
| 0xF002-0xF05F | the sound engine |
| 0xF080 | the race accounts of each horse (8 bytes) |
| 0xF0B0-0xF0EA | the odds, the bets, the payout and the whip |
| 0xF300 | the interrupt: working and busy |
