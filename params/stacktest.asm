ARGS_AMOUNT equ 3                                   ; ARGS_AMOUNT will equate to 4 if extra points can be implemented
section .data
    ; Extracting information from main()
    argpt: times ARGS_AMOUNT dq 0x0000000000000000  ; Argument pointers table - char** argv
    arglt: times ARGS_AMOUNT db 0x00                ; Argument lenghts table  - char** argv
debug_byte: db 0x00
debug_qword: dq 0x0000000000000000

%macro push_debug_reg 0
    push rax
    push rdi
    push rsi
    push rdx
%endmacro
%macro pop_debug_reg 0
    pop rdx
    pop rsi
    pop rdi
    pop rax
%endmacro
%macro debug_reg_byte 1
    push_debug_reg
    mov [debug_byte], %1
    mov rax, 1      ; syscall write
    mov rdi, 1      ; file descriptor: stdout
    mov rsi, debug_byte
    mov rdx, 1
    syscall
    pop_debug_reg
%endmacro
%macro debug_reg_qword 1
    push_debug_reg
    mov [debug_qword], %1
    mov rax, 1      ; syscall write
    mov rdi, 1      ; file descriptor: stdout
    mov rsi, debug_qword
    mov rdx, 8
    syscall
    pop_debug_reg
%endmacro

section .text
global main
main:
_test:
    ;debug_reg_qword rbp    ; it is still empty even using gcc :(
    pop r15
    debug_reg_qword r15     ; Here we have printed argc

    pop r14                 ; get address of argument vector
    debug_reg_qword r14

    xor r8, r8              ; set an counter to loop around the arguments table
    .read_addresses:
        ; rcx is just a counter, 8 is a displacement on the table
        mov rdi, [r14 + r8 *8]      ; r14 is the address of argv
        debug_reg_qword rdi
        mov [argpt + r8 *8], rdi    ; copy the address back to the pointers table
        inc r8
        cmp r8, r15
        jnz .read_addresses         ; if not reached argc
ret
