%include "io.inc"
section .bss 
    config resb 1024 ; 1 KB por Linea ; ARCHIVO DE CONFIGURACION DE LA ENIGMA
    plug resq 1;  ; Pointer to Config
section .data
    data db 'ESTO ES UNA PRUEBA BONITA',0
   
    
section .text 

remplazo:
    mov rcx , 0
    .while:
     mov al, byte[data+rcx] 
     inc rcx   
     mov rbx , [plug]
     cmp al,0
     jz salida
     cmp al,byte[rbx]
     jnz remplazo.while
     mov bl ,byte[rbx+1]
     mov byte[data+rcx-1] , bl
     cmp al,0
     jnz remplazo.while  
     
     salida:
         xor rax,rax 
          
  ret
;PROCEDIMIENTO PRINCIPAL DEL PLUGBOARD
;RECIBE EL ARCHIVO DE CONFIG EN CONFIG 
;DATA BUFFER A MODIFICAR 
remp:
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
          call remplazo 
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

global CMAIN
CMAIN:
    mov rbp, rsp; for correct debugging
    ; --DEPURACION PARA SASM ---------  
    mov rbp, rsp; for correct debugging
    xor rax, rax
    ;-------CARGA DEL BUFFER--------------------------
    mov rdi ,0  ; STDIN
    mov rsi , config
    mov rdx , 1024
    syscall    
   ;-----------------------------------------------
       
         call remp  ;
         
       ;------------IMPRIMIR 
       mov rax , 1
       mov rdi,1
       mov rsi,data
       mov rdx,1024
       syscall
    ret
    
    