@echo off
set cartPath=%cd%/bin

mame channelf -debug -cartridge %cartPath%\game.bin -w -effect sharp -r 800x455 -ka