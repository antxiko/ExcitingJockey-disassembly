# The texts

Every text in the ROM is in English, except the title, which is kanji in big letters. The
letters are tiles of the game in ASCII order (0x30-0x5F); on the track, the space is a grass
tile (0xE2-0xE4).

| Where | Text | Meaning |
|---|---|---|
| the selection (0x851A) | PLAYER SELECT | |
| | A PLAY-JOCKEY MODE | ride a horse |
| | B 1PLAYER BET MODE | one player bets |
| | C 2PLAYERS BET MODE | two players bet |
| | D 3PLAYERS BET MODE | three players bet |
| | E 4PLAYERS BET MODE | four players bet |
| | PUSH TRIGGER 1 TO START GAME | |
| | COPYRIGHT 1984 @ CASIO | the @ is drawn as © and ^ as a dash |
| the box (0x8794) | DEMONSTRATION | the demonstration, blinking |
| the box (0x87E1) | 1ST BONUS 1000 / 2ND BONUS 500 | the jockey's prizes; the figures change with the race |
| the track (0x888E) | HORSE SELECT JOY / START PUSH TRIG 2 | the joystick picks the horse, button 2 starts |
| the track (0x8AD9) | BET MODE | the bets |
| the track (0x88A4) | PUSH TRIG 2 | press button 2 for the next race |
| the track (0x8C44) | GAME OVER | |
| the track (0x8CAE) | RACE END | the nine races are over |

The other words are drawn in tiles of their own (0xB835) and are already in the screens:
ODDS and the six pairs, 1UP to 4UP, MIN and MAX on the strength bar, RACE, GRASS and DIRT
and the distances in the oval, the distance signs of the track, GOAL down the finish post and a
CASIO sign among the shrubs.

The title in the selection, CASIO and 大障害競馬 (*dai shōgai keiba*, "the great
steeplechase"), is 14 x 6 tiles (0xBD35).
