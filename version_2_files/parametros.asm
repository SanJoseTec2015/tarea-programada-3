ARGS_AMOUNT equ 3                   ; ARGS_AMOUNT will equate to 4 if extra points can be implemented

; Operating System I/O Constants for x86_64
O_RDONLY equ 000000q    ; file is read - only
O_WRONLY equ 000001q    ; file is write - only
O_RDWR   equ 000002q    ; read or write
O_CREAT  equ 000100q    ; create file or erase it

S_IRUSR  equ 00400q     ; user permission to read
S_IWUSR  equ 00200q     ; to write
S_IXUSR  equ 00100q     ; to execute
; ==============================================

section .data
    ; Extracting information from main()
    argc: dq 0
    first_param : times 32 db 0x00
    secondparam : times 32 db 0x00

settings_pointer: dq 0
input_pointer: dq 0
config_contenido : times 256 db 0x00
entrada_contenido : times 256 db 0x00

msg_error_insufficent_args: db 'Argumentos insuficientes, se requiren al menos 2 argumentos.', 10
msg_error_insufficent_argsLEN equ $-msg_error_insufficent_args
msg_error_failed_first_arg: db 'Fallo al intentar abrir el archivo de configuracion.', 10
msg_error_failed_first_argLEN equ $-msg_error_failed_first_arg
msg_error_failed_secondarg: db 'Fallo al intentar abrir el archivo de entrada por encriptar.', 10
msg_error_failed_secondargLEN equ $-msg_error_failed_secondarg

section .text
global LEER_ARGUMENTOS, ABRIR_CONFIGURACION, ABRIR_ENTRADA, config_contenido, entrada_contenido, argc
extern sys_write, debug_qword_r15


LEER_ARGUMENTOS:
; Receives top of stack as parameter on RBP (base pointer)
; Stores argument count on memory in [argc], only output.
; Preserves all the registers.
    push rax
    push rcx
    push rdi
    push rsi
    push r14
    
    ; Step 1: Obtain argument count
    mov rax, [rbp]
    cmp rax, 3         ; Si no tiene al menos 2 argumentos (aparte del nombre del ejecutable)
    jb _error_insufficent_args
    mov qword [argc], rax
    ; Step 2: Scan stack parameters
    xor rcx, rcx
    xor rsi, rsi
    lea rsi, [rbp+8]            ; Begin from first pointer of first parameter

    _begin:
        cmp rcx, qword [argc]
        jg _done
        mov rdi, [rsi+rcx*8]    ; Get next *pointer* to next parameter
        inc rcx
        cmp rcx, 2              ; select second parameter, discard filename
        jz .save_first
        cmp rcx, 3              ; select third parameter, discard filename
        jz .save_second
        jmp _begin

        .save_first:
            lea r14, [first_param]
            jmp .save_current_param
        .save_second:
            lea r14, [secondparam]

        .save_current_param
            call save_param_in_r14
            jmp _begin

    _done:
    pop r14
    pop rsi
    pop rdi
    pop rcx
    pop rax
    ret

save_param_in_r14:
; Receives pointer of argument beggining in rdi
; Receives pointer of destination buffer in r14
    push rdx
    push rcx
    push rax
    push r14
    push rdi
    push rsi
    xor rcx, rcx
    xor rax, rax
    .find_null:
        mov al, [rdi+rcx]
        mov [r14+rcx], al
        inc rcx
        cmp rax, 0
        jnz .find_null
    pop rsi
    pop rdi
    pop r14
    pop rax
    pop rcx
    pop rdx
    ret

ABRIR_CONFIGURACION:
; Deja el resultado de abrir el archivo en rax
; Finalmente encontré documentación en
; http://cs.smith.edu/dftwiki/images/e/e3/CSC231_File_IO_In_Assembly.pdf
; Adaptado a syscalls para x86_64 según
; http://blog.rchapman.org/post/36801038863/linux-system-call-table-for-x86-64

    push rax
    push rdi
    push rcx
    push rsi
    
    mov rax, 2                      ; sys_open
    mov rdi, first_param
    mov rsi, O_RDONLY
    mov rdx, S_IRUSR                ; permission to read for current user, and nobody else has permissions
    syscall

    ; According to http://man7.org/linux/man-pages/man2/open.2.html
    ; when syscall open() fails, errno constant is properly set.
    ; Documentation of open() available on http://lxr.free-electrons.com/source/fs/open.c
    ; Errno constant is defined on the operating system inside file /usr/include/asm/errno.h
    ; (On my computer this takes me to /usr/include/asm-generic/errno.h and ./errno-base.h)

    test rax, rax
    js _error_first_arg

    .continue:
    mov [settings_pointer], rax     ; si la lectura no dio error guarde el resultado
    mov rax, 0                      ; read(
    mov rdi, [settings_pointer]     ;   file_descriptor,
    mov rsi, config_contenido       ;   *buf,
    mov rdx, 256                    ;   *bufsize
    syscall                         ; );

    ;mov rdi, config_contenido
    ;call debug_content_buffer

    mov rax, 6                      ; sys_close
    mov rdi, [settings_pointer]
    syscall

    .done:
    pop rsi
    pop rcx
    pop rdi
    pop rax
    ret

ABRIR_ENTRADA:
; Deja el resultado de abrir el archivo en rax
    ;push rax
    push rdi
    push rcx
    push rsi
    mov rax, 2                      ; sys_open
    mov rdi, secondparam
    mov rsi, O_RDONLY               ; read only
    mov rdx, S_IRUSR                ; permission to read for current user, and nobody else has permissions
    syscall
    
    test rax, rax
    js _error_second_arg

    .continue:
    mov [input_pointer], rax        ; si la lectura no dio error guarde el resultado
    mov rax, 0                      ; read(
    mov rdi, [input_pointer]        ;   file_descriptor,
    mov rsi, entrada_contenido      ;   *buf,
    mov rdx, 256                    ;   *bufsize
    syscall                         ; );

    mov rax, 6      ; sys_close
    mov rdi, [input_pointer]
    syscall
    mov rax, 1
    .done:
    pop rsi
    pop rcx
    pop rdi
    ;pop rax
    ret

_error_insufficent_args:
    mov rsi, msg_error_insufficent_args
    mov rdx, msg_error_insufficent_argsLEN
    jmp _error_args
_error_first_arg:
    mov rsi, msg_error_failed_first_arg
    mov rdx, msg_error_failed_first_argLEN
    jmp _error_args
_error_second_arg:
    mov rsi, msg_error_failed_secondarg
    mov rdx, msg_error_failed_secondargLEN

_error_args:
    call sys_write
    mov rax, 60                         ;sys_exit (code 60)
    mov rdi, 1                          ;exit_code (code  successful)
    syscall

debug_content_buffer:
; Receives content buffer on RDI as origin register,
; according to Intel Architecture Manuals Volume 2B, page 4-348 (350 on PDF).
; Quick reference on REPNE SCASB: http://www.int80h.org/strlen/
    pushf
    push rcx
    push rax
    push rsi
    push rdx
    xor rcx, rcx
    not rcx                         ; set rcx to highest possible unsigned 64 bits value
    xor al, al
    cld
    repne scasb                     ; looking for NUL char. After finding NUL, rcx was also decremented,
    not rcx                         ; therefore ECX = (-strlen - 2) or strlen + 2
    dec rcx                         ; this approach takes advantage of two's compliment design.
    ; ECX now contains the length of the string, not counting the terminating NUL.
    mov rsi, rdi
    mov rdx, rcx
    call sys_write
    pop rdx
    pop rsi
    pop rax
    pop rcx
    popf
    ret