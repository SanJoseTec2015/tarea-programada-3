
;PROCEDIMIENTO PRINCIPAL DEL PLUGBOARD
;RECIBE EL ARCHIVO DE CONFIG EN CONFIG 
;recibe r9b byte a modificar

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
         cmp byte[rbx+rcx],32 ;COMA
         jnz ciclo2
         add rbx,rcx 
         inc rbx 
         mov [plug] ,rbx
         cmp byte[rbx+rcx],0
         jnz ciclo      
       
ret

remplazoaux: 
     mov rbx , qword[plug]
     mov dl ,byte[rbx]  
     cmp r9b,dl
     jnz remplazoaux.con2
     inc rbx
     mov dl , byte[rbx]
     mov r9b,dl
     jmp remplazoaux.salida
     .con2:
     inc rbx
     cmp r9b , byte[rbx]
     jnz remplazoaux.salida
     dec rbx
     mov r9b , byte[rbx]   
     .salida:
     ret

