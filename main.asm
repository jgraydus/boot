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
    mov r12, rax

.next_tok:
    mov rsi, r12
    call _next_token
    ;cmp rax, 0
    ;je .next_tok
    mov r13, rax
    call _print_token
    mov rax, [r13+0]
    cmp rax, TOKEN_EOF
    jne .next_tok
.done:



    ;mov rax, [input]
    ;call _print_string

    ; exit
    pop r15
    pop r14
    pop r13
    pop r12
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall


