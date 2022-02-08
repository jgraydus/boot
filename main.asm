%include "constants.inc"
%include "memory.inc"
%include "print.inc"
%include "string.inc"

section .text

global _start
_start:
    call _init_heap

    call _read_string

    call _print_string

    ; exit
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall


