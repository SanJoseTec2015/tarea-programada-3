section .data
	settings_file_descriptor: dq 0
	input_file_descriptor: dq 0

	error_cannot_open_settings: db 'Cannot open settings file.', 0x00
	error_cannot_open_settingsLEN equ $-error_cannot_open_settings
	error_cannot_open_input:	db 'Cannot open message file.', 0x00
	error_cannot_open_inputLEN equ $-error_cannot_open_input

; =============================================== DEBUGGING

; =============================================== DEBUGGING
section .text
global _start

global settings_file_descriptor
global input_file_descriptor

extern GET_ARGS_FROM_STACK
extern RETRIEVE_FILENAMES
extern settings_filename
extern input_filename
;extern enigma_rotors_filename

_start:
	call GET_ARGS_FROM_STACK	; do not place nothing before this
	;call RETRIEVE_FILENAMES
	; call OPEN_SETTINGS
	; call OPEN_INPUT
	; mov rsi, settings_file_descriptor
 ;    xor rax, rax    ; current char
 ;    xor rdx, rdx    ; getting strlen() directly on rdx
 ;    .strlen:
 ;        mov al, [rsi+rdx]
 ;        inc rdx
 ;        cmp rax, 0x00
 ;        jnz .strlen
 ;    mov rax, 1      ; syscall write
 ;    mov rdi, 1      ; file descriptor: stdout
 ;    syscall
	mov rax, 60        ; sys_EXIT
    syscall

OPEN_SETTINGS:
	push rdi
	push rsi
	push rax
	mov rax, 2						; Using open() syscall according to http://man7.org/linux/man-pages/man2/open.2.html
	lea rdi, [settings_filename]	; Passing parameters, order according to http://blog.rchapman.org/post/36801038863/linux-system-call-table-for-x86-64
	mov rsi, 0x0000 				; Setting flag O_RDONLY, according to http://lxr.free-electrons.com/ident?i=O_RDONLY
	syscall
	cmp rax, 0
	jl  .error
	mov [settings_file_descriptor], rax
	pop rax
	pop rsi
	pop rdi
	ret
	.error:
		mov rsi, error_cannot_open_settings
		mov rdx, error_cannot_open_settingsLEN
		mov rax, 1
		mov rdi, 1
		syscall
		mov rax, 60        ; sys_EXIT
		syscall
;====================
OPEN_INPUT:
	push rdi
	push rsi
	push rax
	mov rax, 2						
	lea rdi, [input_filename]
	mov rsi, 0x0000 				
	syscall
	cmp rax, 0
	jl  .error
	mov [input_file_descriptor], rax
	pop rax
	pop rsi
	pop rdi
	ret
	.error:
		mov rsi, error_cannot_open_input
		mov rdx, error_cannot_open_inputLEN
		mov rax, 1
		mov rdi, 1
		syscall
		mov rax, 60        ; sys_EXIT
		syscall

TERM_PAUSE:			; Allows animation to be paused by hitting enter
	push rax
	push rdi
	push rsi
	push rdx
	.enter_pause:
		mov rax, 0	; sys_read
		mov rdi, 0	; stdin
		mov rsi, debug_current_char
		mov rdx, 1
		syscall
		cmp byte [debug_current_char], 10	; if not enter skip letter
		jnz .enter_pause
	pop rdx
	pop rsi
	pop rdi
	pop rax
	ret