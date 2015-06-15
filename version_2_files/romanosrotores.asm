section .data
test_buffer: db 'I,II,III,', 0x00
selec_rotor: dq 0, 0, 0
error_chars: db 'Se ha encontrado un caracter inválido o se ha excedido el valor requerido.', 10
error_charsLEN: equ $-error_chars

section .text
extern sys_write, debug_qword_r15
global selec_rotor, RomanosRotores

RomanosRotores:
; El buffer debe contener solamente la línea de los rotores
; seleccionados en el archivo.
; Se asume que no hay otros caracteres en este buffer,
; aparte de 'I', 'V', comas y el salto de línea.
; Entradas:
; rsi: buffer de entrada de los números romanos de los rotores
; Salidas:
; selec_rotor: se llena la tabla con los valores reales
; Devuelve:
; rsi: offset del último caracter, debería ser un salto de línea
	push r14
	push rbx
	push rax
	xor rsi, rsi
	xor r14, r14	; contador comas
	.ciclo:
		cmp r14, 3
		je NEAR .return

		;mov r15, r14
		;call debug_qword_r15
		;mov r15, 0xF0
		;call debug_qword_r15

		xor rax, rax	; char actual
		.encontrar_numero:
			mov al, [test_buffer+rsi]

			;mov r15, rax
			;call debug_qword_r15
			;mov r15, 0xF1
			;call debug_qword_r15

			; No incremente rsi hasta que encuentre que no hay error
			cmp al, 0x56		; look for 'V'
			jz .sume_cinco
		; Se asume que no hay otros caracteres inválidos
		; El ciclo empieza a sumar rbx=0
			xor rbx, rbx	; numero acum
		.sume_siguiente_char:
			cmp rbx, 3
			jz .siguiente_romano	; no se puede exceder de 3, III
			mov al, [test_buffer+rsi]

			;mov r15, rax
			;call debug_qword_r15
			;mov r15, 0xF2
			;call debug_qword_r15

			inc rsi
			cmp al, 0x56			; encontró 'V'
			jz .sume_tres
			cmp al, 0x49
			jnz .siguiente_romano	; siempre que AL sea 'I' sume uno

			inc rbx					; rbx++

			;mov r15, rbx
			;call debug_qword_r15
			;mov r15, 0xF4
			;call debug_qword_r15

			jmp .sume_siguiente_char

			; Lo que sigue después de 'I' fue 'V'
			; No puede haber leído algo como IIV ó IIIV, debe ser 'IV'
			.sume_tres:
				cmp rbx, 1		
				jnz .error
				add rbx, 3		; 1+3 = 4 jaja
				jmp .siguiente_romano

			.sume_cinco:
				xor rbx, rbx		; borre lo que sea que tuviese acumulado
				add rbx, 5
				inc rsi

		.siguiente_romano:
			mov al, [test_buffer+rsi]

			;mov r15, rax
			;call debug_qword_r15

			;mov r15, 0xF3
			;call debug_qword_r15
			
			inc rsi						; basta para saltarse la coma del test_buffer

			; Podría saltarse por ejemplo III(II) con tal de encontrar la coma
			cmp al, 0x2C
			jnz .siguiente_romano

			;mov r15, r14
			;call debug_qword_r15

			;mov r15, 0xF5
			;call debug_qword_r15

			; guarde el número encontrado en la tabla de bytes
			mov [selec_rotor+r14*8], rbx
			inc r14				; siga con la siguiente coma

			;mov r15, r14
			;call debug_qword_r15

			;mov r15, 0xF6
			;call debug_qword_r15

			cmp r14, 3
			jne .ciclo			; no ha terminado la tabla
			jmp .return			; ya llenó toda la tabla selec_rotor

	.error:
		push rdx
		push rsi
		mov rsi, error_chars
		mov rdx, error_charsLEN
		call sys_write
		pop rsi
		pop rdx

	.return:
	pop rax
	pop rbx
	pop r14
	ret