section .data
    P: times 256 db 0
    F: times 256 db 0
    input_value: db 0
    is_seqeuence_valid: db 0
section .text
global _start
_start:
