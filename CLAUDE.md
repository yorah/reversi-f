# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Reversi-F is an implementation of Reversi (Othello) for the **Fairchild Channel F / VES**, an early cartridge console powered by the **Fairchild F8** 8-bit processor. The whole game is written in F8 assembly and assembled with **dasm**. A deliberate design constraint: it runs with **no SCHACH RAM** — everything (game state *and* a software stack) lives in the F8's 64 8-bit scratchpad registers.

**Cartridge ROM is small and fixed** — always favor compact, byte-conscious code; new features compete for very limited space. This build targets `GAME_SIZE = 8` KB (`src/game.asm:34`), with the cartridge mapped at `$0800` and the size enforced by the padding/signature at the end of `game.asm`. When size matters, prefer the smaller encoding (e.g. `BR` over `JMP` where range allows — see the F8 gotchas below).

**Macros do NOT save ROM.** dasm `MAC`/`ENDM` macros expand inline at every invocation, so reusing a macro emits its code at each call site — it aids readability and single-sourcing but costs the same (or more) bytes as duplication. Only factoring shared code into a **called subroutine** (`pi`, returning via kstack/`pk`) actually reduces ROM, trading some call overhead for size. So "de-duplicate to save space" means *subroutine*, not *macro*; where the duplicated blocks differ only by a small action (e.g. the 8-direction scan), making it a real subroutine usually means driving that action from data (a table/loop) rather than per-call macro arguments.

**ROM ceiling.** Cartridge ROM starts at `$0800` (the 2 KB BIOS is `$0000–$07FF`). A plain, unbanked cartridge has a contiguous window up to `$2800` (where Schach/cartridge RAM is conventionally mapped) → **8 KB max** — which is exactly what this build targets (`GAME_SIZE = 8` fills `$0800–$27FF`). Going beyond 8 KB requires a 3853 SMI + bank switching (mapping into `$3800`/`$7800`/`$B800`/`$F800`), up to the F8's 16-bit / 64 KB address space. Sources: VES Wiki [Schach RAM](https://channelf.se/veswiki/index.php?title=Schach_RAM) and [SABA Videoplay 20 disassembly](https://channelf.se/veswiki/index.php?title=Disassembly:SABA_Videoplay_20).

## Build & Run

Requires [dasm](https://dasm-assembler.github.io/) (assembler) and [MAME](https://www.mamedev.org/) (emulator) on `PATH`. MAME needs the Channel F BIOS `channelf.zip` in `roms/` — it's found via `-rompath roms`, separate from the cartridge.

**Linux / WSL / macOS** — use the [mise](https://mise.jdx.dev/) tasks in `.mise.toml`:
```sh
mise run compile   # mkdir bin + dasm src/game.asm -f3 -obin/game.bin -lbin/game.lst
mise run run       # mame channelf -rompath roms -cart bin/game.bin -debug ...
mise run make      # compile then run
```

**Windows** — the original `.bat` files still work (`_make.bat` = compile + run). Keep `.mise.toml` and the `.bat` files in sync if you change the dasm/mame invocation.

There is no test suite — verification is done by running in the MAME emulator. `bin/`, `game.lst`, and `game.bin` are git-ignored build artifacts (dasm does not create `bin/`, so the compile step must `mkdir` it first).

## Architecture

`src/game.asm` is the single entry point — it `include`s everything else, so the include order there is the authoritative file manifest. The cartridge is ORG'd at `$0800`; flow is **cartridge init → title screen → new game → `game.loop` → game over → back to title**.

### Registers are the whole memory map
The most important thing to understand: there is no RAM, so **specific scratchpad register numbers are assigned fixed roles**, documented in the header block of `src/game.asm` (lines ~42–63). Several registers are bit-packed — e.g. `PLAYER_STATE` (r31) packs X/Y selection cursor, a debounce flag, and whose turn it is into one byte; `GAME_STATE` (r30) packs a blink counter and a 2-bit turn state. The 8x8 board lives in 16 bytes at `BOARD_STATE` (r32–r47, ISAR 40–47/50–57). Registers r53–r62 hold the software stack, r63 is its stack pointer. When touching state, consult this map first and respect the bit layouts — the macros in `src/macros/` (`gamestate.h`, `playerstate.h`, `gamemode.h`) are the accessors that read/write those packed fields and should be preferred over hand-rolled bit fiddling.

### Custom software stack (kstack)
`src/libs/kstack.inc` implements a register-based call stack (ported from the pacman homebrew, more efficient than the BIOS one). It pushes the `K` register down from r57 using r63 as the pointer, allowing ~6 levels of nested subroutine calls. It is initialized in `main` (pointer set to r62). **Caveat:** the BIOS `BIOS_CLEAR_SCREEN` uses its *own* push/pop scheme and requires r31 = 0, so calling it after kstack is in use is dangerous — see `RANDOM_THOUGHTS.md`.

### Code organization
- `src/ves.h` — standard VES/Channel F header: BIOS call addresses, colors, and core macros (`CARTRIDGE_START`, `CARTRIDGE_INIT`, `SETISAR`). Do not redistribute (per its header).
- `src/functions/` — top-level screens/systems: `board.asm`, `sidebar.asm`, `titlescreen.asm`, `newgame.asm`.
- `src/functions/game/` — gameplay logic: `newturn`, `gameover`, `handleInput`, `inputActions`, `blink`, `boardManipulation` (move legality + piece flipping, the largest/most complex file), `ai`.
- `src/macros/` — `.h` macro definitions (input, draw, sound, and the state accessors noted above).
- `src/libs/` — `kstack.inc` and `drawing.inc` (blitting subroutines like `blitGraphic`).
- `src/data/` — `graphics.inc` (sprite/tile data + palette), `jumptables.inc` (dispatch tables used via `JMP_TABLE`), `ai.inc`.

### Game modes
`GAME_MODE` (r27) encodes mode in its low bits (quickgame / best-of-3 / best-of-5) plus a bit for human-vs-human vs human-vs-computer. The AI always plays as Player 2.

## F8 / Channel F gotchas

**Never guess F8 instructions or their behavior.** The F8 is an obscure ISA with non-obvious semantics (see the gotchas below) — hallucinating an opcode or its side effects produces code that assembles but misbehaves subtly. Always confirm instruction existence, operands, timing, and flag effects against authoritative sources before writing or editing assembly:
- [VES Wiki](https://channelf.se/veswiki/index.php?title=Main_Page) — hardware, BIOS routines, memory map, disassembled games.
- The PDFs linked at the bottom of the wiki — **F8 Guide to Programming** and **F8 User's Guide** — are the primary reference for the instruction set.

If a task needs instruction details not already captured here or in `RANDOM_THOUGHTS.md`, fetch the relevant section from those sources and store the distilled facts as project documentation (extend `RANDOM_THOUGHTS.md` or add a focused doc) rather than relying on memory.

`RANDOM_THOUGHTS.md` is a real source of hard-won knowledge — read it before debugging low-level issues. Highlights:
- **`JMP` clobbers the accumulator**; `BR` does not. `BR` is relative (−127…+128) and can silently go out of range when code is added between branch and target — prefer `JMP` (via a nearby trampoline label) when the target may be far. The code uses indirection labels (e.g. `.loop.draw`) precisely for this reason.
- **No OR-from-scratchpad instruction** exists — only OR-immediate and OR-from-memory. `XS` (XOR-from-scratchpad) substitutes when the target bits are known to be 0.
- **BCD arithmetic (`ASD`) leaves the sign status unreliable** — score comparisons in `gameover.asm` compare high nibble then low nibble instead of trusting sign.
