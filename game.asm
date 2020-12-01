.686
.model flat, stdcall
option casemap:none

include \masm32\include\msimg32.inc
includelib \masm32\lib\msimg32.lib

include \masm32\include\windows.inc

include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib

include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib

include C:\masm32\include\gdi32.inc 
includelib C:\masm32\lib\gdi32.lib

include C:\masm32\include\masm32.inc
includelib C:\masm32\lib\masm32.lib

include \masm32\macros\macros.asm

WinMain proto :DWORD
Update proto
Init proto
InitRand proto
InitPipes proto
NumbToStr proto :DWORD, :DWORD
DrawCustomButton proto :DWORD

Bird struct
	bWidth dd ?
	bHeight dd ?

	x dd ?
	y dd ?

	startX dd ?
	startY dd ?

	velocityY dd ?
	acceleration dd ?
Bird ends

Ground struct
	startX dd ?
	endX dd ?
Ground ends

PipeSet struct
	x dd ?
	gapY dd ?
	passed db ?
PipeSet ends

.data
	ClassName db "WinClass", 0
	AppName db "Flappy Bird By Adrian Bareja", 0
	AppIcon db "bird.ico", 0

	BirdBmpName db "resources\bird.bmp", 0
	BackgroundBmpName db "resources\background.bmp", 0
	GroundBmpName db "resources\ground.bmp", 0
	BtnBmpName db "resources\button.bmp", 0
	ScoreBoardBmpName db "resources\scoreboard.bmp", 0
	PipeUpBmpName db "resources\pipe-up.bmp", 0
	PipeDownBmpName db "resources\pipe-down.bmp", 0

	FontSrc db "resources\FlappyBird.ttf", 0
	FontName db "Flappy Bird Regular", 0
	IDF_MYFONT byte "resources\Flappy.ttf"
	ClassNameBtn db "BUTTON", 0
	BtnText db "Restart", 0

	MyBird Bird <120, 85, 500, 330, 500, 330, 0, 1>
	MyGround1 Ground <0, 1200>
	MyGround2 Ground <1200, 2400>

	upForce dd -15
	timerClock dd 4
	gameState db 1
	bestScore dd 0
	score dd 0
	direction db 1
	groundLevel dd 750
	groundTextureLength dd 1200
	startText db "Get Ready!", 0
	scoreText db "SCORE", 0
	bestText db "BEST", 0
	TimerID dd 1234
	gapHeight dd 250
	leftScreenEdge dd 6

.data?
	hInstance HINSTANCE ?
	hWndRetryBtn HWND ?
	BirdBitmap dd ?
	BackgroundBitmap dd ?
	GroundBitmap dd ?
	ScoreBoardBitmap dd ?
	PipeUpBitmap dd ?
	PipeDownBitmap dd ?
	RandSeed dd ?
	RangeOfNumbers dd ?
	PipeSetArr PipeSet <?>
	buff db 11 dup(?)

.code
	start:
		invoke InitRand
    	invoke Init
    	invoke InitPipes

		invoke WinMain, hInstance
		invoke ExitProcess, eax

		Init proc
			invoke GetModuleHandle, NULL
			mov hInstance, eax

			invoke LoadImage, NULL, addr BackgroundBmpName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE
			mov BackgroundBitmap, eax

			invoke LoadImage, NULL, addr BirdBmpName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_CREATEDIBSECTION
			mov BirdBitmap, eax

			invoke LoadImage, NULL, addr GroundBmpName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_CREATEDIBSECTION
			mov GroundBitmap, eax

			invoke LoadImage, NULL, addr ScoreBoardBmpName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_CREATEDIBSECTION
			mov ScoreBoardBitmap, eax

			invoke LoadImage, NULL, addr ScoreBoardBmpName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_CREATEDIBSECTION
			mov ScoreBoardBitmap, eax

			invoke LoadImage, NULL, addr PipeUpBmpName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_CREATEDIBSECTION
			mov PipeUpBitmap, eax

			invoke LoadImage, NULL, addr PipeDownBmpName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_CREATEDIBSECTION
			mov PipeDownBitmap, eax
			ret
		Init endp

		InitRand proc
			rdtsc
	    	mov RandSeed, eax
	    	mov eax, 500
	    	sub eax, gapHeight
	    	mov RangeOfNumbers, eax
			ret
		InitRand endp

		InitPipes proc
			;mov eax, RangeOfNumbers
			;call PseudoRandom
	    	;add eax, 100
	    	;add eax, gapHeight

	    	;mov PipeSet1.gapY, eax

			ret
		InitPipes endp

		WinMain proc hInst:HINSTANCE
			LOCAL wc:WNDCLASSEX
			LOCAL msg:MSG
	    	LOCAL hWnd:HWND

			mov wc.cbSize, sizeof WNDCLASSEX
			mov wc.style, NULL
			mov wc.lpfnWndProc, offset WndProc
			mov wc.cbClsExtra, NULL
	    	mov wc.cbWndExtra, NULL
			push hInstance
			pop wc.hInstance
			mov wc.hbrBackground, NULL
			mov wc.lpszMenuName, NULL
			mov wc.lpszClassName, offset ClassName

			invoke LoadImage, NULL, addr AppIcon, IMAGE_ICON, 0, 0, LR_LOADTRANSPARENT or LR_LOADFROMFILE or LR_DEFAULTSIZE

			mov wc.hIcon, eax
			mov wc.hIconSm, eax
			invoke LoadCursor, NULL, IDC_ARROW
			mov wc.hCursor, eax
			invoke RegisterClassEx, addr wc

			invoke CreateWindowEx, NULL, addr ClassName, addr AppName, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX or WS_VISIBLE or WS_CLIPCHILDREN, CW_USEDEFAULT, CW_USEDEFAULT, 1206, 900, NULL, NULL, hInst, NULL

			mov hWnd, eax
			invoke ShowWindow, hWnd, SW_SHOWNORMAL
			invoke UpdateWindow, hWnd

			 .WHILE TRUE
	            invoke GetMessage, addr msg, NULL, 0, 0
	            .BREAK .IF (!eax)
	            invoke TranslateMessage, addr msg
	            invoke DispatchMessage, addr msg
	   		.ENDW
			mov eax, msg.wParam

			ret
		WinMain endp

		Draw proc, hdc:HDC, rect:RECT
			LOCAL hdcMem:HDC
			LOCAL hdcBuffer:HDC
			LOCAL hbmBuffer:HBITMAP
			LOCAL hbmOldBuffer:HBITMAP
			LOCAL hFont:HFONT
			Local hOldFont:HFONT
			LOCAL pen:HPEN 

			invoke CreateCompatibleDC, hdc
			mov hdcBuffer, eax

			invoke SetBkMode, hdcBuffer, TRANSPARENT
			RGB 255, 255, 255
			invoke SetTextColor, hdcBuffer, eax

			invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
			mov hbmBuffer, eax

			invoke SelectObject, hdcBuffer, hbmBuffer
			mov hbmOldBuffer, eax

			invoke CreateCompatibleDC, hdc
			mov hdcMem, eax

			invoke FillRect, hdcBuffer, addr rect, 0

			invoke SelectObject, hdcMem, BackgroundBitmap

			invoke BitBlt, hdcBuffer, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

			;invoke  NumbToStr, PipeSet1.x, addr buff
			;invoke TextOut, hdcBuffer, 10, 10, eax, 3

			invoke CreateFont, 80, 0, 0, 0, FW_BOLD, 0, 0, 0, 0, 0, 0, 2, 0, addr FontName
			mov hFont, eax

			invoke SelectObject, hdcBuffer, hFont
			mov hOldFont, eax

			;Drawing pipes

			.IF gameState == 2 || gameState == 3
				invoke SelectObject, hdcMem, PipeDownBitmap
				RGB 255, 0, 0
				;invoke TransparentBlt, hdcBuffer, PipeSet1.x, PipeSet1.gapY, 155, 600, hdcMem, 0, 0, 155, 600, eax

				invoke SelectObject, hdcMem, PipeUpBitmap
				RGB 255, 0, 0
				;mov ebx, PipeSet1.gapY
				sub ebx, 600
				sub ebx, gapHeight

				;invoke TransparentBlt, hdcBuffer, PipeSet1.x, ebx, 155, 600, hdcMem, 0, 0, 155, 600, eax
			.ENDIF

			;End of drawing Pipes

			;Drawing Bird

			invoke SelectObject, hdcMem, BirdBitmap

			RGB 255, 0, 0
			invoke TransparentBlt, hdcBuffer, MyBird.x, MyBird.y, MyBird.bWidth, MyBird.bHeight, hdcMem, 0, 0, MyBird.bWidth, MyBird.bHeight, eax

			;End of drawing Bird

			;Drawing Ground

			invoke SelectObject, hdcMem, GroundBitmap

			invoke BitBlt, hdcBuffer, MyGround1.startX, groundLevel, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

			invoke BitBlt, hdcBuffer, MyGround2.startX, groundLevel, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY

			;End of drawing Ground

			invoke SetTextAlign, hdcBuffer, TA_CENTER

			RGB 0, 0, 0
			invoke CreatePen, PS_SOLID, 3, eax
			mov pen, eax

			invoke SelectObject, hdcBuffer, pen

			invoke BeginPath, hdcBuffer
			.IF gameState == 1
				invoke TextOut, hdcBuffer, 600, 100, addr startText, 10
			.ELSEIF gameState == 2
				invoke  NumbToStr, score, addr buff
				invoke TextOut, hdcBuffer, 620, 50, eax, 2
			.ELSEIF gameState == 3
				invoke SelectObject, hdcMem, ScoreBoardBitmap

				RGB 255, 0, 0
				invoke TransparentBlt, hdcBuffer, 444, 50, 313, 333, hdcMem, 0, 0, 313, 333, eax

				invoke  NumbToStr, score, addr buff
				invoke TextOut, hdcBuffer, 620, 120, eax, 2

				invoke  NumbToStr, bestScore, addr buff
				invoke TextOut, hdcBuffer, 620, 273, eax, 2

				invoke EndPath, hdcBuffer

				RGB 253, 119, 90
				invoke SetTextColor, hdcBuffer, eax

				invoke CreateFont, 40, 0, 0, 0, 400, 0, 0, 0, 0, 0, 0, 2, 0, addr FontName
				mov hFont, eax

				invoke SelectObject, hdcBuffer, hFont
				invoke TextOut, hdcBuffer, 600, 80, addr scoreText, 5
				invoke TextOut, hdcBuffer, 600, 233, addr bestText, 4

			.ENDIF
			invoke EndPath, hdcBuffer

			invoke StrokeAndFillPath, hdcBuffer

			invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcBuffer, 0, 0, SRCCOPY

			invoke DeleteDC, hdcMem
			invoke SelectObject, hdcBuffer, hOldFont
			invoke SelectObject, hdcBuffer, hbmOldBuffer
			invoke DeleteObject, hFont
			invoke DeleteObject, pen
			invoke DeleteDC, hdcBuffer
			invoke DeleteObject, hbmBuffer
			invoke DeleteObject, hbmOldBuffer
			ret
		Draw endp

		WaitingAnimation proc
			.IF direction == 1
				.IF MyBird.y <= 310
					mov direction, 0
				.ELSE 
					sub MyBird.y, 1
				.ENDIF
			.ELSE
				.IF MyBird.y >= 340
					mov direction, 1
				.ELSE
					add MyBird.y, 2
				.ENDIF
			.ENDIF
			ret
		WaitingAnimation endp

		Collision proc
			mov MyBird.velocityY, 0 
			mov gameState, 3
			invoke ShowWindow, hWndRetryBtn, SW_SHOW

			mov eax, score
			.IF eax > bestScore
				mov bestScore, eax
			.ENDIF
			ret
		Collision endp

		Flying proc
			mov eax, groundLevel
			sub eax, MyBird.bHeight

			.IF MyBird.y >= eax
				invoke Collision
			.ELSE
				mov eax, MyBird.acceleration
				add MyBird.velocityY, eax

				mov eax, MyBird.velocityY
				add MyBird.y, eax

				;sub PipeSet1.x, 4
				;mov eax, PipeSet1.x
				;add eax, 155

				.IF eax <= leftScreenEdge
					;mov PipeSet1.x, 1200

			    	call PseudoRandom
			    	add eax, 100
			    	add eax, gapHeight
			    	;mov PipeSet1.gapY, eax
				.ENDIF
			.ENDIF
			ret
		Flying endp

		Update proc
			;gameState = 1 - waiting for start
			;gameState = 2 - game is running
			;gameState = 3 - game lost

			.IF gameState == 1 || gameState == 2
				sub MyGround1.startX, 4
				sub MyGround1.endX, 4
				sub MyGround2.startX, 4
				sub MyGround2.endX, 4

				mov eax, leftScreenEdge

				.IF MyGround1.endX <= eax
					mov MyGround1.startX, 1200
					mov MyGround1.endX, 2400
				.ENDIF

				.IF MyGround2.endX <= eax
					mov MyGround2.startX, 1200
					mov MyGround2.endX, 2400
				.ENDIF

			.ENDIF

			.IF gameState == 1
				invoke WaitingAnimation
			.ELSEIF gameState == 2
				invoke Flying
			.ELSEIF gameState == 3
				
			.ENDIF

			ret
		Update endp

		WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
			LOCAL rect:RECT
			LOCAL hdc:HDC
			LOCAL hdcBtn:HDC

			.IF uMsg==WM_CREATE
				invoke SetTimer, hWnd, TimerID, timerClock, NULL

				invoke AddFontResourceEx, addr FontSrc, FR_PRIVATE, NULL

				invoke CreateWindowEx, 0, addr ClassNameBtn, addr BtnText, WS_VISIBLE or WS_CHILD or BS_BITMAP or BS_OWNERDRAW, 535, 400, 130, 75, hWnd, NULL, hInstance, NULL
				mov hWndRetryBtn, eax

				invoke ShowWindow, hWndRetryBtn, SW_HIDE
				ret
		    .ELSEIF uMsg==WM_TIMER
			    invoke GetDC, hWnd
				mov hdc, eax
				invoke GetClientRect, hWnd, addr rect
		    	invoke Update
		    	invoke Draw, hdc, rect
		    	invoke ReleaseDC, hWnd, hdc
		    	ret
			.ELSEIF uMsg==WM_CHAR || uMsg==WM_LBUTTONDOWN
				.IF gameState == 1
					mov gameState, 2
				.ENDIF
				mov eax, upForce
				mov MyBird.velocityY, eax
				ret
			.ELSEIF uMsg==WM_COMMAND
				mov score, 0
				mov eax, MyBird.startY
				mov MyBird.y, eax
				mov direction, 1
				mov gameState, 1
				;mov PipeSet1.x, 1200
				call PseudoRandom
		    	add eax, 100
		    	add eax, gapHeight
		    	;mov PipeSet1.gapY, eax
				invoke ShowWindow, hWndRetryBtn, SW_HIDE
				ret
			.ELSEIF uMsg==WM_DRAWITEM
				invoke GetDC, hWndRetryBtn
				mov hdcBtn, eax
				invoke DrawCustomButton, hdcBtn
				ret
			.ELSEIF uMsg==WM_DESTROY
				invoke DeleteObject, BackgroundBitmap
				invoke DeleteObject, BirdBitmap
				invoke KillTimer, hWnd, TimerID
				invoke RemoveFontResourceEx, addr FontSrc, FR_PRIVATE, NULL
		        invoke PostQuitMessage, NULL
				ret
		    .ELSE
		        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
		        ret
		    .ENDIF
		    xor eax, eax
		    ret
		WndProc endp

		DrawCustomButton proc, hdc:HDC
			LOCAL rect:RECT
			LOCAL br:HBRUSH
			LOCAL BtnBitmap:HBITMAP
			LOCAL hdcMem:HDC
			LOCAL hdcBuffer:HDC
			LOCAL hbmBuffer:HBITMAP
			LOCAL hbmOldBuffer:HBITMAP

			mov rect.left, 0
			mov rect.top, 0
			mov rect.right, 130
			mov rect.bottom, 75

			invoke CreateCompatibleDC, hdc
			mov hdcBuffer, eax

			invoke CreateCompatibleBitmap, hdc, rect.right, rect.bottom
			mov hbmBuffer, eax

			invoke SelectObject, hdcBuffer, hbmBuffer
			mov hbmOldBuffer, eax

			invoke CreateCompatibleDC, hdc
			mov hdcMem, eax

			invoke LoadImage, NULL, addr BtnBmpName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE or LR_CREATEDIBSECTION
			mov BtnBitmap, eax

			invoke SelectObject, hdcMem, BtnBitmap

			invoke BitBlt, hdcBuffer, 0, 0, 130, 75, hdcMem, 0, 0, SRCCOPY

			invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hdcBuffer, 0, 0, SRCCOPY

			invoke DeleteDC, hdcMem
			invoke SelectObject, hdcBuffer, hbmOldBuffer
			invoke DeleteDC, hdcBuffer
			invoke DeleteObject, hbmBuffer
			invoke DeleteObject, hbmOldBuffer
			ret
		DrawCustomButton endp

		NumbToStr PROC uses ebx x:DWORD, buffer:DWORD

		    mov     ecx, buffer
		    mov     eax, x
		    mov     ebx, 10
		    add     ecx, ebx 
		@@:
		    xor     edx, edx
		    div     ebx
		    add     edx, 48             
		    mov     BYTE PTR [ecx], dl   
		    dec     ecx                 
		    test    eax, eax             
		    jnz     @b

		    inc     ecx
		    mov     eax, ecx             
		    ret

		NumbToStr ENDP

		PseudoRandom PROC                       
			push edx                 
			imul edx, RandSeed, 08088405H
			inc edx
			mov RandSeed, edx
			mul edx
			mov eax, edx
			pop edx
		    ret
		ret
		PseudoRandom ENDP 

	end start
