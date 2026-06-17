# Roadmap

Improvement backlog for reversi-f, sorted by tier. Derived from a codebase audit.
Correctness items are framed as **verify against the F8 guide** — the game ships and
works, so these are confirmations to make (and document), not known breakage. Per the
project rule, never assert F8 opcode semantics from memory; consult the
[VES Wiki](https://channelf.se/veswiki/index.php?title=Main_Page) and the F8 PDFs.

## Tier 1 — Foundations & correctness

- **F8 cheat-sheet doc.** Commit `docs/f8-notes.md` distilling the F8 opcode gotchas
  (JMP clobbers A, BR range, no OR-from-scratchpad, BCD sign unreliable, `ds`/`as`/`inc`
  flag behavior). CLAUDE.md already prescribes capturing distilled F8 facts as docs.
- **Board-encoding diagram + verify the seed/clear loop.** Document the
  coordinate ↔ (register, bit) mapping near `newgame.asm` and verify the board-clear
  loop (`newgame.asm:32-57`) correctly walks the 16 registers across the **octal ISAR
  47→50 gap**. Highest-risk-to-edit code; least-documented bit-packing.
- **Verify & document F8 semantics flagged by the audit.** Confirm and record:
  - `inputActions.asm:17-28` — move handlers appear to fall through; confirm
    `UPDATE_*_POSITION` macros terminate control flow.
  - `handleInput.asm:124-126` — return value depends on `MAP_ACTION_RETURN` writing into r0.
  - `drawing.inc:86,228` — plot/blit return via `pop` while kstack is active (BIOS-vs-kstack hazard).
  - `drawing.inc:105-109` — `blitGraphic` `br7` loop loads exactly r1–r6.
  - `boardManipulation.asm:40-42,145-150` — `ni %11111111`-as-no-op-to-set-Z assumes
    intervening `lr` ops don't disturb Z.
  - `ds`/`as`/`inc` carry/zero semantics underpinning fill/draw loops (note `clearscreen`
    uses `bc` where `sidebar.draw` uses `ci/bnz` for the same operation).

## Tier 2 — Refactors (maintainability)

- **De-duplicate the 8-direction scan (#1 refactor).** The unrolled 8-way board scan is
  copy-pasted 4× — `ai.asm:56-113`, `newturn.asm:92-149`, `inputActions.asm:106-155`, and
  the engine in `boardManipulation.asm` — differing only by the per-direction action.
  Collapse into one macro parameterized by that action (~150 lines removed).
- **Single-source the bit masks.** `PLAYER_STATE`/`GAME_STATE`/`GAME_MODE` masks
  (`%11100000`, `%00011100`, …) are duplicated across `gamestate.h`, `gamemode.h`,
  `playerstate.h`, and re-derived inline in `draw.h`'s `DRAW_SELECTION`. Define
  `PLAYER_STATE_X_MASK` etc. once (extend the enum-naming pattern already in `gamemode.h`).
- **De-duplicate the title-screen menu state machine.** `titlescreen.asm` has two
  near-identical selection loops (gamemode `28-99` vs opponent `118-173`). Extract a
  generic menu helper parameterized by item count + draw routine.
- **BCD score helper.** The `$66` + `asd` score adjustment is repeated in
  `boardManipulation.asm` (4 sites) and `gameover.asm` (2 sites). Extract one helper.
- **Parameterize Bo-checks + unify the fill loop.** Collapse the three near-identical
  Bo1/Bo3/Bo5 blocks (`gameover.asm:86-135`) into one threshold-parameterized routine; and
  unify the screen-fill loop duplicated in `clearscreen` (drawing.inc) and `sidebar.draw`
  (they currently use different termination idioms).
- **Sound BEEP helper + turn-graphic dedup.** Add a `BEEP duration, tone` macro to
  collapse the repeated `sound.h` envelope (esp. `WINNING_SOUND`); and replace the
  duplicated player-turn → p1/p2 graphic selection in `newgame.asm:81-90` with a call to
  `updateTurnInSidebar`.

## Tier 3 — Hygiene & polish

- **Name the recurring magic numbers.** Button/direction masks (`%10001100`, `%00001100`,
  `%00000100`), the screen-write ARM handshake (`$60`/`$c0`), the three sound tone patterns,
  and bare pixel coordinates throughout `board.asm`/`sidebar.asm`/`titlescreen.asm`.
  Constants exist for board geometry but are used inconsistently (e.g. `li 28` vs `BOARD_MIDDLE_X`).
- **Fix stale/misleading comments** (the only spec in assembly):
  - `newturn.asm:158` says "r10" but stores to r0.
  - `inputActions.asm:81` says "r16" but uses r10.
  - `titlescreen.asm:115` "quick game mode is default" copied into the opponent block.
  - `game.asm:96-98` says the title screen "could have options" — now obsolete.
  - `handleInput.asm:44` / `input.h:8` carry "?" uncertainty markers — resolve.
  - `RANDOM_THOUGHTS.md:58` & `:73` share the heading "BIOS_CLEAR_SCREEN and kstack" but
    the second is actually about BCD sign.
- **`.gitignore` additions.** Editor/OS noise (`.vscode/`, `.idea/`, `.DS_Store`, `*.swp`)
  and likely MAME dirs (`nvram/`, `snap/`, `sta/`, `diff/`).

## Tier 4 — Functional enhancements

- **Stronger AI.** Currently greedy 1-ply (max immediate flips + static positional weights),
  which is weak in Reversi. Add mobility/frontier weighting or shallow look-ahead within F8
  constraints. Also verify `ai.asm:140-147`: the `bp`/`bz` score compare assumes a move's
  score can't reach ≥128 and flip the sign bit.
- **Better RNG seeding.** Entropy comes solely from idle time at the title
  (`titlescreen.asm:62-63`), so a fast/deterministic player gets a near-constant seed.
  Mix in input timing or a frame counter.
- **Menu back-navigation.** Allow returning to mode select from the opponent screen
  (currently one-way).
- **Match-draw handling + audio polish.** A per-game draw advances neither player's
  `GAME_SCORE` (`gameover.asm:53`); verify a Bo-N can't deadlock on repeated draws and
  define the even-match outcome. Add title music / a game-over jingle (sound is currently
  just move/place/win blips).
