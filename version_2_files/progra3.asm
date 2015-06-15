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
varMsjEncriptado: resb 1024

ClearTerm: db 27,"[2J" 				; <ESC>[2J; clears display
CLEARLEN equ $-ClearTerm 			; Length of term clear string

lista_rotores: dq varRotor1, varRotor2, varRotor3, varRotor4, varRotor5
tabla_rotores: dq 0, 0, 0, varReflector, 0h

debug_qword: dq 0

section .text
global _start

global MensajeAEncriptar, varMsjEncriptado, varRotor1, varRotor2, varRotor3, tabla_rotores
global settings_pointer, input_pointer
global sys_write, debug_qword_r15
extern RecorrerBufferAEncriptar, RomanosRotores, LEER_ARGUMENTOS, ABRIR_CONFIGURACION, ABRIR_ENTRADA
extern first_param, secondparam, selec_rotor, argc

_start:
	; HOWTO: read arguments from stack without libC:
	; Finally found the proper documentation, at page 29.
    ; AMD64 Application Binary Interface System V specification
    ; Section 3.4 Process Initialization
    ; "Figure 3.9: Initial Process Stack"
    ; This order is used if only assembly will be used.

    ; Step 0: back-up top of stack in base pointer, use rbp instead
    xor rbp, rbp
    mov rbp, rsp
    call LEER_ARGUMENTOS		; LEER_ARGUMENTOS descarta automáticamente argumentos extra
    
    call ABRIR_CONFIGURACION
    call ABRIR_ENTRADA
    
	;call RomanosRotores
	
	;mov r15, [selec_rotor]
	;call debug_qword_r15
	;mov r15, [selec_rotor+8]
	;call debug_qword_r15
	;mov r15, [selec_rotor+8]
	;call debug_qword_r15

	;call SeleccionarRotores
	;call ClrScr
	;call RecorrerBufferAEncriptar

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