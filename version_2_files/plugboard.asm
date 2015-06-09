section .text

global RemplazoPlugboard
extern plug, config_contenido


;PROCEDIMIENTO PRINCIPAL DEL PLUGBOARD
;RECIBE EL ARCHIVO DE config_contenido EN config_contenido 
;recibe r9b byte a modificar

RemplazoPlugboard:

	push rax
	push rbx
	push rcx
	push rdx

   xor rax , rax
   mov [plug], rax
   mov rcx,0
   mov rdx,2 ; 2 SALTOS DE LINEA
   while:
	   mov al , [config_contenido+rcx] 
	   inc rcx
	   cmp al , 10 ;SALTO DE LINEA
	   jnz while
	   dec rdx
	   cmp rdx , 0
	   jnz while
	   add rcx ,config_contenido
	   mov rax ,rcx
	   mov [plug] , rax
	   mov rbx , [plug]
	   mov bl ,[rbx]
			 
	   ciclo:
		  call RemplazoPlugboardaux
		  mov rcx, -1
	   ciclo2:  
		 inc rcx
		 mov rbx , [plug] ;POS MEMORIA
		 cmp byte[rbx+rcx],32 ;COMA
		 jnz ciclo2
		 add rbx,rcx 
		 inc rbx 
		 mov [plug] ,rbx
		 cmp byte[rbx+rcx],0
		 jnz ciclo      
	
	pop rdx
	pop rcx
	pop rbx
	pop rax
	   
ret

RemplazoPlugboardaux: 
	 mov rbx , qword[plug]
	 mov dl ,byte[rbx]  
	 cmp r9b,dl
	 jnz RemplazoPlugboardaux.con2
	 inc rbx
	 mov dl , byte[rbx]
	 mov r9b,dl
	 jmp RemplazoPlugboardaux.salida
	 .con2:
	 inc rbx
	 cmp r9b , byte[rbx]
	 jnz RemplazoPlugboardaux.salida
	 dec rbx
	 mov r9b , byte[rbx]   
	 .salida:
	 ret