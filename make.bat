@echo off
/masm32/bin/ml /c /coff game.asm
/masm32/bin/rc /v rsrc.rc
/masm32/bin/cvtres /machine:ix86 rsrc.res
/masm32/bin/link /SUBSYSTEM:WINDOWS game rsrc
game.exe
pause