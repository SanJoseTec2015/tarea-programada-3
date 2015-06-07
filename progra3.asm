;--------------------------------------------------------------------------------------------------------;
;						INSTITUTO TECNOLÓGICO DE COSTA RICA
;									TAREA PROGRAMADA 3
;										PROYECTO FINAL
;										SEMESTRE 2015
;
;										MAQUINA ENIGMA
;
;									ANDRES PENIA CASTILLO
;											GERMAN VIVES
;							ISAAC CAMPOS MESEN 2014004626
;
;										ANIO 2015
;---------------------------------------------------------------------------------------------------------;

	section .bss							;Section containing uninitialized data

BUFLEN equ 1					;We read the file 1024 bytes at a time
Buffer resb BUFLEN					;Text buffer itself

	section .data						;Section containing initialized data

;varIntToStringLEN	equ $ - varIntToString

entrada: db ' ENTRADA = ';'------------------------------------------------------------', 10,10,\
'        INSTITUTO TECNOLOGICO DE COSTA RICA', 10,\
'                TAREA PROGRAMADA 3', 10,\
'                 I SEMESTRE 2015', 10,10,\
'            MAQUINA ENIGMA', 10, 10,\
'          ISAAC CAMPOS MESEN 2014004626', 10,\
'        ANDRES PENIA CASTILLO', 10,\
'                GERMAN VIVES', 10, 10,\
'                    ANIO 2015', 10,10,\
'------------------------------------------------------------',10, 10, ' ENTRADA = '

entradaLEN	equ $ - entrada

lenprimeraLetraRotors	equ 26

salida: db " RESULTADO = "
salidaLEN equ $ - salida


varRotor1 db 'AJDKSIRUXBLHWTMCQGZNPYFVOE',0h
varRotor2 db 'BDFHJLCPRTXVZNYEIWGAKMUSQO',0h
varRotor3 db 'VZBRGITYUPSDNHLXAWMJQOFECK',0h

Rotores dq varRotor1, varRotor2, varRotor3, 0h


varMsjEncriptado: db '..........................',0h

PatternAnimRotorU: db '< < < < < < < < < < < < < < <',10
PatternAnimRotorD: db '> > > > > > > > > > > > > > >',10



;--------------------------------------------------- ESCAPE CODES
PosTerm: db 27,"[01;01H" 			; <ESC>[<Y>;<X>H
POSLEN: equ $-PosTerm 				; Length of term position string

ClearTerm: db 27,"[2J" 				; <ESC>[2J; clears display
CLEARLEN equ $-ClearTerm 			; Length of term clear string
;--------------------------------------------------- /ESCAPE CODES



;--------------------------------------------------- PARAMETROS DELAY 
  timeval:
    tv_sec  dd 0
    tv_usec dd 0
;--------------------------------------------------- / PARAMETROS DELAY

; This table gives us pairs of ASCII digits from 0-80. Rather than
; calculate ASCII digits to insert in the terminal control string,
; we look them up in the table and read back two digits at once to
; a 16-bit register like DX, which we then poke into the terminal
; control string PosTerm at the appropriate place. See GotoXY.
; If you intend to work on a larger console than 80 X 80, you must
; add additional ASCII digit encoding to the end of Digits. Keep in
; mind that the code shown here will only work up to 99 X 99.

Digits:	db "0001020304050607080910111213141516171819"
			db "2021222324252627282930313233343536373839"
			db "4041424344454647484950515253545556575859"
			db "606162636465666768697071727374757677787980"
	
primeraLetraRotor: db 0h		;para almacenar la letra que se va a imprimir en la pantalla

flechaU: db '^'
flechaR: db '>'
flechaD: db '<'
entradL: db 'v'

debbug: db '#'

null: db ' '								;caracter en blanco para 'borrar' caracteres de pantalla

	section .text						;Section containing code

global _start							;Linker needs this to find the entry point!

_start:
;///// PRUEBA VALOR RETORNO ROTOR
	;call read
	;xor r15, r15

	;mov al, byte[rsi]					;se guarda el caracter leido
	;mov rsi, varRotor1
	;call GetLetraRotor
	;call AddCharVarMsjEncriptado
	;call PrintMsjEncriptado
;///// PRUEBA VALOR RETORNO ROTOR
	call ClrScr

	call RecorrerRotores
	jmp done

;Read a buffer full of text from stdin:
read:
	mov rax, 0						;sys_read (code 0)
	mov rdi, 0						;file_descriptor (code 0 stdin)
	mov rsi, Buffer				;address to the buffer to read into
	mov rdx, BUFLEN			;maximun number of bytes to read
	syscall								;system call

	mov rbp, rax					;save the number of bytes read
	cmp rax, 0						;test if the number of bytes read is 0
		jz done							;jump to the tag done if it is 0

	;Setup the register for later use
	mov rsi, Buffer				;place the buffer address in the rsi
ret

GetLetraRotor:
	sub rax, "A"						;se resta A para obtener el indice del entrada
	mov al, byte[rsi+rax]
ret

RecorrerRotores:
	xor r10, r10
		.siguienteRotor
			mov rsi, [Rotores + r10 * 8]
			call PrintRotor
			call AnimarRotor

			inc 	r10						;next rotor
			cmp r10, 3 	; la cantidad de rotores		
				jnz .siguienteRotor
		
	mov rax, 'W'
	xor r10, r10
		.siguienteRotor2
			mov rsi, [Rotores + r10 * 8]
			;call GirarRotor
			call Delay
			;call AnimarRotor
			call AnimarBusquedaLetra
			call GetLetraRotor

			inc 	r10						;next rotor
			cmp r10, 3 	; la cantidad de rotores		
				jnz .siguienteRotor2
				
		call AddCharVarMsjEncriptado
		call PrintMsjEncriptado
		;mov rsi, varRotor2
		;mov r10, 1
		;call PRUEBA_GIRAR_ROTORES
ret

AnimarBusquedaLetra:
	push rax
	push rcx
	push rdx

	;-----POS  DE SALIDA DEL ROTOR ACTUAL
	sub al, "A"						;se resta A para obtener el indice del entrada
	mov dl, al
	call GetPosRotorActual
	add ah, dl						;se incrementa desde la posicon inicial hasta el indice
	dec al								;se sube una linea
	call GotoXY
	call printDebbug
	
	add al, 2							;se baja una linea
	call GotoXY
	call printDebbug
	
	xor rax, rax
	;-----POS DE ENTRADA DEL ROTOR SIGUIENTE
	mov al, byte[rsi + rdx]
	call GetLetraRotor
	sub al, "A"						;se resta A para obtener el indice del entrada
	mov cl, al
	
	cmp dl, cl
		jb .ponerFlechasR
		
		
		jmp .exit
		
	.ponerFlechasL
		dec cl

		call GetPosRotorActual
		add ah, cl						;se incrementa desde la posicon inicial hasta el indice
		inc al								;se sube una linea
		call GotoXY
		
		call printDebbug
		cmp cl, dl
			ja .ponerFlechasL


	.ponerFlechasR		
	
		
		call GetPosRotorActual
		add ah, dl						;se incrementa desde la posicon inicial hasta el indice
		inc al								;se sube una linea
		call GotoXY
		call printDebbug

		inc dl

		cmp dl, cl
			jnz .ponerFlechasR
		inc al
		call GotoXY
		call printDebbug
	

.exit


	pop rdx
	pop rcx
	pop rax
ret

PRUEBA_GIRAR_ROTORES:
	mov ecx, 26
	.ciclo:
		call GirarRotor
		call Delay
	loop .ciclo
ret
;------------------------------------------------------------------------------------------------------------
; GirarRotor
;
; El procedimiento recibe en el RSI el el rotor que se quiere girar 1 pos
;
; E: RSI la direccion del buffer del rotor
; M: nada
;------------------------------------------------------------------------------------------------------------
GirarRotor:
	push rax
	push rcx
	push r8
	push rsi
	
	mov r8b, [rsi]						;se guarda temporalmente la primer primer primeraLetraRotor del rotor
	mov [primeraLetraRotor], r8b
	xor rcx, rcx			
	.nextChar:
		mov al, byte [rsi + rcx + 1] 	;se guarda el siguiente char en al > RSI rotor, RCX indice, 1 = siguiente char

		mov [rsi + rcx], al					;se mueve el siguiente char a la posicion actual
		inc rcx										;indice
		
		mov byte [rsi + rcx], " "	;se mueve un caracter vacio en la posicion donde
		
		call PrintRotor
		call Delay

		cmp rcx, 25			;si no ha llegado al final continua con el siguiente char/byte
			jnz .nextChar
	mov [rsi + rcx ], r8b				;movemos al final del rotor la primera primeraLetraRotor
	inc rcx										;se incrementa el indice para borrar el caracter movido anterior
	call limpiarLetraAnteriorMovida
	call PrintRotor

	pop rsi
	pop r8
	pop rcx
	pop rax
ret

;------------------------------------------------------------------------------------------------------------
; AddCharVarMsjEncriptado
;
; El procedimiento usa el registro R15 como indice global para el msj
; que se va a encriptar, inserta la primeraLetraRotor al final del texto y deja en R15
; el indice que apuntal al final del texto.
;
; E: AL el char que se quiere agregar al msj encriptado
; M: R15
;------------------------------------------------------------------------------------------------------------
AddCharVarMsjEncriptado:
	mov byte[varMsjEncriptado+r15], al
	inc r15
ret

PrintMsjEncriptado:
	push rax
	push rdx
	push rsi
	
	; Position the cursor for the "Press Enter" prompt:
	mov ax, 0522h 			; X,Y = 1,23 as a single hex value in AX
	call GotoXY 			; Position the cursor
	
	mov rsi, varMsjEncriptado				;address of the buffer to print out
	mov rdx, r15									;number of chars to print out
	call sys_write	

	pop rsi
	pop rdx
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
	mov rdx, 1								;number of chars to print out
	call sys_write	
	
	pop rsi
	pop rdx
	pop rcx
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



done:
	mov rax, 60							;sys_exit (code 60)
	mov rdi, 	0								;exit_code (code 0 successful)
	syscall
	
ClrScr:
	push rsi
	push rdx

	mov rsi, ClearTerm 		; Pass offset of terminal control string
	mov rdx, CLEARLEN 		; Pass the length of terminal control string
	call sys_write	

	pop rdx 			        ; Restore pertinent registers
	pop rsi
ret 				; Go home
	
Delay:
	push rax
	push rbx
	push rcx
	push r8
	push r10


	mov dword [tv_sec], 0		; Sleep n seconds
	mov dword [tv_usec], 200*1000000		;Sleep n nanoseconds 500*1000000 = 500 miliseg
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
	mov cx, word [Digits + rbx * 2] 	; Fetch decimal digits to CX
	mov word [PosTerm + 2], cx 	; Poke digits into control string

	; Poke the X digits:
	mov bl, ah 			; Put X value into scale term EBX
	mov cx, word [Digits + rbx * 2] 	; Fetch decimal digits to CX
	mov word [PosTerm + 5], cx 	; Poke digits into control string

	; Send control sequence to stdout:
	mov rsi, PosTerm 		; Pass address of the control string
	mov rdx, POSLEN 			; Pass the length of the control string
	call sys_write	 
	
	; Wrap up and go home:
	pop rdx    			; Restore callers registers
	pop rsi
	pop rcx 
	pop rbx 
	pop rax
ret 				; Go home
	
AnimarRotor:
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
ret

animarFlechasU:
    call GetPosRotorActual
	dec al											;se corre una posicon hacia arriba
	dec ah											;se corre una posicon hacia la izq
	call GotoXY
	lea rsi, [PatternAnimRotorU+r8]	;address of the buffer to print out	;dependiendo si r8 es 0 o 1 se crea el efecto de animacion
	mov rdx, 28								;number of chars to print out
	call sys_write		
ret

animarFlechasD:
    call GetPosRotorActual
	dec ah											;se corre una posicon hacia atras
	inc al											;se corre una posicon hacia abajo
	call GotoXY
	lea rsi, [PatternAnimRotorD+r8]	;address of the buffer to print out ;dependiendo si r8 es 0 o 1 se crea el efecto de animacion
	mov rdx, 28								;number of chars to print out
	call sys_write			
ret

sys_write:
	push rax
	push rdi 
	
	mov rax, 1								;sys_write (code 1)
	mov rdi, 1								;file_descriptor (code 1 stdout)
	syscall										;system call
	
	pop rdi
	pop rax
ret

GetPosRotorActual:
	mov ah, 5					; POS X = 5 espacios desde la pos inicial
	
	mov al, r10b			; POS Y
	shl al, 2
	add al, 3					;POS Y = pos rotor * 2 + 4
ret
	
	
printDebbug:
	push rcx
	push rsi
	push rdx
	
	mov rsi, debbug				;address of the buffer to print out
	mov rdx, 1				;number of chars to print out
	call sys_write
	
	pop rdx
	pop rsi
	pop rcx
ret

PrintRotor:
	push rcx
	push rdx
	push rsi
	
	cmp rcx, 25									; lama a la animacion de mover letra si la letra no esta en la ultima posicion
		ja .continuar
		call animarPrimeraLetraRotor ;else
	
	.continuar

	call GetPosRotorActual
	call GotoXY

	mov rsi, rsi									;address of the buffer to print out
	mov rdx, 27								;number of chars to print out
	call sys_write
	
	pop rsi
	pop rdx
	pop rcx
ret