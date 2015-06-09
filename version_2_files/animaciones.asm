section .data

PatternAnimRotorU: db ' < < < < < < < < < < < < < < <',10
PatternAnimRotorD: db '> > > > > > > > > > > > > > >',10

;--------------------------------------------------- PARAMETROS DELAY 
  timeval:
	tv_sec  dd 0
	tv_usec dd 0

;--------------------------------------------------- ESCAPE CODES
PosTerm: db 27,"[01;01H" 			; <ESC>[<Y>;<X>H
POSLEN: equ $-PosTerm 				; Length of term position string

;--------------------------------------------------- POSICIONES PANTALLA
; Look-up table
ASCII_digits:	db "0001020304050607080910111213141516171819"
				db "2021222324252627282930313233343536373839"
				db "4041424344454647484950515253545556575859"
				db "606162636465666768697071727374757677787980"
; Table is read moving two digits at once to a 16-bit register like DX.
; They are inserted into the terminal control string PosTerm at the appropriate place. See GotoXY.
; Will work when terminal size is 80x80.
; If you intend to work on a larger console than 80 X 80, you must
; add additional ASCII digit encoding to the end of ASCII_digits.
; Keep in mind that the code shown here will only work up to 99 X 99.

primeraLetraRotor: db 0h		; para almacenar la letra que se va a imprimir en la pantalla

; EXTERN_THIS animaciones
flechaU: db '^'
flechaR: db '>'
flechaD: db '<'
entradL: db 'v'
null: 	 db ' '					; caracter en blanco para 'borrar' caracteres de pantalla

; EXTERN_THIS animaciones
debugEntrada: db '#'
debugSalida: db '$'

global PrintMsjEncriptado, AnimarEntradaRotores, AnimarSalidaRotores
global PrintRotor, AnimarRotor, Delay, limpiarLetraAnteriorMovida
global primeraLetraRotor, GotoXY

extern tabla_rotores, varMsjEncriptado, MensajeAEncriptar, sys_write, AddCharVarMsjEncriptado

; ============================================================================================== EXTERN_THIS
; ANIMACIONES

PrintMsjEncriptado:			; imprime al pie de pagina el buffer con el msj encriptado
	push rax
	push rdx
	push rsi
	
	mov ax, 2805h 			; X,Y = 28,05 as a single hex value in AX
	call GotoXY 			; Position the cursor
	mov rsi, MensajeAEncriptar				;address of the buffer to print out
	mov rdx, r15									;number of chars to print out
	call sys_write	
	
	mov ax, 2807h 			; X,Y = 28,07 as a single hex value in AX
	call GotoXY 			; Position the cursor
	mov rsi, varMsjEncriptado				;address of the buffer to print out
	mov rdx, r15									;number of chars to print out
	call sys_write	
	

	pop rsi
	pop rdx
	pop rax
ret

AnimarEntradaRotores:
	call Delay											;se espera n seg
	call AnimarLetraEncriptada				;se va actualizando la letra encriptada en cada rotor

	push rax
	push rcx
	push rdx

	;-----POS  DE ENTRADA DEL ROTOR ACTUAL
	sub rax, "A"										;se resta A para obtener el indice del entrada
	mov rdx, rax										;se resta A para obtener el indice del entrada
	call GetPosRotorActual
	add ah, dl											;se incrementa desde la posicon inicial hasta el indice
	dec al												;se sube una linea
	call GotoXY
	call printDebugEntrada								;se imprime un asterisco sobre la pos de entrada
	
	;-----/ POS  DE SALIDA DEL ROTOR ACTUAL 		
	add al, 2											;se baja una linea
	call GotoXY
	call printDebugEntrada
		
	;-----POS DE ENTRADA DEL ROTOR SIGUIENTE
	;xor rax, rax											;limpiamos rax
	;mov al, byte[rsi + rdx]			

	.exit
			;call GetPosRotorActual
			;add al, 2
			;add ah, cl						;se incrementa desde la posicon inicial hasta el indice
			;call GotoXY			
			;call printDebugEntrada

	pop rdx
	pop rcx
	pop rax
ret

AnimarSalidaRotores:
	call Delay
	call AnimarLetraEncriptada				;se va actualizando la letra encriptada en cada rotor

	push rax
	push rbx
	push rcx
	
	mov rcx, 27						;iniciamos en la ultma posicion del rotor
	
	.buscarLetra
		dec rcx
		;js si es menor a 0 LANZAR ERROR 
		mov bl, byte[rsi + rcx]
		cmp al, bl					;si la letra del rotor conicide con la letra a buscar salimos
			jnz .buscarLetra
		
		;-----POS  DE ENTRADA DEL ROTOR ACTUAL

	call GetPosRotorActual
	add ah, cl											;se incrementa desde la posicon inicial hasta el indice
	dec al													;se sube una linea
	call GotoXY
	call printDebugSalida									;se imprime un asterisco sobre la pos de entrada
	
		;-----/ POS  DE SALIDA DEL ROTOR ACTUAL 		
	add al, 2												;se baja una linea
	call GotoXY
	call printDebugSalida

	pop rcx
	pop rbx
	pop rax
ret

animarPrimeraLetraRotor:
	push rcx
	push rdx
	push rsi
	
	call AnimarRotor
	call limpiarLetraAnteriorMovida

	mov ah, cl					; POS X, cl = indice dentro del rotor
	add ah, 4					; corremos la posicion 6 espacios	
	
	mov al, r10b			; POS Y indice dentro del ciclo de los rotores
	shl al, 2						
	add al, 4					;POS Y = pos rotor * 2 +3
	
	call GotoXY

	mov rsi, primeraLetraRotor		;address of char to print out
	mov rdx, 1						;number of chars to print out
	call sys_write	
	
	pop rsi
	pop rdx
	pop rcx
ret

AnimarRotor:
	push rax
	push rcx
	push rdx
	push rsi
	push r8
	
	mov r8 , 1
	and r8, rcx			; resultado 1 o 0... usado para la animacion
	
	call animarFlechasU
	call animarFlechasD
	
	pop r8
	pop rsi
	pop rdx
	pop rcx
	pop rax
ret

AnimarLetraEncriptada:
	call AddCharVarMsjEncriptado		;mueve al buffer de msj encriptado la letra y aumenta su indice en r15
	call PrintMsjEncriptado					;imprime al pie de pagina el buffer con el msj encriptado
	dec r15										;volvemos a dejar el indice en la posicion que le corresponde
ret

limpiarLetraAnteriorMovida:
	push rcx
	push rdx
	push rsi
	
	mov ah, cl					; POS X, cl = indice dentro del rotor
	add ah, 3					; corremos la posicion 4 espacios	
	
	mov al, r10b			; POS Y indice dentro del ciclo de los rotores
	shl al, 2						
	add al, 4					;POS Y = pos rotor * 2 +3
	
	call GotoXY

	mov rsi, null		;address of char to print out
	mov rdx, 1								;number of chars to print out
	call sys_write	
	
	pop rsi
	pop rdx
	pop rcx
ret

animarFlechasU:
	call GetPosRotorActual
	dec al									;se corre una posicon hacia arriba
	dec ah									;se corre una posicon hacia la izq
	call GotoXY
	lea rsi, [PatternAnimRotorU+r8]			;address of the buffer to print out	;dependiendo si r8 es 0 o 1 se crea el efecto de animacion
	mov rdx, 28								;number of chars to print out
	call sys_write		
ret

animarFlechasD:
	call GetPosRotorActual
	dec ah									;se corre una posicon hacia atras
	inc al									;se corre una posicon hacia abajo
	call GotoXY
	lea rsi, [PatternAnimRotorD+r8]			;address of the buffer to print out ;dependiendo si r8 es 0 o 1 se crea el efecto de animacion
	mov rdx, 28								;number of chars to print out
	call sys_write			
ret

GetPosRotorActual:
	mov ah, 5					; POS X = 5 espacios desde la pos inicial
	
	mov al, r10b				; POS Y	R10 es el indice del rotor actual, usado como escala relativa al top de la pantalla
	shl al, 2						; se multiplica por 4 el indice para dejar una separacion en pantalla de cada rotor
	add al, 3						; POS Y = pos rotor * 4 + 3 (3 espacios desde el inicio) deja 4 espacios entre cada rotor y la poscion la baja 3 espacios desde el TOP
ret

PrintRotor:
	push rax
	push rcx
	push rdx
	push rsi
	
	cmp rcx, 25									; llama a la animacion de mover letra si la letra no esta en la ultima posicion
		ja .continuar
		call animarPrimeraLetraRotor ;else
	
	.continuar:

	call GetPosRotorActual
	call GotoXY

	mov rsi, rsi								; address of the buffer to print out
	mov rdx, 27									; number of chars to print out
	call sys_write
	
	pop rsi
	pop rdx
	pop rcx
	pop rax
ret

printDebugEntrada:
	push rcx
	push rsi
	push rdx
	
	mov rsi, debugEntrada	;address of the buffer to print out
	mov rdx, 1						;number of chars to print out
	call sys_write
	
	pop rdx
	pop rsi
	pop rcx
ret	

printDebugSalida:
	push rcx
	push rsi
	push rdx
	
	mov rsi, debugSalida		;address of the buffer to print out
	mov rdx, 1						;number of chars to print out
	call sys_write
	
	pop rdx
	pop rsi
	pop rcx
ret

;-------------------------------------------------------------------------
	; GotoXY: Position the Linux Console cursor to an X,Y position
	; UPDATED: February 4, 2015
	; IN: X in AH, Y in AL
	; RETURNS: Nothing
	; MODIFIES: PosTerm terminal control sequence string
	; CALLS: Kernel sys_write
	; DESCRIPTION: Prepares a terminal control string for the X,Y coordinates
	; passed in AL and AH and calls sys_write to position the
	; console cursor to that X,Y position. Writing text to the
	; console after calling GotoXY will begin display of text
	; at that X,Y position.
GotoXY:
	push rax
	push rbx 			; Save callers registers
	push rcx
	push rsi
	push rdx

	xor rbx, rbx 			; Zero EBX
	xor rcx, rcx 			; Ditto ECX

	; Poke the Y digits:
	mov bl, al 			; Put Y value into scale term EBX
	mov cx, word [ASCII_digits + rbx * 2] 	; Fetch decimal digits to CX
	mov word [PosTerm + 2], cx 	; Poke digits into control string

	; Poke the X digits:
	mov bl, ah 			; Put X value into scale term EBX
	mov cx, word [ASCII_digits + rbx * 2] 	; Fetch decimal digits to CX
	mov word [PosTerm + 5], cx 	; Poke digits into control string

	; Send control sequence to stdout:
	mov rsi, PosTerm 		; Pass address of the control string
	mov rdx, POSLEN 			; Pass the length of the control string
	call sys_write	 

	pop rdx
	pop rsi
	pop rcx 
	pop rbx 
	pop rax
ret

Delay:
	push rax
	push rbx
	push rcx
	push r8
	push r10

	mov dword [tv_sec], 0							; Sleep n seconds
	mov dword [tv_usec], 150*1000000	; Sleep n nanoseconds 200*1000000 = 200 miliseg
	mov rax, 162
	mov rbx, timeval
	mov rcx, 0
	int 0x80
	
	pop r10
	pop r8
	pop rcx
	pop rbx
	pop rax
ret
	
