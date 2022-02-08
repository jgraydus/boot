%include "constants.inc"
%include "memory.inc"
%include "print.inc"
%include "string.inc"

section .data
    message: db "hello there", 10
    message_len: dq 12

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

    mov rsi, message
    mov rcx, [message_len]
    call _append_from_buffer

    call _print_string


    ; exit
    pop r15
    pop r14
    pop r13
    pop r12
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall


