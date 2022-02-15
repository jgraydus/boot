%include "constants.inc"
%include "lexer.inc"
%include "memory.inc"
%include "object.inc"
%include "stack.inc"
%include "string.inc"
%include "vec.inc"

section .text

; parser
;
; struct {
;    ptr,      ; address of vec of tokens 
;    qword,    ; index of next token
; }

%define SIZEOF_PARSER    16

; input: 
;   rax - address of a vec of tokens
; output:
;   rax - address of parser
global _new_parser
_new_parser:
    push rbx
    mov rbx, rax
    mov rax, SIZEOF_PARSER
    call _malloc
    mov [rax+0], rbx
    mov qword [rax+8], 0
    pop rbx
    ret

section .rodata
    unmatched_paren_msg: db "unmatched paren"

section .text

; input:
;   rax - address of parser
; output:
;   rax - address of next parsed object (or -1 if done parsing)
global _parse_next
_parse_next:
    push rsi
    push rbx
    push rcx
    push r14
    push r15
    mov rbx, rax       ; parser
    ; TODO ensure we don't read past end of vec?
    ; get the next token
    mov rax, [rbx+0]
    mov rsi, [rbx+8]
    call _vec_value_at
    mov rcx, rax        ; token
    ; increment index
    mov rsi, [rbx+8] 
    inc rsi
    mov [rbx+8], rsi
    ; 
    mov rax, rcx
    call _token_type

.eof:
    cmp rax, TOKEN_EOF
    jne .string
    mov rax, -1
    jmp .done

.string:
    cmp rax, TOKEN_STRING
    jne .integer
    mov rax, rcx
    call _token_value
    jmp .done

.integer:
    cmp rax, TOKEN_INTEGER
    jne .symbol
    mov rax, rcx
    call _token_value
    call _make_integer_obj
    jmp .done

.symbol:
    cmp rax, TOKEN_SYMBOL
    jne .list
    mov rax, rcx
    call _token_value
    call _make_symbol_obj
    jmp .done

.list:
    cmp rax, TOKEN_LEFT_PAREN
    jne .error
    call _new_stack
    mov r14, rax
.list_next:
    ; check next token for right paren
    mov rax, [rbx+0]
    mov rsi, [rbx+8]
    call _vec_value_at
    call _token_type
    cmp rax, TOKEN_RIGHT_PAREN
    je .list_done
    cmp rax, TOKEN_EOF
    je .list_unmatched_paren
    mov rax, rbx
    call _parse_next
    mov rsi, rax
    mov rax, r14
    call _stack_push
    jmp .list_next
.list_done:
    ; consume the right paren
    mov rsi, [rbx+8] 
    inc rsi
    mov [rbx+8], rsi
    ; create list
    mov rcx, 0
.build_list:
    mov rax, r14
    call _stack_size
    cmp rax, 0
    je .build_list_done
    mov rax, r14
    call _stack_pop
    call _make_pair_obj
    mov rcx, rax
    jmp .build_list
.build_list_done:
    mov rax, rcx
    jmp .done
.list_unmatched_paren:
    call _new_string
    mov rsi, unmatched_paren_msg
    mov rcx, 15
    call _append_from_buffer
    call _print_string
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

.error:
    ; TODO

.done:
    pop r15
    pop r14
    pop rcx
    pop rbx
    pop rsi
    ret









