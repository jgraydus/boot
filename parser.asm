%include "constants.inc"
%include "lexer.inc"
%include "memory.inc"
%include "object.inc"
%include "stack.inc"
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


; input:
;   rax - address of parser
; output:
;   rax - address of next parsed object (or 0 if no more tokens to parse)
global _parse_next
_parse_next:
    push rsi
    push rbx
    push rcx
    mov rbx, rax       ; parser
    ; check if there are more tokens
    mov rax, [rbx+0]
    call _vec_length
    cmp rax, 0
    je .done
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
    mov rax, 0
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
    mov rax, rcx
    ; TODO

.error:
    ; TODO

.done:
    pop rcx
    pop rbx
    pop rsi
    ret









