@echo off
/masm32/bin/ml /c /coff game.asm
/masm32/bin/link /SUBSYSTEM:WINDOWS game
game.exe
pause