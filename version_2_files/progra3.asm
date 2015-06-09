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
lista_rotores dq varRotor1, varRotor2, varRotor3, varRotor4, varRotor5
tabla_rotores dq 0, 0, 0, varReflector, 0h

debug_qword: dq 0

section .text
global _start

global MensajeAEncriptar, varMsjEncriptado, varRotor1, varRotor2, varRotor3, tabla_rotores
global sys_write
extern RecorrerBufferAEncriptar, selec_rotor, RomanosRotores

_start:
	call RomanosRotores
	call SeleccionarRotores
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
	push rcx 	; IMPORTANTE: el sys_write y otros syscalls modifican rcx
				; Experiencia personal :P
	mov rax, 1								; sys_write (code 1)
	mov rdi, 1								; file_descriptor (code 1 stdout)
	syscall

	pop rcx
	pop rdi
	pop rax
ret

SeleccionarRotores:
	push r15
	push r14
	push r13
	push r12
	xor r15, r15 ; indice dentro de lista_rotores
	xor r14, r14 ; indice dentro de tabla_rotores
	xor r13, r13 ; indice dentro de selec_rotor

	.begin:
		lea rsi, [lista_rotores]
		lea rdi, [tabla_rotores]
		.ciclo:
			xor r12, r12					; contiene la dirección a guardar en tabla_rotores
			cmp r13, 3
			jz .return
			mov r15, [selec_rotor+r13*8]	; seleccione el rotor en lista_rotores
			dec r15							; -1 porque el número empieza en 1 en el archivo
			mov r12, [lista_rotores+r15*8]  ; *8 es la escala, son 8 bytes
											
			mov [tabla_rotores+r14*8], r12
			inc r14
			inc r13
			jmp .ciclo
	.return:

	mov r15, [lista_rotores]
	call debug_qword_r15
	mov r15, [lista_rotores+8]
	call debug_qword_r15
	mov r15, [lista_rotores+16]
	call debug_qword_r15
	mov r15, [lista_rotores+24]
	call debug_qword_r15
	mov r15, [lista_rotores+32]
	call debug_qword_r15
	xor r15, r15
	call debug_qword_r15
	mov r15, [tabla_rotores]
	call debug_qword_r15
	mov r15, [tabla_rotores+8]
	call debug_qword_r15
	mov r15, [tabla_rotores+16]
	call debug_qword_r15
	pop r12
	pop r13
	pop r14
	pop r15
	ret

debug_qword_r15:
	push rsi
	push rdx
	mov [debug_qword], r15
	mov rsi, debug_qword
	mov rdx, 8
	call sys_write
	pop rdx
	pop rsi
	ret