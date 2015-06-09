; =============================================================================== CICLO PRINCIPAL

; section .data
; entrada:
; db '------------------------------------------------------------', 10,10,\
; '              INSTITUTO TECNOLOGICO DE COSTA RICA', 10,\
; '                      TAREA PROGRAMADA 3', 10,\
; '                        I SEMESTRE 2015', 10,10,\
; '                        MAQUINA  ENIGMA', 10, 10, 10\
; '                    ISAAC CAMPOS MESEN 2014004626', 10,\
; '                  ANDRES PENA CASTILLO 2014057250', 10,\
; '                          GERMAN VIVES', 10, 10,\
; '------------------------------------------------------------',10, 10, ' ENTRADA = '
; entradaLEN	equ $ - entrada

section .text

extern MensajeAEncriptar, PrintRotor, AnimarRotor, AnimarEntradaRotores, AnimarSalidaRotores
extern Delay, limpiarLetraAnteriorMovida, tabla_rotores, varMsjEncriptado, primeraLetraRotor, 
extern PrintMsjEncriptado, GotoXY

global RecorrerBufferAEncriptar, AddCharVarMsjEncriptado

RecorrerBufferAEncriptar:
xor rcx, rcx
	.siguienteLetra
		mov al, byte[MensajeAEncriptar + rcx]
		call EncriptarLetra
		inc rcx
		cmp byte[MensajeAEncriptar + rcx], 0h
			jnz .siguienteLetra
			
	;cuando termina de encriptar la ultima letra, manda el cursor al lado inferior de la pantalla
	mov ax, 0426h 			; X,Y = 28,05 as a single hex value in AX
	call GotoXY 					; Position the cursor
ret

EncriptarLetra:
	push rcx

	; Ciclo para imprimir los rotores
	xor r10, r10
	.PrintSiguienteRotor						
		mov rsi, [tabla_rotores + r10 * 8]		;le pasamos a rsi la direccion del buffer del rotor			
		call PrintRotor										;imprime el rotor
		call AnimarRotor									;imprime la primera vez las flechas
		inc r10												;next rotor
		cmp qword[tabla_rotores + r10 * 8], 0h		;la cantidad de rotores	+ 1 reflector	
			jnz .PrintSiguienteRotor
	
	; Ciclo para obtener las letras encriptadas que entran
	xor r10, r10

	; FIXME: Aquí debe llamarse al plugboard a sustituir

	.siguienteRotorEntrada						
		mov rsi, [tabla_rotores + r10 * 8]
		; obtiene la letra del rotor actual
		call GetLetraRotorEntrando				;recibe la letra en RAX, y deja la salida en RAX
		
		inc r10									;next rotor
		cmp qword[tabla_rotores + r10 * 8], 0h		;la cantidad de rotores + 1 reflector
			jnz .siguienteRotorEntrada
		
	; FIXME: Aquí se agrega el reflector
	; ACLARAR.... EN LA TABLA DE ROTORES <tabla_rotores> SE PONE EN LA ULTIMA POSICION EL REFLECTOR...
	; ESTE EN EL CICLO ANTERIOR ESTA OBTENIENDO UN RESULTADO.... (COMO DEBE SER), por lo tanto no es necesario
	; agregar nada extra.
	
	sub r10, 2									;le restamos las posicion del indice 'muerto' (el ultimo del indice (4)) y le restamos el reflector

	; AHORA OBTENEMOS EL RESULTADO DE VUELTA EN CADA ROTOR... PERO EL REFLECTOR LO ESTAMOS SALTANDO
	
		; Ciclo para obtener las letras encriptadas que entran
		.siguienteRotorSalida					
			mov rsi, [tabla_rotores + r10 * 8]
			; obtiene la letra del rotor actual
			call GetLetraRotorSaliendo				;recibe la letra en RAX, y deja la salida en RAX
			dec r10											;next rotor
				jns .siguienteRotorSalida				;si es mayor a 0 siga con el siguiente

		; FIXME: Aquí debe llamarse al plugboard a sustituir
		call AddCharVarMsjEncriptado				;mueve al buffer de msj encriptado la letra y aumenta su indice en r15
		call Delay

		xor r10, r10
		call GirarRotor								;gira el rotor rsi en la posicion r10
		
		pop rcx
ret

; ======================================================================================== FUNCIONAMIENTO INTERNO

; Las entradas y salidas son el mismo registro RAX, cualquier otro registro se preservan
GetLetraRotorEntrando:
	call AnimarEntradaRotores				;imprime los '#' en las posiciones de entrada
	sub rax, "A"						;se resta A para obtener el indice del entrada
	mov al, byte[rsi+rax]
ret

GetLetraRotorSaliendo:
	call AnimarSalidaRotores
	push rcx
	push rbx

	mov rcx, 27						;iniciamos en la ultma posicion del rotor
	
	.buscarLetra
		dec rcx
		;js si es menor a 0 LANZAR ERROR 
		mov bl, byte[rsi + rcx]
		cmp al, bl					;si la letra del rotor conicide con la letra a buscar salimos
			jnz .buscarLetra
		
		mov rax, rcx
		add rax, 'A'				;le sumamos A al indice para obtener la letra correspondiente

	pop rbx
	pop rcx
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
	call PrintMsjEncriptado
ret

;------------------------------------------------------------------------------------------------------------
; GirarRotor
;
; El procedimiento recibe en el RSI el rotor que se quiere girar 1 pos
;
; E: RSI la direccion del buffer del rotor
; M: nada
;------------------------------------------------------------------------------------------------------------
GirarRotor:
	push rax
	push rcx
	push r8
	push rsi
	
	mov r8b, [rsi]							; se guarda temporalmente la primer primer primeraLetraRotor del rotor
	mov [primeraLetraRotor], r8b
	xor rcx, rcx			
	.nextChar:
		mov al, byte [rsi + rcx + 1] 		; se guarda el siguiente char en al > RSI rotor, RCX indice, 1 = siguiente char

		mov [rsi + rcx], al					; se mueve el siguiente char a la posicion actual
		inc rcx								; indice
		
		mov byte [rsi + rcx], " "			; se mueve un caracter vacio en la posicion donde
		
		call PrintRotor
		call Delay

		cmp rcx, 25							; si no ha llegado al final continua con el siguiente char/byte
			jnz .nextChar
	mov [rsi + rcx ], r8b					; movemos al final del rotor la primera primeraLetraRotor
	inc rcx									; se incrementa el indice para borrar el caracter movido anterior
	call limpiarLetraAnteriorMovida
	call PrintRotor

	pop rsi
	pop r8
	pop rcx
	pop rax
ret