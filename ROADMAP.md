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

## Tier 2 — Refactors (maintainability; ROM only via subroutines)

> **Note:** dasm macros expand inline at every call site, so converting duplication into a
> *macro* improves single-sourcing but does **not** shrink ROM. Only a called **subroutine**
> (`pi` + kstack return) reclaims space. Items below are split accordingly.

- **De-duplicate the 8-direction scan (#1 refactor).** The unrolled 8-way board scan is
  copy-pasted 4× — `ai.asm:56-113`, `newturn.asm:92-149`, `inputActions.asm:106-155`, and
  the engine in `boardManipulation.asm` — differing only by the per-direction action.
  A shared *macro* would single-source it but save no ROM (still emitted 4×). To actually
  reclaim space, make it one **subroutine** that loops over a direction-offset table, with
  the per-direction action selected by a parameter (register/flag) — this also subsumes the
  "snail pattern" idea noted in `game.asm`. Biggest ROM win available.
- **Single-source the bit masks.** `PLAYER_STATE`/`GAME_STATE`/`GAME_MODE` masks
  (`%11100000`, `%00011100`, …) are duplicated across `gamestate.h`, `gamemode.h`,
  `playerstate.h`, and re-derived inline in `draw.h`'s `DRAW_SELECTION`. Define
  `PLAYER_STATE_X_MASK` etc. once (extend the enum-naming pattern already in `gamemode.h`).
  *(Equates, not code — no ROM impact; pure maintainability.)*
- **De-duplicate the title-screen menu state machine.** `titlescreen.asm` has two
  near-identical selection loops (gamemode `28-99` vs opponent `118-173`). Extract a
  generic menu **subroutine** parameterized by item count + draw routine — saves ROM, not
  just source. (A macro here would not.)
- **BCD score helper (subroutine).** The `$66` + `asd` score adjustment is repeated in
  `boardManipulation.asm` (4 sites) and `gameover.asm` (2 sites). Factor into one called
  subroutine to actually reclaim bytes.
- **Parameterize Bo-checks + unify the fill loop (subroutines).** Collapse the three
  near-identical Bo1/Bo3/Bo5 blocks (`gameover.asm:86-135`) into one threshold-parameterized
  routine; unify the screen-fill loop duplicated in `clearscreen` (drawing.inc) and
  `sidebar.draw` (currently different termination idioms). Both save ROM only as subroutines.
- **Sound envelope helper + turn-graphic dedup.** The repeated `sound.h` envelope (esp.
  `WINNING_SOUND`) is a candidate for a called subroutine taking tone/duration — a `BEEP`
  *macro* would tidy source but save no ROM, so prefer a subroutine if size is the goal.
  Separately, replace the duplicated player-turn → p1/p2 graphic selection in
  `newgame.asm:81-90` with a call to `updateTurnInSidebar` (a clear ROM + clarity win).

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
