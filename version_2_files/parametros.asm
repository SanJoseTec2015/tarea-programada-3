ARGS_AMOUNT equ 3                   ; ARGS_AMOUNT will equate to 4 if extra points can be implemented
section .data
    ; Extracting information from main()
    argc: dq 0
    first_param : times 32 db 0x00
    secondparam : times 32 db 0x00

debug_qword: dq 0

section .text
global LEER_ARGUMENTOS, argc

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
        ja _done
        mov rdi, [rsi+rcx*8]    ; Get next *pointer* to next parameter
        inc rcx
        cmp rcx, 1
        jz .save_first
        cmp rcx, 2
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
    ; Print argument
    ;mov rsi, rdi    ; use address where parameter begins on stack
    ;mov rdx, rcx    ; use strlen
    ;call sys_write
    pop rsi
    pop rdi
    pop r14
    pop rax
    pop rcx
    pop rdx
    ret