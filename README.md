# Exciting Jockey - commented disassembly

*(También [en castellano](README.es.md).)*

The commented disassembly of **Exciting Jockey** (大障害競馬, Casio, 1984) for the MSX: a 16 KB cartridge at 0x8000.

- **100%** of the binary explained: 9,039 bytes of code and 7,345 of named data, not one byte unassigned.
- **42.4%** of the listing commented, 505 routines and labels, none below 10% of comments.
- The listing reassembles into the original ROM **byte for byte**.
- The selection comes from running the ROM, checked against openMSX; the start, the jump, the fall, the shrub, the finish, the bets and the payout, played in GIF; the seven tunes, from its own sound engine and identical to openMSX frame by frame.

The site: <https://antxiko.github.io/ExcitingJockey-disassembly/>
(in Spanish: <https://antxiko.github.io/ExcitingJockey-disassembly/es/>).

## Rebuilding it

The ROM image is not distributed. Put yours in the root as `excitingjockey.rom` (sha256 `2bd3078a...`) and run `make`. The details, in [UNDER THE HOOD](docs/UNDER-THE-HOOD.md).

## Legal

The game belongs to Casio and its rights holders. The `LICENSE` covers only the tools, comments, analysis and documentation here. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
