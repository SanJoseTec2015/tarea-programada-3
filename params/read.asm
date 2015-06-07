ARGS_AMOUNT equ 3									; ARGS_AMOUNT will equate to 4 if extra points can be implemented
section .data
	; Extracting information from main()
	argpt: times ARGS_AMOUNT dq 0x0000000000000000	; Argument pointers table - char** argv
	arglt: times ARGS_AMOUNT db 0x00				; Argument lenghts table  - char** argv
	current_char: db 0x00
	debug_current_char: dq 0x00
	; Filenames must be shorter than 256 bytes, including extension
	settings_filename: times 256 db 0x00
	input_filename:	  times 256 db 0x00
	;enigma_rotors_filename:	  times 256 db 0x00

	enigma_settings_file_descriptor: dq 0
	enigma_input_file_descriptor:	 dq 0
	;enigma_rotors_file_descriptor:	 dq 0

	error_max_args: db 'Exceeded maximum supported arguments.', 0x00
	error_max_argsLEN equ $-error_max_args
	error_no_args: db 'Not enough arguments were provided to this program.', 0x00
	error_no_argsLEN equ $-error_no_args
	error_args_too_long: db 'One of the arguments is too long.', 0x00
	error_args_too_longLEN equ $-error_args_too_long
; =============================================== DEBUGGING
%macro debug_buffer 1   ; address of buffer
    push rdx
    push rsi
    push rdi
    push rax
    mov rsi, %1     ; unknown buffer
    xor rax, rax    ; current char from unknown buffer
    xor rdx, rdx    ; current offset from unknown buffer
    %%scan:
        xor rax, rax
        mov al, [rsi+rdx]
        inc rdx
        cmp rax, 0x00
        jnz %%scan
    dec rdx
    mov rax, 1      ; syscall write
    mov rdi, 1      ; file descriptor: stdout
    syscall
    pop rax
    pop rdi
    pop rsi
    pop rdx
%endmacro
%macro debug_register 1
    push rdi
    push rdx
    push rsi
    push rax
    mov [debug_current_char], %1
    mov rax, 1      ; syscall write
    mov rdi, 1      ; file descriptor: stdout
    mov rsi, debug_current_char
    mov rdx, 8
    syscall
    pop rax
    pop rsi
    pop rdx
    pop rdi
%endmacro
; =============================================== DEBUGGING
section .text
global GET_ARGS_FROM_STACK
global RETRIEVE_FILENAMES
global settings_filename
global input_filename
	
GET_ARGS_FROM_STACK:
	; "call GET_ARGS_FROM_STACK" has moved stack pointer -8,
	; I'm not using libc here (there is no "main" return address at [rsp], according to http://bit.ly/1K8uIyu)
	; argc is originally at [rsp]
	.start:
		mov r15, [rsp+8]
		cmp r15, ARGS_AMOUNT		; ARGS_AMOUNT will equate to 4 if extra points can be implemented
		; Needs to match exact amount of arguments
		ja .exceeded_max_args_supported
		jb .not_enough_arguments
		xor rcx, rcx				; set an counter to loop around the arguments table
	.read_addresses:
		; rcx is just a counter, 8 is a displacement on the table
		mov rdi, [rsp + rcx*8 + 16]	; rsp+16 is the address of argv
		debug_register rdi
		mov [argpt + rcx * 8], rdi	; copy the address back to the pointers table
		inc rcx
		cmp rcx, r15
		jnz .read_addresses			; if not reached argc
	.scan_begin:
		xor rax, rax				; Searching for 0x00 (NULL) in .scan
		xor rbx, rbx				; Offset index inside argpt
	.scan:
		mov rcx, 256				; Limiting search to 256 bytes maximum
		mov rdi, [argpt + rbx * 8]	; Take next argument address
		mov rdx, rdi				; Backup address (start offset) in rdx, see later [1]
		cld							; Scanning from lower to higher addresses (bottom-up)
		repne scasb					; While rcx != 0, check [rdi] for AL, rdi++
		jnz .arguments_too_long		; if (scasb has finished and rcx != 0): AL was not found
	.store_lengths:
		sub rdi, rdx				; [1] calculate size of argument (end offset - start offset)
		mov [arglt + rbx * 8], rdi	; store length of current argument
		inc rbx
		cmp rbx, r15				; has reached max of argc?
		jb .scan_begin
		ret
	; =============================== ERROR CODES
	.exceeded_max_args_supported:
		mov rsi, error_max_args
		mov rdx, error_max_argsLEN
		jmp .error
	.not_enough_arguments:
		mov rsi, error_no_args
		mov rdx, error_no_argsLEN
		jmp .error
	.arguments_too_long:
		mov rsi, error_args_too_long
		mov rdx, error_args_too_longLEN
	.error:
		mov rax, 1
		mov rdi, 1
		syscall
		mov rax, 60        ; sys_EXIT
		syscall

RETRIEVE_FILENAMES:
	; GET_ARGS_FROM_STACK also saved filename as a parameter, so we can skip it
	push rdi
	push rcx
	push rbx
	push rsi
	.skip_filename_parameter:
		xor rdi, rdi
		xor rcx, rcx
		inc rcx
		cld							; Scanning from lower to higher addresses (bottom-up)
	; This loop will actually only run ARGS_AMOUNT - 1 times
	.save_parameter:
		mov rbx, [arglt + rcx]		; get size of current parameter
		mov rsi, [argpt + rcx]		; get address of current parameter
		cmp rcx, 1
		jz .read_settings
		cmp rcx, 2
		jz .read_input
		;cmp rcx, 3
		;jz .read_rotors
			.read_settings
				mov rdi, settings_filename
				jmp .continue
			.read_input:
				mov rdi, input_filename
				jmp .continue
			;.read_rotors:			; Extra points parameter
				;mov rdi, enigma_rotors_filename
		.continue:
		repne movsb					; Copy filename to selected buffer
		;debug_buffer settings_filename
		cmp rcx, ARGS_AMOUNT
		jz .return
		inc rcx
		jmp .save_parameter
	.return:
		pop rsi
		pop rbx
		pop rcx
		pop rdi
		ret