;--------------------------------------------------------------------------------------------------------;
;						INSTITUTO TECNOLÓGICO DE COSTA RICA
;									TAREA PROGRAMADA 3
;										PROYECTO FINAL
;
;										MAQUINA ENIGMA
;
;							GERMAN VIVES
;							ISAAC CAMPOS MESEN 2014004626
;							ANDRES PENA CASTILLO 2014057250
;
;										I SEMESTRE 2015
;---------------------------------------------------------------------------------------------------------;
section .data

varRotor1 db 'EKMFLGDQVZNTOWYHXUSPAIBRCJ',0h
varRotor2 db 'AJDKSIRUXBLHWTMCQGZNPYFVOE',0h
varRotor3 db 'BDFHJLCPRTXVZNYEIWGAKMUSQO',0h
varRotor4 db 'ESOVPZJAYQUIRHXLNFTGKDCMWB',0h
varRotor5 db 'VZBRGITYUPSDNHLXAWMJQOFECK',0h
varReflector  db 'ZYXWVUTSRQPONMLKJIHGFEDCBA',0h
;varReflector  db 'JPGVOUMFYQBENHZRDKASXLICTW',0h

MensajeAEncriptar: db 'DYKRMNZGCN',0h
varMsjEncriptado: db '..........................',0h

ClearTerm: db 27,"[2J" 				; <ESC>[2J; clears display
CLEARLEN equ $-ClearTerm 			; Length of term clear string

; EXTERN_THIS parse_files
tabla_rotores dq varRotor1, varRotor2, varRotor3, varReflector, 0h

section .text
global _start

global MensajeAEncriptar, varMsjEncriptado, varRotor1, varRotor2, varRotor3, tabla_rotores
global sys_write
extern RecorrerBufferAEncriptar

_start:
	call ClrScr
	call RecorrerBufferAEncriptar
	done:
		mov rax, 60							;sys_exit (code 60)
		mov rdi, 0							;exit_code (code 0 successful)
		syscall

ClrScr:
	push rsi
	push rdx

	mov rsi, ClearTerm 		; Pass offset of terminal control string
	mov rdx, CLEARLEN 		; Pass the length of terminal control string
	call sys_write	

	pop rdx 			        ; Restore pertinent registers
	pop rsi
ret

sys_write:
	push rax
	push rdi 
	
	mov rax, 1								; sys_write (code 1)
	mov rdi, 1								; file_descriptor (code 1 stdout)
	syscall									
	
	pop rdi
	pop rax
ret