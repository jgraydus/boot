%include "constants.inc"
%include "memory.inc"
%include "string.inc"

; struct {
;     ptr,       ; address of input string
;     qword,     ; index of next character to read
; }

SIZEOF_LEXER          equ 16

; input:
;   rsi - address of input string object
; output:
;   rax - address of lexer object
global _new_lexer
_new_lexer:
    mov rax, SIZEOF_LEXER
    call _malloc
    mov [rax+0], rsi
    mov qword [rax+8], 0
    ret

; input:
;   rsi - address of lexer object
; output:
;   rax - address of token object
global _next_token
_next_token:
    ; TODO
    ret


