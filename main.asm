%include "constants.inc"
%include "lexer.inc"
%include "memory.inc"
%include "print.inc"
%include "string.inc"
%include "vec.inc"

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

    mov rax, 4
    call _new_vec
    mov r15, rax

; tokenize input
.next_tok:
    mov rsi, r12
    call _next_token

    mov r13, rax
    ; call _print_token

    mov rsi, rax
    mov rax, r15
    call _vec_append

    mov rax, [r13+0]
    cmp rax, TOKEN_EOF
    jne .next_tok


; print the tokens
    push r8
    push r9
    mov r8, 0
    mov rax, r15
    call _vec_length
    mov r9, rax
_loop:
    cmp r8, r9
    je _done
    mov rax, r15
    mov rsi, r8
    call _vec_value_at
    call _print_token
    inc r8
    jmp _loop
_done:
    pop r9
    pop r8



    ; exit
    pop r15
    pop r14
    pop r13
    pop r12
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall


