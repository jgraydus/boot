%include "constants.inc"
%include "lexer.inc"
%include "memory.inc"
%include "object.inc"
%include "stack.inc"
%include "string.inc"
%include "sys_calls.inc"
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
    call _vec_get_value_at
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
    call _vec_get_value_at
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
    mov rdi, 1
    call _sys_exit 
.error:
    ; TODO
.done:
    pop r15
    pop r14
    pop rcx
    pop rbx
    pop rsi
    ret


; input:
;   rax - address of a vec of tokens
; output:
;   rax - address of a list object
global _parse
_parse:
    push rcx
    push r8
    push r9
    push r10
    push r11
    call _new_parser
    mov r8, rax
    mov r9, 0
    mov r10, 0
.next:
    mov rax, r8
    call _parse_next
    cmp rax, -1
    je .done
    mov rcx, 0
    call _make_pair_obj
    mov r11, rax
    mov rax, r9
    cmp rax, 0
    jne .append
    mov r9, r11
    mov r10, r11
    jmp .next
.append:
    mov rax, r10
    mov rcx, r11
    call _set_pair_tail
    mov r10, r11
    jmp .next
.done:
   mov rax, r9
   pop r11
   pop r10
   pop r9
   pop r8
   pop rcx
   ret





