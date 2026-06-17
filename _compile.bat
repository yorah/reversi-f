@echo off
if not exist bin mkdir bin
dasm src/game.asm -f3 -obin/game.bin -lbin/game.lst
