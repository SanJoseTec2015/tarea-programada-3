section .bss 
    config resb 1024 ; 1 KB por Linea ; ARCHIVO DE CONFIGURACION DE LA ENIGMA
    plug resq 1;  ; Pointer to Config
section .data
    ;MensajeAEncriptar: db 'ESTO ES UNA PRUEBA BONITA' 
    ;times 1024-$+MensajeAEncriptar db 0
     
section .text 

global RemplazoPlugboard
extern MensajeAEncriptar

;PROCEDIMIENTO PRINCIPAL DEL PLUGBOARD
;RECIBE EL ARCHIVO DE CONFIGURACION EN EL BUFFER CONFIG 
;BUFFER MensajeAEncriptar , texto a modificar por el PLUGBOARD
RemplazoPlugboard:
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
          call RemplazoPlugboardAux
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

;funcion auxiliar utilizada por RemplazoPlugboard 
;remplaza el texto por el caracter
;utiliza el puntero plug  del tamaño de palabra de 64 bits
RemplazoPlugboardAux:
    mov rcx , 0
    .while:
     mov al, byte[MensajeAEncriptar+rcx] 
     inc rcx   
     mov rbx , [plug]
     cmp al,0
     jz salida
     cmp al,byte[rbx]
     jnz RemplazoPlugboardAux.while
     mov bl ,byte[rbx+1]
     mov byte[MensajeAEncriptar+rcx-1] , bl
     cmp al,0
     jnz RemplazoPlugboardAux.while  
     salida:
         xor rax,rax 
 ret


;global _start
;_start:
 ;   ;-------CARGA DEL BUFFER--------------------------
  ;  mov rdi ,0  ; STDIN
   ; mov rsi , config
    ;mov rdx , 1024
    ;syscall    
   ;;-----------------------------------------------
       
   ; call RemplazoPlugboard    

  ;------------IMPRIMIR 
       ;mov rax , 1
;       mov rdi,1
       ;mov rsi, MensajeAEncriptar
;       mov rdx, 1000 ; LARGO DEL BUFFER A IMPRIMIR 
       ;syscall
;
       ;mov rax,60
;       mov rdi,0
       ;syscall