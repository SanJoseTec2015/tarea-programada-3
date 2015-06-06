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

lenLetras	equ 26

salida: db " RESULTADO = "
salidaLEN equ $ - salida

varRotor1: db 'AJDKSIRUXBLHWTMCQGZNPYFVOE',10
varRotor2: db 'BDFHJLCPRTXVZNYEIWGAKMUSQO',10
varRotor3: db 'VZBRGITYUPSDNHLXAWMJQOFECK',10
varMsjEncriptado: db '..........................',10


;--------------------------------------------------- ESCAPE CODES
ClearTerm: db 27,"[2J" 				; <ESC>[2J; clears display
CLEARLEN equ $-ClearTerm 			; Length of term clear string
;--------------------------------------------------- /ESCAPE CODES


;--------------------------------------------------- SLEEP

  timeval:
    tv_sec  dd 0
    tv_usec dd 0
	
;--------------------------------------------------- /SLEEP


;

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


	mov rsi, varRotor1

mov ecx, 26
call PrintRotor1
		call ClrScr

ciclo:
	call GirarRotor
	call PrintRotor1
loop ciclo

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
	sub al, "A"						;se resta A para obtener el indice del entrada
	mov al, byte[rsi+rax]
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
	
	mov r8b, [rsi]						;se guarda temporalmente la primer primer letra del rotor
	xor rcx, rcx			
	.nextChar:

		mov al, byte [rsi + rcx + 1] 	;se guarda el siguiente char en al > RSI rotor, RCX indice, 1 = siguiente char
		mov byte [rsi + rcx+1 ], " "	;se mueve un caracter vacio en la posicion donde
		
		call Delay
		call ClrScr
		call PrintRotor1


		mov [rsi + rcx], al					;se mueve el siguiente char a la posicion actual
		inc rcx										;indice

		cmp rcx, 25			;si no ha llegado al final continua con el siguiente char/byte
			jnz .nextChar

	mov byte [rsi + rcx], r8b				;movemos al final del rotor la primera letra
	
	pop r8
	pop rcx
	pop rax
ret

;------------------------------------------------------------------------------------------------------------
; AddCharVarMsjEncriptado
;
; El procedimiento usa el registro R15 como indice global para el msj
; que se va a encriptar, inserta la letra al final del texto y deja en R15
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
	push rcx
	push rdx
	push rsi
	push rdi

	mov byte[varMsjEncriptado+r15], 10	;agregamos un cambio de linea
	inc r15

	mov rax, 1								;sys_write (code 1)
	mov rdi, 1								;file_descriptor (code 1 stdout)
	mov rsi, varMsjEncriptado				;address of the buffer to print out
	mov rdx, r15								;number of chars to print out
	syscall										;system call

	dec r15
	mov byte[varMsjEncriptado+r15], 0h	;volvemos a insertar el caracter null al final

	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rax
ret

PrintRotor1:
	push rax
	push rcx
	push rdx
	push rsi
	push rdi

	mov byte[varRotor1+26], 10	;agregamos un cambio de linea

	mov rax, 1								;sys_write (code 1)
	mov rdi, 1								;file_descriptor (code 1 stdout)
	mov rsi, varRotor1				;address of the buffer to print out
	mov rdx, 27								;number of chars to print out
	syscall										;system call

	mov byte[varRotor1+26], 0h	;volvemos a insertar el caracter null al final

	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rax
ret

done:
	mov rax, 60							;sys_exit (code 60)
	mov rdi, 	0								;exit_code (code 0 successful)
	syscall
	
ClrScr:
	push rax 			; Save pertinent registers
	push rdi
	push rsi
	push rdx

	mov rax, 1 			; sys_write (code 1)
	mov rdi, 1 			; file_descriptor (code 1 stdout)
	mov rsi, ClearTerm 		; Pass offset of terminal control string
	mov rdx, CLEARLEN 		; Pass the length of terminal control string
	syscall     			

	pop rdx 			        ; Restore pertinent registers
	pop rsi
	pop rdi
	pop rax
ret 				; Go home
	
Delay:
	push rax
	push rbx
	push rcx


	mov dword [tv_sec], 1		; Sleep n seconds
	mov dword [tv_usec], 0		;Sleep 0 nanoseconds
	mov rax, 162
	mov rbx, timeval
	mov rcx, 0
	int 0x80
	
	pop rcx
	pop rbx
	pop rax
ret
