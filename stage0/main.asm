%include "constants.inc"
%include "env.inc"
%include "eval.inc"
%include "gc.inc"
%include "intrinsics.inc"
%include "lexer.inc"
%include "memory.inc"
%include "object.inc"
%include "parser.inc"
%include "print.inc"
%include "string.inc"
%include "sys_calls.inc"
%include "vec.inc"

section .bss
    input: resq 1
    argc: resq 1
    args: resq 1
    buffer: resb 1024

section .rodata
    prelude: db "./prelude.0", 0
    space_character: db " "

section .text

; read input from stdin and save
_read:
    push r8
    mov rax, STDIN_FILENO
    mov r8, [argc]
    cmp r8, 2
    jne .stdin
    mov rdi, [args]    ; pointer to the array of args
    mov rdi, [rdi+8]   ; file should be second arg 
    mov rsi, O_RDONLY
    call _sys_open
.stdin:
    call _read_string
    mov [input], rax
    pop r8
    ret

; input:
;   rax - address of vec of tokens
_print_tokens:
    push r8
    push r9
    push r15
    mov r15, rax
    call _vec_length
    mov r9, rax
    mov r8, 0
.loop:
    cmp r8, r9
    je .done
    mov rax, r15
    mov rsi, r8
    call _vec_get_value_at
    call _print_token
    inc r8
    jmp .loop
.done:
    pop r15
    pop r9
    pop r8
    ret

_make_environment:
    mov rax, 0
    call _make_env
    call _add_intrinsics_to_env
    ret

global _start
_start:
    ; get argc
    pop rax
    mov [argc], rax
    ; top of stack now points at array of arguments (char**)
    mov [args], rsp

    ; these registers should be preserved
    push r12
    push r13
    push r14
    push r15

    call _init_heap     ; allocate heap memory (required for memory.asm)
    call _gc_init       ; initialize garbage collector (required for object.asm)

    call _make_environment
    mov r13, rax
    call _gc_set_root_object

    call _read
    call _tokenize
    mov r15, rax
    ;call _print_tokens

    mov rax, r15
    call _parse
    mov rsi, r13
    call _eval_proc
    call _object_to_string
    call _print_string
    mov rax, r13
    call _gc_run

.exit:
    call _print_memory_stats
    pop r15
    pop r14
    pop r13
    pop r12
    mov rdi, EXIT_SUCCESS
    call _sys_exit


