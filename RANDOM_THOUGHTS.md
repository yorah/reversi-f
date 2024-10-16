# Random Thoughts

This file contains random thoughts/findings along the process of
writing reversi-f. This might serve as insight for newcomers to F8
programming, or for myself at a later time.

## JMP pitfall
- *Date:* 2024-09-18
- *Thought:*

JMP instruction changes the content of the accumulator. Yes, it is written
quite clearly in the F8 programming guide, but I didn't pay much attention
to it at first. Until I stumbled on a bug related to that, where I had to
debug step-by-step and see that A was modified by it...

---

## JMP vs BR
- *Date:* 2024-09-18
- *Thought:* 

BR is an unconditional branch. So it behaves quite similarly to JMP, at least
for the unexperimented reader. There are however some subtle differences:
- BR can only be used to jump to -127 +128 relative addresses
- JMP can be used to jump to an absolute address
Again, this is written quite clearly in the F8 programming guide. The pitfall to
avoid is writing some BR, which work at first, then adding some additonal code
between the BR and the destination, so that the adress to which we want to branch
gets out of reach. Depending on the language server/editor you use, you might get
a warning, or not...

One might think JMP is thus always better. I guess the difference is that BR uses
one less byte than JMP, so that it can/could lead to smaller programs. I also
think that JMP could be faster, as there is no add needed to get the new address,
unlike for BR.

Not sure about that last paragraph, if someone wants to enlighten me more.

---

## No OR-from-scratchpad
- *Date:* 2024-09-18
- *Thought:* 

Strangely, there is no OR-from-scratchpad instruction. There is only
OR-immediate (where you provide the value), and OR-from-memory (where
the OR is done with a memory location).

There is however an XS, which is XOR-from-scratchpad. In case you are
sure the bits you want to OR are at 0 in the accumulator, it will behave
the same way as an OR.

A way to emulate an OR could be an XOR-AND-XOR sequence (not sure, but
looks like the way to go): (A XOR Sreg) XOR (A AND Sreg).

---

## BIOS_CLEAR_SCREEN and kstack
- *Date:* 2024-09-24
- *Thought:* 

The builtin clrscrn (see bios disassembly on VES Wiki) makes use of two things:
- the r31 register, which must be set to 0 in order for clrscrn to work correctly
- the builtin pushk/popk routines, which use a different structure than the one
used by kstack (from VES Wiki again), and doesn't start from the same register

This effectively means that calling BIOS_CLEAR_SCREEN after the kstack
has been used should be done very carefully, or avoiding using it
alltogether.

---

## BIOS_CLEAR_SCREEN and kstack
- *Date:* 2024-10-11
- *Thought:* 

Turns out you can't rely on the sign status when doing BCD arithmetics
on the F8 processor (like using ASD).

I ended up comparing the scores in gameover.asm by first comparing high
nibble and then low nibble.

---
