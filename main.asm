%include "constants.inc"
%include "env.inc"
%include "eval.inc"
%include "intrinsics.inc"
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
    newline: db 10
    foobar: db "foobar"

section .text


; read input from stdin and save
_read:
    call _read_string
    mov [input], rax
    ret

; input:
;   rax - address of input string
; output:
;   rax - addres of vec of tokens
_tokenize:
    push r8                    ; lexer
    push r9                    ; vec
    push r10                   ; token
    push rsi
    ; create the lexer
    call _new_lexer
    mov r8, rax
    ; create a vec to store the tokens 
    mov rax, 4
    call _new_vec
    mov r9, rax
    ; tokenize
.next_tok:
    mov rax, r8
    call _next_token
    mov r10, rax
    ; push token into vec
    mov rsi, rax
    mov rax, r9
    call _vec_append
    ; if not EOF, continue
    mov rax, r10
    call _token_type
    cmp rax, TOKEN_EOF
    jne .next_tok
    mov rax, r9    ; return the vec
    pop rsi
    pop r10
    pop r9
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

_print_newline:
    call _new_string
    mov rsi, newline
    mov rcx, 1
    call _append_from_buffer
    call _print_string
    ret

section .rodata
    x: db "x"
    y: db "y"
    z: db "z"
section .text

_make_environment:
    push r8        
    push r9
    push r10
    mov rax, 0
    call _make_env
    mov r8, rax
    ; bind x to 1
    call _new_string
    mov rsi, x
    mov rcx, 1
    call _append_from_buffer
    call _make_symbol_obj
    mov r9, rax
    mov rax, 1
    call _make_integer_obj
    mov rdi, rax
    mov rsi, r9
    mov rax, r8
    call _env_add_binding
    ; bind y to 2
    call _new_string
    mov rsi, y
    mov rcx, 1
    call _append_from_buffer
    call _make_symbol_obj
    mov r9, rax
    mov rax, 2
    call _make_integer_obj
    mov rdi, rax
    mov rsi, r9
    mov rax, r8
    call _env_add_binding
    ; bind z to 3
    call _new_string
    mov rsi, z
    mov rcx, 1
    call _append_from_buffer
    call _make_symbol_obj
    mov r9, rax
    mov rax, 3
    call _make_integer_obj
    mov rdi, rax
    mov rsi, r9
    mov rax, r8
    call _env_add_binding
    ; done
    mov rax, r8
    pop r10
    pop r9
    pop r8
    ret

global _start
_start:
    ; these registers should be preserved
    push r12
    push r13
    push r14
    push r15

    call _init_heap     ; allocate heap memory (required for memory.asm)
    call _gc_init       ; initialize garbage collector (required for object.asm)

    call _read
    call _tokenize
    mov r15, rax
    call _print_tokens
    call _print_newline
    call _print_newline
;jmp .exit

    call _make_environment
    mov r13, rax
    call _add_intrinsics_to_env
    ;call _object_to_string
    ;call _print_string
;jmp .exit

.parse:
    mov rax, r15
    call _new_parser
    mov r12, rax
.parse_next:
    mov rax, r12
    call _parse_next
    cmp rax, -1
    je .parse_done
    mov rsi, r13   ; environment
    call _eval
    call _object_to_string
    ; add a space
    mov rsi, space_character
    mov rcx, 1
    call _append_from_buffer
    call _print_string
    call _print_newline
    mov rax, r13
    call _object_to_string
    call _print_string
    call _print_newline
    jmp .parse_next
.parse_done:


.exit:
    call _print_memory_stats
    pop r15
    pop r14
    pop r13
    pop r12
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall


