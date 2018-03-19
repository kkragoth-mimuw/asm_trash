%define ARR_LEN 256
%define BUFFER_SIZE 2048

%define SYS_READ 0
%define SYS_OPEN 2
%define SYS_CLOSE 3
%define SYS_EXIT 60

%define READONLY 0

section .data
    P: times ARR_LEN db 0
    O: times ARR_LEN db 0

section .bss
    input_value: resb 1
    file_buffer: resb BUFFER_SIZE

; eax - input_value
; ebx - file descriptor
; ecx - Getting_value_from_array
; r10 - is_first_permutation
; r15 - numbers_in_current_set
; r12 - numbers_in_first_set
; r13 - is_valid

section .text
global _start
_start:
    nop

	mov eax, 1;
	mov bl, [P + eax]

    pop rdi ;number of command line parameters
    cmp rdi, 2 ; check if we get file parameter
    jne .exit_not_ok

    pop rdi ;name of the program - will be disregarded

    pop rdi ;name of the file to be opened

    ;open file in read mode
    mov rax, SYS_OPEN
    mov rsi, READONLY
    syscall
    
    cmp rax, 0 ;check if fd > 0 (ok)
    jle .exit_not_ok
    mov rdi, rax

    mov r10, 1
    xor r15, r15 ;numbers_in_current_permutation = 0
    xor r12, r12 ;numbers_in_first_permutation = 0
    xor r13, r13 ;is_valid = 0;
.main_loop:
    mov rax, SYS_READ
    mov rsi, input_value
    mov rdx, 1 ;read one byte

    syscall
    js .exit_not_ok ;file is open but cannot be read

    cmp eax, 1;check number of bytes read
    jb .ending_protocol

    mov rax, [input_value]

    cmp al, 0
    je .handle_zero

    ;non_zero
	xor r13, r13
    cmp r10, 0
    je .handle_non_zero_in_non_first_permutation
.handle_non_zero_in_first_permutation:
    mov dl, [O + eax]
    cmp dl, 1
    je .exit_not_ok

    inc dl
    mov [O + eax], dl
    inc r12
    jmp .main_loop
    
.handle_non_zero_in_non_first_permutation:
    mov dl, [P + eax]
    cmp dl, 0
    je .exit_not_ok

    dec r15
    dec dl
    mov [P + eax], dl


    jmp .main_loop

.handle_zero:
    xor r10, r10; first_permutation = 0;
    cmp r15, 0
    je .valid
    xor r13, r13
    jmp .next

.valid:
    mov r13, 1
.next:
    mov r15, r12; numbers_in_current_permutation = 0;
    
    mov r14, [O]
    mov [P], r14

    mov r14, [O+1*64]
    mov [P+1*64], r14

    mov r14, [O+2*64]
    mov [P+2*64], r14

    mov r14, [O+3*64]
    mov [P+3*64], r14
    jmp .main_loop

.ending_protocol:
    cmp r13, 1
    je .exit_ok
    jmp .exit_not_ok

.close:
    mov eax, SYS_CLOSE
    syscall

.exit_ok:
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall


.exit_not_ok:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
