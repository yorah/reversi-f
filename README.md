 # Reversi-F
Port of the Reversi game to the Fairchild ChannelF / VES.

## Compiling & running

Use:
- [dasm](https://dasm-assembler.github.io/) (to assemble the code)
- [MAME](https://www.mamedev.org/) (if you want to run the compiled code)

Those tools should be available in your PATH. If not, you will need to
modify the .bat files referencing them.

You also need to put the ChannelF bios in the /roms folder (or it should
be available to MAME one way or another).

## Disclaimer

This code certainly ain't pretty. It started as a small experiment, out
of curiosity for the F8 processor and the Fairchild ChannelF, and I didn't
really anticipate the time I would spend on it. I learned a few things
along the way, some of whom I shared in the [Random thoughts] (RANDOM_THOUGHTS.md) file.

If I were to do it again, I would organize the code differently.

I also really wanted to have a working version which does not use the SCHACH
RAM (additional RAM), so everything had to work with only the 64 8bits
registers of the F8 (thus acting both as registers and RAM for the game).

I may or may not continue working on it for a bit, but no guarantee at all, and
if I do that would be at a slower pace.

## Acknowledgements

This wouldn't have been possible at all without all the info available on
the [VES Wiki](https://channelf.se/veswiki/index.php?title=Main_Page).
I also learned a lot (and surely borrowed some code) from the games disassembled and
available over there (both homebrews and actual legacy games).

The [official ChannelF Thread](https://forums.atariage.com/topic/274416-the-official-channel-f-thread/) on Atariage.com was also
very helpful, and I kindly thank everyone that took some time to point me in the right directions.
