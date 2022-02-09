%include "constants.inc"
%include "lexer.inc"
%include "memory.inc"
%include "print.inc"
%include "string.inc"

section .bss
    input: resq 1


section .text

global _start
_start:
    ; these registers should be preserved
    push r12
    push r13
    push r14
    push r15

    ; allocate the heap memory
    call _init_heap

    ; read from stdin
    call _read_string
    mov [input], rax

    mov rsi, rax
    call _new_lexer 




    ; exit
    pop r15
    pop r14
    pop r13
    pop r12
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall


