# F8 Notes — practical reference for reversi-f

A distilled, *verified* cheat-sheet for the Fairchild F8 (F3850 CPU) as used in this
codebase. Mnemonics are written lowercase to match the `dasm` style used in `src/`.

> **Golden rule (from `CLAUDE.md`): never guess F8 instruction behavior.** Every
> claim below is grounded in an authoritative source (see [Sources](#sources)).
> Items that could not be confirmed against a source are tagged
> `[UNVERIFIED — confirm against F8 Guide to Programming]`. Prefer omitting a claim
> to guessing.

Status flags used throughout: **O** = Overflow, **Z** = Zero, **C** = Carry,
**S** = Sign. The status register (W) bit layout is **bit7=Sign, bit6=Carry,
bit5=Zero, bit4=Overflow, bit0=ICB (interrupt master enable)**
([F3850 datasheet](https://archive.org/stream/bitsavers_fairchildfralProcessingUnitdatasheet1982_5876308/Fairchild_-_F3850_Central_Processing_Unit_datasheet_-_1982_djvu.txt)).

---

## Gotchas

These are the hard-won ones. Read this section before debugging low-level issues.

- **`jmp` clobbers the accumulator.** `jmp` is a 3-byte absolute jump
  (`PC0 ← mmmm`); to build the new PC it loads the high address byte *into A*, so
  **A is destroyed** by every `jmp`. `br` does not touch A.
  Source: [VES Wiki Opcode](https://channelf.se/veswiki/index.php?title=Opcode),
  [F3850 datasheet](https://archive.org/stream/bitsavers_fairchildfralProcessingUnitdatasheet1982_5876308/Fairchild_-_F3850_Central_Processing_Unit_datasheet_-_1982_djvu.txt).

- **`pi` also clobbers the accumulator.** The call instruction `pi` (push/call)
  loads the target high byte through A the same way `jmp` does, so **A is destroyed
  across a `pi` call** independent of what the callee does. Save A first if you need
  it after the call.
  Source: [VES Wiki Opcode](https://channelf.se/veswiki/index.php?title=Opcode),
  [F3850 datasheet](https://archive.org/stream/bitsavers_fairchildfralProcessingUnitdatasheet1982_5876308/Fairchild_-_F3850_Central_Processing_Unit_datasheet_-_1982_djvu.txt).

- **`br` is relative, range −128…+127; `jmp` is absolute.** `br` is 2 bytes and
  encodes a signed 8-bit offset added to PC, so the target must be within roughly
  −128…+127 bytes. Adding code between a `br` and its target can silently push the
  target out of range. `jmp` is 3 bytes, reaches anywhere, but clobbers A (above).
  Practice in this repo: use a nearby trampoline label (e.g. `.loop.draw`) and
  `jmp` to it when the real target may be far.
  Source: [VES Wiki Opcode](https://channelf.se/veswiki/index.php?title=Opcode),
  `RANDOM_THOUGHTS.md`.

- **`jmp` is faster than `br`, but bigger.** `jmp` ≈ 5.5 cycles / 3 bytes vs
  `br` ≈ 3.5 cycles / 2 bytes. So `br` saves a byte (matters for the 8 KB ROM cap),
  `jmp` saves time and range. Pick `br` for size, `jmp` for reach.
  Source: [VES Wiki Opcode](https://channelf.se/veswiki/index.php?title=Opcode).

- **No OR-from-scratchpad instruction exists.** You only get `oi`
  (OR-immediate) and `om` (OR-with-memory via DC). There is **no** OR-from-register.
  `xs` (XOR-from-scratchpad) substitutes *only when the target bits are known to be
  0 in A* (then XOR == OR). A general OR-from-scratchpad must be emulated.
  Source: [VES Wiki Opcode](https://channelf.se/veswiki/index.php?title=Opcode),
  `RANDOM_THOUGHTS.md`.

- **BCD arithmetic (`asd`) leaves the sign status unreliable.** `asd` does a
  decimal (BCD) add; the documented status flags are computed from the *binary*
  intermediate result, so S (and O) do not meaningfully reflect the BCD value.
  This repo's `gameover.asm` compares scores by high nibble then low nibble instead
  of trusting sign. `[UNVERIFIED — the exact reason S/O are meaningless for BCD is
  not spelled out in the sources consulted; confirm against F8 Guide to Programming.
  The empirical fact (sign unreliable after asd) is from RANDOM_THOUGHTS.md.]`
  Source: `RANDOM_THOUGHTS.md`;
  [VES Wiki Opcode](https://channelf.se/veswiki/index.php?title=Opcode).

- **`BIOS_CLEAR_SCREEN` ($00d0) fights the kstack.** The BIOS clear-screen
  (1) requires r31 = 0 to work correctly, and (2) uses the BIOS's *own* push/pop
  scheme (`BIOS_PUSH_K` $0107 / `BIOS_POP_K` $011e, manipulating their own pointer
  register), which is a different structure than this repo's `kstack` (which pushes
  K down from r57 using r63 as pointer). Calling `BIOS_CLEAR_SCREEN` once the
  kstack is in use is dangerous — avoid it or do it very carefully.
  Source: `RANDOM_THOUGHTS.md`, `CLAUDE.md`, `src/ves.h`.

- **`br7` continues a loop until ISAR's low octal digit hits 7.** `br7` branches
  (taken) when the **low 3 bits of ISAR are NOT equal to 7**; once they reach 7 the
  branch falls through. It is the idiomatic "scan an 8-byte buffer" loop terminator
  used with auto-increment (`I`) addressing. No flags affected.
  Source: [VES Wiki Opcode](https://channelf.se/veswiki/index.php?title=Opcode),
  [tech-in-japan F8 article](https://tech-in-japan.github.io/articles/467811/index.html).

- **ISAR auto-increment/decrement only touches the low octal digit (wraps within
  the 8-byte window).** Incrementing ISAR goes `…46→47→40` (octal), *not* `47→50`.
  So you cannot walk across the `47→50` boundary by simple increment — that is the
  "gap". The 16 board bytes (r32–r47, octal 40–47 / 50–57) therefore span **two**
  windows and need an explicit ISAR reload at the boundary.
  Source: [VES Wiki Register](https://channelf.se/veswiki/index.php?title=Register),
  [tech-in-japan F8 article](https://tech-in-japan.github.io/articles/467811/index.html),
  F3850 datasheet (see Sources).

---

## Instruction reference (opcodes used in this repo)

Flags column lists flags *modified*. "—" means no status flags affected. Byte
sizes and side-effects verified against the
[VES Wiki Opcode table](https://channelf.se/veswiki/index.php?title=Opcode) unless
noted. Logical-op flag detail (O/C cleared) is corroborated by the
[F3850 datasheet](https://archive.org/stream/bitsavers_fairchildfralProcessingUnitdatasheet1982_5876308/Fairchild_-_F3850_Central_Processing_Unit_datasheet_-_1982_djvu.txt).

| Mnemonic | Bytes | Meaning | Flags | Notes / side-effects |
|----------|-------|---------|-------|----------------------|
| `lr` (A↔reg / A↔K,Q,IS,DC,H…) | 1 | Load/move between registers | — | Pure move. `lr k,p` saves return addr for nesting. Does **not** affect A's value except when A is the destination. |
| `lis n` | 1 | Load short immediate (0–15) into A | — | Smallest way to load a small constant. |
| `li n` | 2 | Load 8-bit immediate into A | — | |
| `lisu i` / `lisl i` | 1 / 1 | Set upper / lower octal digit of ISAR | — | Pair of these = `SETISAR` macro (`src/ves.h`). |
| `clr` | 1 | A ← 0 | — | `[UNVERIFIED — whether clr touches flags; opcode table lists no flags. Treat as none.]` |
| `ni n` | 2 | A ← A AND n | Z, S (O, C cleared) | |
| `oi n` | 2 | A ← A OR n | Z, S (O, C cleared) | |
| `xi n` | 2 | A ← A XOR n | Z, S (O, C cleared) | |
| `ci n` | 2 | Compare immediate (A − n) | O, Z, C, S | **A unchanged**; flags only. Computed as `n + (~A) + 1`. |
| `ai n` | 2 | A ← A + n (binary) | O, Z, C, S | |
| `as r` | 1 | A ← A + (r) (binary) | O, Z, C, S | Add-from-scratchpad. |
| `asd r` | 1 | A ← A + (r) (decimal/BCD) | O, Z, C, S | **Sign/Overflow unreliable for BCD** — see Gotchas. |
| `ns r` | 1 | A ← A AND (r) | Z, S (O, C cleared) | AND-from-scratchpad. |
| `xs r` | 1 | A ← A XOR (r) | Z, S (O, C cleared) | XOR-from-scratchpad; OR-substitute (see Gotchas). |
| `ds r` | 1 | (r) ← (r) − 1 (i.e. + $FF) | O, Z, C, S | Decrement happens **in the scratchpad register**, not A. Sets Z when result 0; loop-counter friendly. |
| `inc` | 1 | A ← A + 1 | O, Z, C, S | |
| `com` | 1 | A ← A XOR $FF (ones-complement) | Z, S (O, C cleared) | `[UNVERIFIED — O/C exact effect; opcode table lists Z,C,S. Confirm.]` |
| `sl 1` / `sl 4` | 1 | Shift A left 1 / 4 bits | Z, C, S | Zeros shifted in. |
| `sr 1` / `sr 4` | 1 | Shift A right 1 / 4 bits | Z, C, S | Logical shift, zeros in. |
| `lm` | 1 | A ← (DC); DC ← DC + 1 | — | Load from memory via Data Counter, auto-increments DC. |
| `am` | 1 | A ← A + (DC) (binary); DC++ | O, Z, C, S | Add-from-memory via DC. |
| `dci nnnn` | 3 | DC ← nnnn (16-bit) | — | Set Data Counter for `lm`/`am`/`st`. |
| `adc` | 1 | DC ← DC + A | — | Add A to Data Counter (table/sprite stepping). `[UNVERIFIED — whether adc affects flags; opcode table lists none. Treat as none.]` |
| `br n` | 2 | Unconditional relative branch | — | Range −128…+127. Does **not** clobber A. |
| `br7 n` | 2 | Branch if low-3-bits(ISAR) ≠ 7 | — | Loop terminator over an 8-byte window. |
| `bz n` / `bnz n` | 2 | Branch if Zero / if not Zero | — | `bz`=`bt 4`, `bnz`=`bf 4`. |
| `bc n` / `bnc n` | 2 | Branch if Carry / if no Carry | — | |
| `bp n` | 2 | Branch if Positive (Sign set) | — | `[UNVERIFIED — exact Sign polarity (bp = sign bit set vs clear); confirm against F8 Guide to Programming.]` |
| `bm n` | 2 | Branch if Minus | — | `[UNVERIFIED — sign polarity; confirm against F8 Guide to Programming.]` |
| `bt t,n` / `bf i,n` | 2 | Branch true / false on status mask | — | Generic conditional branch; `bz`/`bnz`/etc. are encodings of these. |
| `jmp nnnn` | 3 | Absolute jump (PC0 ← nnnn) | — | **Clobbers A** (see Gotchas). |
| `pi nnnn` | 3 | Call subroutine (save ret in PC1, jump) | — | **Clobbers A**. Pairs with `pop`/`pk` (see below). |
| `pk` | 1 | PC0 ← K (return via K register) | — | Used by the kstack return path. |
| `pop` | 1 | PC0 ← PC1 (return one level) | — | Single-level return (no K save needed). |
| `ins i` | 1 | A ← input port i (i ≤ 15) | O, Z, C, S | Reads I/O port. Used for controller input. |
| `outs i` | 1 | Output port i ← A (i ≤ 15) | — | Used in `CARTRIDGE_INIT` (ports 0,1,4,5). |
| `in n` / `out n` | 2 | Input / output port n (8-bit port #) | `in`: O,Z,C,S; `out`: — | For ports > 15. |

Notes:
- `pi`/`pk`/`pop` are the call/return primitives. With no hardware stack, only **one**
  return address lives in PC1, so deep nesting needs K saved off (`lr k,p`) — which is
  exactly what this repo's `kstack` (and the BIOS pushk/popk) automate.
- The flag effect "(O, C cleared)" on logical ops is from the F3850 datasheet; the
  VES Wiki opcode table summarizes some of these as "Z, S" only. They agree that O is
  not meaningfully set by logical ops.

---

## Sizes & addressing

- **ROM window: $0800–$27FF = 8 KB.** BIOS occupies $0000–$07FF. A plain unbanked
  cartridge is contiguous from $0800 up to $2800 (where Schach/cartridge RAM is
  conventionally mapped). This build targets `GAME_SIZE = 8` KB and fills
  $0800–$27FF. Beyond 8 KB needs a 3853 SMI + bank switching.
  Source: `CLAUDE.md`,
  [VES Wiki Schach RAM](https://channelf.se/veswiki/index.php?title=Schach_RAM).
- **No system RAM in this build** — all state lives in the 64 scratchpad registers
  (see the register map in `src/game.asm`). The software call stack (`kstack`) also
  lives there (r53–r62, r63 = pointer).
- **Scratchpad addressing.** Registers 0–11 are addressable directly by number.
  Registers 12/13/14 are the special ISAR ports: `S` (12) = use ISAR as-is, `I` (13)
  = use ISAR then **auto-increment**, `D` (14) = use ISAR then **auto-decrement**.
  Registers 16–63 are reachable only via ISAR.
  Source: [VES Wiki Register](https://channelf.se/veswiki/index.php?title=Register).
- **ISAR is octal: upper 3 bits = which 8-byte window, lower 3 bits = index 0–7.**
  Windows: 16–23, 24–31, 32–39, 40–47, 48–55, 56–63 (decimal). Auto inc/dec only
  changes the low octal digit and **wraps within the window** (`47→40` octal, never
  `47→50`). Crossing a window boundary requires reloading ISAR (`lisu`/`lisl` or the
  `SETISAR` macro). `br7` is the natural way to detect "end of window" (low digit = 7).
  Source: [VES Wiki Register](https://channelf.se/veswiki/index.php?title=Register),
  [tech-in-japan F8 article](https://tech-in-japan.github.io/articles/467811/index.html).
- **DC / DC1 (Data Counter) and Q.** `dci` loads the 16-bit DC; `lm`/`am`/`st` use
  and auto-increment it for memory (ROM table / sprite) access; `adc` adds A to DC.
  `Q` is a 16-bit register that can hold an address (`lr p0,q` jumps to it). K is the
  16-bit return-address save register used for subroutine nesting.
  Source: [VES Wiki Opcode](https://channelf.se/veswiki/index.php?title=Opcode),
  [VES Wiki Subroutines](https://channelf.se/veswiki/index.php?title=Subroutines).
- **`dasm` macros do not save ROM** — they expand inline at each call site. Only a
  real subroutine (`pi` … `pk`/`pop`) reduces bytes. Source: `CLAUDE.md`.

---

## Sources

Consulted and used (all verified against these):

- VES Wiki — Opcode table (primary instruction reference):
  <https://channelf.se/veswiki/index.php?title=Opcode>
- VES Wiki — Register (scratchpad / ISAR / DC / Q):
  <https://channelf.se/veswiki/index.php?title=Register>
- VES Wiki — Subroutines (PI/POP/PK, K register, kstack):
  <https://channelf.se/veswiki/index.php?title=Subroutines>
- VES Wiki — F8 (hardware overview, PDF links):
  <https://channelf.se/veswiki/index.php?title=F8>
- VES Wiki — Schach RAM (memory map / ROM ceiling):
  <https://channelf.se/veswiki/index.php?title=Schach_RAM>
- Fairchild F3850 CPU datasheet (1982), OCR text (flag effects, status bits):
  <https://archive.org/stream/bitsavers_fairchildfralProcessingUnitdatasheet1982_5876308/Fairchild_-_F3850_Central_Processing_Unit_datasheet_-_1982_djvu.txt>
- "Architecture and programming Fairchild Channel F" (br7 loop semantics, ISAR windows):
  <https://tech-in-japan.github.io/articles/467811/index.html>
- In-repo prior knowledge: `RANDOM_THOUGHTS.md`, `CLAUDE.md`, `src/ves.h`, `src/game.asm`.

Authoritative PDFs (could **not** be machine-read — scanned/JBIG2, no OCR layer);
use them to clear the `[UNVERIFIED]` items by hand:

- **F8 User's Guide (1976, Fairchild)** — linked from the VES Wiki F8 page:
  <https://channelf.se/veswiki/images/1/1d/F8_User%27s_Guide_%281976%29%28Fairchild%29%28Document_67095665%29.pdf>
- **F8 Guide to Programming (1977, Fairchild)** — bitsavers:
  <http://www.bitsavers.org/components/fairchild/f8/F8_Guide_To_Programming_1977.pdf>

### Open `[UNVERIFIED]` items to confirm against the F8 Guide to Programming

1. The precise reason BCD `asd` makes Sign/Overflow meaningless (empirical fact is
   solid; the mechanism is not sourced here).
2. Exact flag effects of `clr` (assumed none), `com` (Z/C/S per opcode table — O
   effect unclear), and `adc` (assumed none).
3. Sign-branch polarity for `bp` (branch if positive) and `bm` (branch if minus) —
   i.e. which Sign-bit value each tests.
