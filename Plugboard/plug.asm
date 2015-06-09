section .bss 
    config resb 1024 ; 1 KB por Linea ; ARCHIVO DE CONFIGURACION DE LA ENIGMA
    plug resq 1;  ; Pointer to Config
section .data
    data: db 'ESTO ES UNA PRUEBA BONITA' 
    times 1024-$+data db 0
     
section .text 

;PROCEDIMIENTO PRINCIPAL DEL PLUGBOARD
;RECIBE EL ARCHIVO DE CONFIGURACION EN EL BUFFER CONFIG 
;BUFFER data , texto a modificar por el PLUGBOARD
remplazo:
   xor rax , rax
   mov [plug], rax
   mov rcx,0
   mov rdx,2 ; 2 SALTOS DE LINEA
   while:
       mov al , [config+rcx] 
       inc rcx
       cmp al , 10 ;SALTO DE LINEA
       jnz while
       dec rdx
       cmp rdx , 0
       jnz while
       add rcx ,config
       mov rax ,rcx
       mov [plug] , rax
       mov rbx , [plug]
       mov bl ,[rbx]
       ciclo:
          call remplazoaux
          mov rcx, -1
       ciclo2:   
         inc rcx
         mov rbx , [plug] ;POS MEMORIA
         cmp byte[rbx+rcx],32 
         jnz ciclo2
         add rbx,rcx 
         inc rbx 
         mov [plug] ,rbx
         cmp byte[rbx+rcx],0
         jnz ciclo            
ret

;funcion auxiliar utilizada por remplazo 
;remplaza el texto por el caracter
;utiliza el puntero plug  del tamaño de palabra de 64 bits
remplazoaux:
    mov rcx , 0
    .while:
     mov al, byte[data+rcx] 
     inc rcx   
     mov rbx , [plug]
     cmp al,0
     jz salida
     cmp al,byte[rbx]
     jnz remplazoaux.while
     mov bl ,byte[rbx+1]
     mov byte[data+rcx-1] , bl
     cmp al,0
     jnz remplazoaux.while  
     salida:
         xor rax,rax 
 ret


global _start
_start:
    ;-------CARGA DEL BUFFER--------------------------
    mov rdi ,0  ; STDIN
    mov rsi , config
    mov rdx , 1024
    syscall    
   ;-----------------------------------------------
       
    call remplazo    

  ;------------IMPRIMIR 
       mov rax , 1
       mov rdi,1
       mov rsi,data
       mov rdx, 1000 ; LARGO DEL BUFFER A IMPRIMIR 
       syscall

       mov rax,60
       mov rdi,0
       syscall

  
    
