ARGS_AMOUNT equ 3                   ; ARGS_AMOUNT will equate to 4 if extra points can be implemented
section .data
    ; Extracting information from main()
    argc: dq 0
    first_param : times 32 db 0x00
    secondparam : times 32 db 0x00

debug_qword: dq 0

settings_pointer: dq 0
input_pointer: dq 0
config_contenido : times 256 db 0x00
entrada_contenido : times 256 db 0x00

section .text
global LEER_ARGUMENTOS, ABRIR_CONFIGURACION, ABRIR_ENTRADA, config_contenido, entrada_contenido, argc
extern sys_write


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
        jmp .continue
        .save_first:
            lea r14, [first_param]
            call save_param_in_r14
            jmp .continue
        .save_second:
            lea r14, [secondparam]
            call save_param_in_r14
        .continue:
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
    ;push rax
    push rdi
    push rcx
    push rsi
    mov rax, 2      ; sys_open
    mov rdi, first_param
    xor rsi, rsi    ; read_only
    mov rdx, 0400o  ; permission to read for current user, and nobody else has permissions
    syscall
    cmp rax, 0
    jl .done 
    mov [settings_pointer], rax ; si la lectura no dio error guarde el resultado

    mov rax, 0                      ; read(
    mov rdi, [settings_pointer]     ;   file_descriptor,
    mov rsi, config_contenido       ;   *buf,
    mov rdx, 256                    ;   *bufsize
    syscall                         ; );

    mov rax, 6      ; sys_close
    mov rdi, [settings_pointer]
    syscall
    mov rax, 1
    .done:
    pop rsi
    pop rcx
    pop rdi
    ;pop rax
    ret

ABRIR_ENTRADA:
; Deja el resultado de abrir el archivo en rax
    ;push rax
    push rdi
    push rcx
    push rsi
    mov rax, 2      ; sys_open
    mov rdi, secondparam
    xor rsi, rsi    ; read_only
    mov rdx, 0400o  ; permission to read for current user, and nobody else has permissions
    syscall
    cmp rax, 0
    jl .done 
    mov [input_pointer], rax ; si la lectura no dio error guarde el resultado

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