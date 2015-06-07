ARGS_AMOUNT equ 3                   ; ARGS_AMOUNT will equate to 4 if extra points can be implemented
section .data
    ; Extracting information from main()
    return: dq 0
    argc: dq 0
    argv: dq 0
    argx: dq 0
    argpt: times ARGS_AMOUNT dq 0   ; Argument pointers table - char** argv
    arglt: times ARGS_AMOUNT db 0   ; Argument lenghts table  - char** argv

debug_byte: db 0
debug_qword: dq 0

section .text

global main
main:

_test:

    ; Finally found the proper documentation, at page 29.
    ; AMD64 Application Binary Interface System V specification
    ; Section 3.4 Process Initialization
    ; "Figure 3.9: Initial Process Stack"
    ; This order is used if only assembly will be used, and not libc

    ; Also taking most information from
    ; http://stackoverflow.com/questions/5842001/x86-64-elf-initial-stack-layout-when-calling-glibc
    ; http://stackoverflow.com/questions/28984009/how-to-accept-input-from-command-line-in-a-assembly-program-build-using-gcc-tool
    ; 

    ; Step 0: save return address from main.
    pop qword [return]

    ; Step 1: Obtain int argc
    pop qword [argc]
    
    ; Step 2: Obtain char** argv pointer, according to libc
    pop qword [argv]
    
    mov rax, [argc]
    xor rcx, rcx
    xor rsi, rsi
    _begin:
        cmp rcx, rax
        ja _return
        ; Get next parameter from argv, getting argv pointer according to libc
        mov rsi, [argv]
        mov rsi, [rsi + rcx*8]          ; Moving to rsi, the address of the paramater number rcx
        inc rcx
        ; Get next parameter from argv
        call my_str
        inc rcx
        jmp _begin
        
    _return:
    push qword [return]
    ret

my_str:
    push rdx
    push rcx
    push rax
    push rsi
    xor rcx, rcx
    xor rax, rax
    .find_null:
        mov al, [rsi+rcx]
        inc rcx
        cmp rax, 0
        jnz .find_null
    mov rax, 1      ; syscall write
    mov rdi, 1      ; file descriptor: stdout
    ; keep rsi from input
    mov rdx, rcx
    syscall
    pop rsi
    pop rax
    pop rcx
    pop rdx
    ret