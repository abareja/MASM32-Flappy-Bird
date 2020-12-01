.386
.model flat, stdcall
option casemap:none

include draw.inc

.data
	colorGround b 10

.code
start:
	drawWorld proc

	drawWorld endp
end start
