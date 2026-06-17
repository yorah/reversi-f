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

> **The Sign bit is *complementary* (inverted vs. the result's MSB).** S is **set
> (1) when the result's high-order bit is 0** (i.e. the result is positive/zero in
> two's complement) and **reset (0) when the high-order bit is 1** (negative). The
> F8 Guide repeats this in every arithmetic example, e.g. "The high order bit of
> the result is 1, so SIGN = 0" / "…is 0, so SIGN = 1" (§6.3, §6.5, §6.8). MAME
> encodes it as `SET_SZ(n)`: `if (~n & 0x80) m_w |= S;` with the source comment
> "note: the S flag is complementary". Consequently `bp` (branch if positive)
> tests **S = 1**, and `bm` (branch if minus) tests **S = 0** — see the `bp`/`bm`
> rows below.
> Source: F8 Guide to Programming (1977) §6.3/§6.5/§6.8 (pp.6-3…6-7);
> [MAME `f8.cpp` `SET_SZ`](https://github.com/mamedev/mame/blob/master/src/devices/cpu/f8/f8.cpp).

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
  decimal (BCD) add as three binary steps: (1) `$66` is pre-added to one operand,
  (2) a *binary* add of the two operands records carry/intermediate-carry **and
  sets all four status bits (O/Z/C/S) from this binary intermediate sum**, then
  (3) a decimal-correction factor (`$AA`/`$A0`/`$0A`/`$00`) is added to produce the
  final BCD value — *after* the status bits were already latched. So O and S
  reflect the binary intermediate, not the BCD result, and are meaningless; only Z
  and C are significant. The F8 Guide states this directly for AMD/ASD: "Statuses
  modified: CARRY, ZERO / **Statuses not significant: OVF, SIGN**" and "Other
  status indicators are modified, but their condition is not significant." MAME
  implements exactly this: `do_add_decimal()` calls `CLR_OZCS(); do_add(...);
  SET_SZ(tmp)` on the binary sum *before* applying the correction factor.
  This repo's `gameover.asm` compares scores by high nibble then low nibble instead
  of trusting sign.
  Source: F8 Guide to Programming (1977), §6.4 AMD p.6-4 and §6.6 ASD p.6-5
  ("status bits have the same significance as … AMD");
  [MAME `f8.cpp` `do_add_decimal`](https://github.com/mamedev/mame/blob/master/src/devices/cpu/f8/f8.cpp);
  `RANDOM_THOUGHTS.md`.

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
| `clr` | 1 | A ← 0 | — | **No status bits modified** (F8 Guide §6.9 p.6-7: "No status bits are modified"). In MAME `clr` is opcode `0x70` = `f8_lis(0)` (`m_a = 0`), which touches no flags. |
| `ni n` | 2 | A ← A AND n | Z, S (O, C cleared) | |
| `oi n` | 2 | A ← A OR n | Z, S (O, C cleared) | |
| `xi n` | 2 | A ← A XOR n | Z, S (O, C cleared) | |
| `ci n` | 2 | Compare immediate (A − n) | O, Z, C, S | **A unchanged**; flags only. Computed as `n + (~A) + 1`. |
| `ai n` | 2 | A ← A + n (binary) | O, Z, C, S | |
| `as r` | 1 | A ← A + (r) (binary) | O, Z, C, S | Add-from-scratchpad. |
| `asd r` | 1 | A ← A + (r) (decimal/BCD) | Z, C significant; O, S set but **not significant** | **Sign/Overflow meaningless for BCD** — flags are latched from the binary intermediate sum before the decimal correction. F8 Guide §6.6 p.6-5 ("same significance as AMD") + §6.4 p.6-4 ("not significant: OVF, SIGN"). See Gotchas. |
| `ns r` | 1 | A ← A AND (r) | Z, S (O, C cleared) | AND-from-scratchpad. |
| `xs r` | 1 | A ← A XOR (r) | Z, S (O, C cleared) | XOR-from-scratchpad; OR-substitute (see Gotchas). |
| `ds r` | 1 | (r) ← (r) − 1 (i.e. + $FF) | O, Z, C, S | Decrement happens **in the scratchpad register**, not A. Sets Z when result 0; loop-counter friendly. |
| `inc` | 1 | A ← A + 1 | O, Z, C, S | |
| `com` | 1 | A ← A XOR $FF (ones-complement) | Z, S set from result; **O, C unconditionally cleared** | F8 Guide §6.11 p.6-8: "Statuses modified: ZERO, SIGN / Statuses reset: OVF, CARRY … unconditionally reset to 0". MAME `f8_com`: `m_a = ~m_a; CLR_OZCS(); SET_SZ(m_a)` (matches). |
| `sl 1` / `sl 4` | 1 | Shift A left 1 / 4 bits | Z, C, S | Zeros shifted in. |
| `sr 1` / `sr 4` | 1 | Shift A right 1 / 4 bits | Z, C, S | Logical shift, zeros in. |
| `lm` | 1 | A ← (DC); DC ← DC + 1 | — | Load from memory via Data Counter, auto-increments DC. |
| `am` | 1 | A ← A + (DC) (binary); DC++ | O, Z, C, S | Add-from-memory via DC. |
| `dci nnnn` | 3 | DC ← nnnn (16-bit) | — | Set Data Counter for `lm`/`am`/`st`. |
| `adc` | 1 | DC ← DC + A | — | Add A to Data Counter (table/sprite stepping). A is treated as a **signed** byte (sign-extended). **No status bits modified** (F8 Guide §6.1 p.6-2: "No status bits are modified"). MAME `f8_adc` just routes A onto the data bus into DC0 via `ROMC_0A` and touches no flags. |
| `br n` | 2 | Unconditional relative branch | — | Range −128…+127. Does **not** clobber A. |
| `br7 n` | 2 | Branch if low-3-bits(ISAR) ≠ 7 | — | Loop terminator over an 8-byte window. |
| `bz n` / `bnz n` | 2 | Branch if Zero / if not Zero | — | `bz`=`bt 4`, `bnz`=`bf 4`. |
| `bc n` / `bnc n` | 2 | Branch if Carry / if no Carry | — | |
| `bp n` | 2 | Branch if Positive | — | Taken when **S = 1**, i.e. result's high-order bit is 0 (positive/zero). The Sign bit is complementary (see top of doc). `bp` = `bt 1` (opcode `0x81`, tests mask S). F8 Guide §6.7 Table 6-3 p.6-6 ("Sign bit is set") + Table 6-5; MAME `f8_bt(1)`. |
| `bm n` | 2 | Branch if Minus (negative) | — | Taken when **S = 0**, i.e. result's high-order bit is 1 (negative). `bm` = `bf 1` (opcode `0x91`, branch when masked status all reset). F8 Guide §6.7 Table 6-3 p.6-6 ("Sign bit is reset") + Table 6-4; MAME `f8_bf(1)`. |
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
- **MAME F8 CPU core** (`f8.cpp`) — authoritative for the behavior this project's
  emulator actually produces. Establishes the flag effects of `clr`/`com`/`adc`/`asd`
  (`f8_com`, `f8_adc`, `do_add_decimal`), the complementary Sign bit (`SET_SZ`:
  `if (~n & 0x80) m_w |= S;`), and the `bp`=`f8_bt(1)` / `bm`=`f8_bf(1)` branch tests:
  <https://github.com/mamedev/mame/blob/master/src/devices/cpu/f8/f8.cpp>
  (opcode→mnemonic mapping cross-checked in `f8dasm.cpp`: `CLR`=0x70, `COM`=0x18,
  `ADC`=0x8e, `BP`=0x81, `BM`=0x91).
- **F8 Guide to Programming (1977, Fairchild)** — bitsavers PDF (scanned, but carries
  an OCR text layer; pages also render via the `Read` tool). The instruction-set
  chapter (§6) is the primary reference for per-instruction status effects. Pages used:
  §6.1 ADC p.6-2, §6.4 AMD p.6-4, §6.6 ASD p.6-5, §6.7 Branch (Tables 6-3/6-4/6-5)
  pp.6-6…6-7, §6.9 CLR p.6-7, §6.11 COM p.6-8; complementary-sign examples in
  §6.3/§6.5/§6.8:
  <http://www.bitsavers.org/components/fairchild/f8/F8_Guide_To_Programming_1977.pdf>
- In-repo prior knowledge: `RANDOM_THOUGHTS.md`, `CLAUDE.md`, `src/ves.h`, `src/game.asm`.

Additional authoritative PDF (not needed to clear the items above, kept for reference):

- **F8 User's Guide (1976, Fairchild)** — linked from the VES Wiki F8 page:
  <https://channelf.se/veswiki/images/1/1d/F8_User%27s_Guide_%281976%29%28Fairchild%29%28Document_67095665%29.pdf>

### Open `[UNVERIFIED]` items

All three previously-open items are now **resolved** (confirmed by both the MAME
`f8.cpp` core and the F8 Guide to Programming §6; the two sources agree):

1. ~~BCD `asd` Sign/Overflow mechanism~~ — **resolved.** `asd`/`amd` latch all four
   status bits from the *binary* intermediate sum (3-step BCD: pre-add `$66` → binary
   add sets O/Z/C/S → decimal-correction factor applied *after*), so O and S are "not
   significant"; only Z and C are meaningful. (F8 Guide §6.4/§6.6; MAME `do_add_decimal`.)
2. ~~Flag effects of `clr`/`com`/`adc`~~ — **resolved.** `clr`: none. `com`: Z and S
   set from result, O and C unconditionally reset. `adc`: none. (F8 Guide §6.9/§6.11/§6.1;
   MAME `f8_com`/`f8_adc`/`f8_lis`.)
3. ~~Sign-branch polarity~~ — **resolved.** The Sign bit is complementary: S=1 ⇔ MSB=0
   (positive). `bp` (=`bt 1`) branches when **S=1**; `bm` (=`bf 1`) branches when
   **S=0**. (F8 Guide §6.7 Table 6-3 + §6.3/§6.5 examples; MAME `f8_bt(1)`/`f8_bf(1)`,
   `SET_SZ` "the S flag is complementary".)
