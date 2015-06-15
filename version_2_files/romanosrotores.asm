section .data
test_buffer: db 'I,II,III,', 0x00
selec_rotor: dq 0, 0, 0
error_chars: db 'Se ha encontrado un caracter no permitido.', 10
error_charsLEN: equ $-error_chars

section .text
extern entrada_contenido, sys_write, debug_qword_r15
global selec_rotor, RomanosRotores

RomanosRotores:
; El buffer debe contener solamente la línea de los rotores seleccionados en el archivo.
; Si hay otros caracteres que no sean 'I' o 'V' simplemente emite un error.
; Salida: selec_rotor se llena la tabla con los valores reales.
	push rax
	push rcx
	push rsi
	push rdi
	xor rsi, rsi		; index for entrada_contenido
	xor rdi, rdi		; index for selec_rotor
	xor rcx, rcx		; counter of number from romans
	xor rax, rax		; current char
	.scan:
		.first_char:
			mov al, [entrada_contenido+rsi]
			cmp al, 'V'
			jz .case_5
			cmp al, 'I'
			jz .case_1
			jmp .error
				.case_5:
					add rcx, 5		; rcx = 0; rcx += 5 -> rcx=5
					inc rsi
					jmp .check_comma
				.case_1:
					inc rcx			; rcx = 0; rcx += 1 -> rcx=1
					inc rsi
					;jmp .second_char
		.second_char:
			mov al, [entrada_contenido+rsi]
			cmp al, 'V'
			jz .case_4
			cmp al, 'I'
			jz .case_2
			jmp .error
				.case_4:
					add rcx, 3		; rcx = 1; rcx += 3 -> rcx=4
					inc rsi
					jmp .check_comma
				.case_2:
					inc rcx			; rcx = 1; rcx += 1 -> rcx=2
					inc rsi
					;jmp .third_char
		.third_char:
			mov al, [entrada_contenido+rsi]
			cmp al, 'I'
			jz .case_3
			jmp .error
				.case_3:
					inc rcx
					inc rsi
					jmp .check_comma
		.check_comma:
			mov al, [entrada_contenido+rsi]
			inc rsi
			cmp al, ','
			jnz .check_linefeed
			; Aún no sabemos si hay la suficiente cantidad de comas:
			cmp rdi, 4
			jz  .error	; se ha excedido

		.store:
			mov [selec_rotor+rdi*8], rcx
			xor rcx, rcx
			inc rdi
			jmp .scan

		.check_linefeed:
			cmp al, 0x0A
			jnz .error
			; Aún hay que verificar que no haya encontrado el salto
			; de línea inesperadamente:
			cmp rdi, 4
			jz .return	; sólo si ya leyó las comas necesarias

	.error:
		mov rsi, error_chars
		mov rdx, error_charsLEN
		call sys_write
		mov rax, 60							;sys_exit (code 60)
		mov rdi, 0							;exit_code (code 0 successful)
		syscall

	.return:
	pop rax
	pop rbx
	pop r14
	ret