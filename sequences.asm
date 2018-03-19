%define BUFFER_SIZE 2048

%define SYS_READ 3
%define SYS_OPEN 5
%define SYS_CLOSE 6
%define SYS_EXIT 60

%define READONLY 0

section .data
    P: times 256 db 0
    O: times 256 db 0

section .bss
    input_value: resb 1
    file_buffer: resb BUFFER_SIZE

; eax - input_value
; ebx - file descriptor
; ecx - Getting_value_from_array
; r10 - is_first_permutation
; r11 - numbers_in_current_set
; r12 - numbers_in_first_set
; r13 - is_valid

section .text
global _start
_start:
    nop

    pop rbx ;number of command line parameters
    cmp rbx, 2 ; check if we get file parameter
    jne .exit_not_ok

    pop rbx ;name of the program - will be disregarded

    pop rbx ;name of the file to be opened
    cmp ebx, 0 ;check if ebx is ok
    jbe .exit_not_ok

    ;open file in read mode
    mov eax, SYS_OPEN
    mov ecx, READONLY
    syscall
    
    cmp eax, 0 ;check if fd > 0 (ok)
    jbe .exit_not_ok
    mov ebx, eax

    mov r10, 1
    xor r11, r11 ;numbers_in_current_permutation = 0
    xor r12, r12 ;numbers_in_first_permutation = 0
    xor r13, r13 ;is_valid = 0;
.main_loop:
    mov eax, SYS_READ
    mov ecx, input_value
    mov edx, 1 ;read one byte

    syscall
    js .exit_not_ok ;file is open but cannot be read

    cmp eax, 1;check number of bytes read
    jb .ending_protocol

    mov al, [input_value]

    cmp al, 0
    je .handle_zero

    ;non_zero
    cmp r10, 0
    je .handle_non_zero_in_non_first_permutation
.handle_non_zero_in_first_permutation:
    mov cl, [O + eax]
    cmp cl, 1
    je .exit_not_ok

    inc cl
    mov [O + eax], cl
    inc r12
    jmp .main_loop
    
.handle_non_zero_in_non_first_permutation:
    mov cl, [P + eax]
    cmp cl, 0
    je .exit_not_ok

    dec r11
    dec cl
    mov [P + eax], cl


    jmp .main_loop

.handle_zero:
    xor r10, r10; first_permutation = 0;
    cmp r11, 0
    je .valid
    xor r13, r13
    jmp .next

.valid:
    mov r13, 1
.next:
    mov r11, r12; numbers_in_current_permutation = 0;
    
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
