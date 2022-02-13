%include "constants.inc"
%include "lexer.inc"
%include "memory.inc"
%include "object.inc"
%include "parser.inc"
%include "print.inc"
%include "string.inc"
%include "vec.inc"

section .bss
    input: resq 1

section .rodata
    space_character: db " "

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


    ;mov rax, [input]
    ;mov r8, 2
    ;mov r9, 6
    ;call _substring
    ;call _print_string


;jmp .exit



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

jmp .parse

; print the tokens
    push r8
    push r9
    mov r8, 0
    mov rax, r15
    call _vec_length
    mov r9, rax
.loop:
    cmp r8, r9
    je .done
    mov rax, r15
    mov rsi, r8
    call _vec_value_at
    call _print_token
    inc r8
    jmp .loop
.done:
    pop r9
    pop r8

.parse:
    mov rax, r15
    call _new_parser
    mov r12, rax
.parse_next:
    mov rax, r12
    call _parse_next
    cmp rax, 0
    je .parse_done
    call _object_to_string
    ; add a space
    mov rsi, space_character
    mov rcx, 1
    call _append_from_buffer
    call _print_string
    jmp .parse_next
.parse_done:

    mov rax, r15
    mov rsi, 0
    call _vec_value_at







.exit:
    pop r15
    pop r14
    pop r13
    pop r12
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall


