section .data
test_buffer: db 'IIIII,IV,V', 10
selec_rotor: dq 0, 0, 0
error_chars: db 'Se ha encontrado un caracter inválido o se ha excedido el valor requerido.', 10
error_charsLEN: equ $-error_chars

testmsg: db 'test', 10
testmsgLEN equ $-testmsg

debug_qword: dq 0
section .text
;extern sys_write
global _start

sys_write:
	push rax
	push rdi 
	
	mov rax, 1								; sys_write (code 1)
	mov rdi, 1								; file_descriptor (code 1 stdout)
	syscall									
	
	pop rdi
	pop rax
ret

_start:
	mov rsi, test_buffer

	call SeleccionarRotores
	
	push rsi
	push rdx
	mov rsi, testmsg
	mov [debug_qword], rsi
	mov rsi, debug_qword
	mov rdx, 8
	call sys_write
	pop rdx
	pop rsi

	_exit:
	 	mov rax, 60							;sys_exit (code 60)
	 	mov rdi, 0							;exit_code (code 0 successful)
	 	syscall

; StrLengthLineFeed:
; 	push rsi
; 	.ciclo:
; 		mov al, [rsi]
; 		inc rsi
; 		cmp al, 0x0A
; 		jnz .ciclo
; 	mov rax, [rsp+8]						; obtenga el valor original de rsi de aquí mismo en la pila
; 	sub rsi, rax							; offset final - offset inicial deja el tamaño en rsi
; 	xchg rax, rsi							; mande el tamaño al rax
; 	pop rsi
; 	ret


SeleccionarRotores:
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
	enter 8, 0
	push rcx
	push rbx
	push rax
	xor rcx, rcx	; contador comas
	.ciclo:
		cmp rcx, 3
		je NEAR .return
		xor rax, rax	; char actual
		xor rbx, rbx	; numero acum
		.encontrar_numero:
			mov al, [rsi]
			; No incremente rsi hasta que encuentre que no hay error
			cmp al, 0x56		; look for 'V'
			jz .sume_cinco
		; Se asume que no hay otros caracteres inválidos
		; El ciclo empieza a sumar rbx=0
		.sume_siguiente_char:
			cmp rbx, 3
			jz .siguiente_romano	; no se puede exceder de 3, III
			mov al, [rsi]
			inc rsi
			cmp al, 0x56			; encontró 'V'
			jz .sume_tres
			cmp al, 0x49
			jnz .siguiente_romano	; siempre que AL sea 'I' sume uno

			inc rbx					; rbx++
			jmp .sume_siguiente_char

			; Lo que sigue después de 'I' fue 'V'
			; No puede haber leído algo como IIV ó IIIV, debe ser 'IV'
			.sume_tres:
				cmp rbx, 1		
				jnz .error
				add rbx, 3		; 1+3 = 4 jaja
				jmp .siguiente_romano

			.sume_cinco:
				add rbx, 5
				inc rsi

		.siguiente_romano:
			mov al, [rsi]
			inc rsi

			; si no encuentra salto de línea, lo que debe seguir es una coma
			cmp al, 0x0A
			jz .final_o_no
			; Podría saltarse por ejemplo III(II) con tal de encontrar la coma
			cmp al, 0x2C
			jnz .siguiente_romano

			; guarde el número encontrado en la tabla de bytes
			mov [selec_rotor+rcx*8], rbx
			inc rcx				; siga con la siguiente coma

		.final_o_no:

			push rsi
			push rdx
			mov [debug_qword], rcx
			mov rsi, debug_qword
			mov rdx, 8
			call sys_write
			pop rdx
			pop rsi

			cmp rcx, 3
			jne NEAR .ciclo			; no ha terminado la tabla
			jmp SHORT .return			; ya llenó toda la tabla selec_rotor

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
	pop rcx
	leave
	ret