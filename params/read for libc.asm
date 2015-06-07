ARGS_AMOUNT equ 3									; ARGS_AMOUNT will equate to 4 if extra points can be implemented
section .data
	; Extracting information from main()
	argpt: times ARGS_AMOUNT dq 0x0000000000000000	; Argument pointers table - char** argv
	arglt: times ARGS_AMOUNT db 0x00				; Argument lenghts table  - char** argv
	current_char: db 0x00
	debug_current_char: db 0x00
	; Filenames must be shorter than 64 bytes, including extension
	enigma_settings_filename: times 256 db 0x00
	enigma_input_filename:	  times 256 db 0x00
	;enigma_rotors_filename:	  times 256 db 0x00

	error_max_args: db 'Exceeded maximum supported arguments.', 0x10
	error_no_args: db 'Not enough arguments were provided to this program.', 0x10
; =============================================== DEBUGGING
%macro debug_register 1
    push rdx
    push rsi
    push rdi
    push rax
    mov [debug_current_char], %1
    mov rax, 1      ; syscall write
    mov rdi, 1      ; file descriptor: stdout
    mov rsi, debug_current_char
    mov rdx, 8
    syscall
    pop rax
    pop rdi
    pop rsi
    pop rdx
%endmacro
; =============================================== DEBUGGING
section .text
global _start
global GET_ARGS_FROM_STACK
global RETRIEVE_FILENAMES
global enigma_settings_filename
global enigma_input_filename

main:
	call GET_ARGS_FROM_STACK
	call RETRIEVE_FILENAMES
	mov rsi, enigma_settings_filename
    xor rax, rax    ; current char from unknown buffer
    xor rdx, rdx    ; current offset from unknown buffer
    gsize:
        mov al, [rsi+rdx]
        inc rdx
        cmp rax, 0x00
        jnz gsize
    ;dec rdx
    mov rax, 1      ; syscall write
    mov rdi, 1      ; file descriptor: stdout
    syscall
	jmp EXIT
	
GET_ARGS_FROM_STACK:
	; "call GET_ARGS_FROM_STACK" has moved stack pointer -8,
	; and argc was originally at [rsp+8], because [rsp] has the "main" return address
	; (according to http://bit.ly/1K8uIyu) so finally we need to get argc from [rsp+16]
	.start:
		mov r15, [rsp+16]
		cmp r15, ARGS_AMOUNT		; ARGS_AMOUNT will equate to 4 if extra points can be implemented
		; Needs to match exact amount of arguments
		ja .exceeded_max_args_supported
		jb .not_enough_arguments
		lea r14, [rsp+24]			; get address of argument vector
		xor rcx, rcx				; set an counter to loop around the arguments table
	.read_addresses:
		; rcx is just a counter, 8 is a displacement on the table
		mov rdi, [r14 + rcx*8]		; r14 is the address of argv
		mov [argpt + rcx*8], rdi	; copy the address back to the pointers table
		inc rcx
		cmp rcx, r15
		jnz .read_addresses			; if not reached argc
	.scan_begin:
		xor rax, rax				; Searching for 0x00 (NULL) in .scan
		xor rbx, rbx				; Offset index inside argpt
	.scan:
		mov rcx, 64					; Limiting search to 64 bytes maximum
		mov rdi, [argpt + rbx*8]	; Take next argument address
		mov rdx, rdi				; Backup address (start offset) in rdx, see later [1]
		cld							; Scanning from lower to higher addresses (bottom-up)
		repne scasb					; While rcx != 0, check [rdi] for AL, rdi++
		jnz EXIT					; if (scasb has finished and rcx != 0): AL was not found
	.store_lengths:
		;mov byte [rdi-1], 10		; replace NULL with /n at end_of_string; unnecesary using call puts
		sub rdi, rdx				; [1] calculate size of argument (end offset - start offset)
		mov [arglt + rbx*8], rdi	; store length of current argument
		inc rbx
		cmp rbx, r15				; has reached max of argc?
		jb .scan_begin
		ret
	; =============================== ERROR CODES
	.exceeded_max_args_supported:
		mov rsi, error_max_args
		mov rdx, 38
		jmp .error
	.not_enough_arguments:
		mov rsi, error_no_args
		mov rdx, 52
	.error:
		mov rax, 1
		mov rdi, 1
		syscall
		jmp EXIT

RETRIEVE_FILENAMES:
	; GET_ARGS_FROM_STACK also saved filename as a parameter, so we can skip it
	.skip_filename_parameter:
		xor rbx, rbx
		xor rdi, rdi
		inc rbx
		cld							; Scanning from lower to higher addresses (bottom-up)
	; This loop will actually only run ARGS_AMOUNT - 1 times
	.save_parameter:
		mov rcx, [arglt + rbx]		; get size of current parameter
		mov rsi, [argpt + rbx]		; get address of current parameter
		cmp rbx, 1
		cmove rdi, enigma_settings_filename
		cmp rbx, 2
		cmove rdi, enigma_input_filename
		;cmp rbx, 3
		;cmovz rdi, enigma_rotors_filename
		repne movsb					; Copy filename to selected buffer
		cmp rbx, ARGS_AMOUNT
		jz .return					; 
		inc rbx
		jmp .save_parameter
	.return:
		ret

;====================
EXIT:
	mov rax, 60        ; sys_EXIT
    syscall
