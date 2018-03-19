; Piotrus Szulc 347277
%define ARR_LEN 256
%define BUFFER_SIZE 2048

%define SYS_READ 0
%define SYS_OPEN 2
%define SYS_EXIT 60

%define READONLY 0

; warning! Destroys content of r14
; args: 1:dst 2:src 3:offset
%macro copy_64_bits_from_offset 3
	mov r14, [%2 + %3 * 8]
    mov [%1 + %3 * 8], r14
%endmacro

section .data
    Occurences_in_current_permutation: times ARR_LEN db 0
    Occurences_in_first_permutation:   times ARR_LEN db 0

section .bss
    file_buffer: resb BUFFER_SIZE

; Register mnemonics
; al  - input_value
; rdi - file descriptor
; cl  -  Occurences...[input_value]
; r8  - current_position_in_buffer
; r9  - length_of_buffer
; r10 - is_first_permutation           (are we still processing first permutation)
; r12 - numbers_in_first_permutation   (how many elements are in first permutation)
; r13 - is_valid                       (is sequence valid)
; r14 - used for copying arrays;       (content will be lost when using copy_64_bits_from_offset macro)
; r15 - numbers_in_current_permutation (starts with numbers_in_first_permutation downto 0)

section .text
global _start
_start:
    nop

    pop rdi                                          ; argc == 2?
    cmp rdi, 2
    jne .exit_not_ok

    pop rdi                                          ; disregard name of program
    pop rdi                                          ; name of the file to be opened

    mov rax, SYS_OPEN                                ; opening file
    mov rsi, READONLY
    syscall

    mov rdi, rax
    cmp rdi, 0                                       ; check if fd > 0
    jle .exit_not_ok

    mov r10, 1                                       ; is_first_permutation = 0
    xor r15, r15                                     ; numbers_in_current_permutation = 0
    xor r12, r12                                     ; numbers_in_first_permutation = 0
    xor r13, r13                                     ; is_valid = 0;

.read_from_file_loop:                                ; read data from file into buffer
    mov rax, SYS_READ
    mov rsi, file_buffer
    mov rdx, BUFFER_SIZE

    syscall
    js .exit_not_ok                                   ; file is open but cannot be read

    xor rdx, rdx                                      ; clear register, we're going to use lower 8 bits of this registry

    cmp rax, 0                                        ; check number of bytes read
    je .check_if_valid_and_exit                       ; if bytes_read == 0 then end program

    xor r8, r8                                        ; current_position_in_buffer = 0
    mov r9, rax                                       ; length_of_buffer = bytes_read

.main_loop:                                           ; extracting value from buffer
    cmp r8, r9                                        ; if current_position_in_buffer == length_of_buffer
    je .read_from_file_loop                           ; then buffer exhausted, read more data from file

    mov al, [file_buffer + r8]                        ; input_value = file_buffer[current_position_in_buffer]
    inc r8                                            ; current_position_in_buffer++

    cmp al, 0                                         ; if (input_value == 0)
    je .handle_zero
                                                      ; input_value != 0
    xor r13, r13                                      ; is_valid = 0
    cmp r10, 0                                        ; is_first_permutation == false? (Did we finish parsing first permutation?)
    je .handle_non_zero_in_non_first_permutation
                                                      ; We are still parsing first permutation
    mov dl, [Occurences_in_first_permutation + eax]   ; Occurences_in_first_permutation[input_value] == 1?
    cmp dl, 1                                         ; if yes then we have repetition and sequence is invalid
    je .exit_not_ok

    inc dl
    mov [Occurences_in_first_permutation + eax], dl   ; Occurences_in_first_permutation[input_value]++
    inc r12                                           ; numbers_in_first_permutation++
    jmp .main_loop

.handle_non_zero_in_non_first_permutation:
    mov dl, [Occurences_in_current_permutation + eax] ; Occurences_in_curent_permutation[input_value] == 0?
    cmp dl, 0                                         ; if yes then we have repetition or value is not in first permutation -> sequence invalid
    je .exit_not_ok

    dec dl
    dec r15                                           ; numbers_in_current_permutation--
    mov [Occurences_in_current_permutation + eax], dl ; Occurences_in_current_permutation[input_value]--

    jmp .main_loop

.handle_zero:
    xor r10, r10                                      ; first_permutation = false;
    cmp r15, 0                                        ; numbers_in_current_permutation == 0?
    je .handle_zero_set_valid
    xor r13, r13                                      ; is_valid = false
    jmp .handle_zero_epilogue
.handle_zero_set_valid:
    mov r13, 1                                        ; is_valid = true
.handle_zero_epilogue:
    mov r15, r12                                      ; numbers_in_current_permutation = numbers_in_first_permutation;

    ; Occurences_in_current_permutation = Occurences_in_first_permutation
    ; it's done in magic/tricky way cause I'm having fun with NASM preprocessor; trying out cool different things :)
    ; since array is 256 bytes, lets copy array using 64 bit (!!!) r14 (!!!) register
    %assign i 0
    %rep 32
            copy_64_bits_from_offset Occurences_in_current_permutation, Occurences_in_first_permutation, i
	%assign i i+1
    %endrep

    jmp .main_loop
; ***END OF MAIN_LOOP***

.check_if_valid_and_exit:
    cmp r13, 1                                       ; is_valid == true?
    jne .exit_not_ok

    mov rax, SYS_EXIT                                ; Valid ok, Exit(0)
    mov rdi, 0
    syscall

.exit_not_ok:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
