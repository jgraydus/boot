%include "constants.inc"
%include "memory.inc"
%include "string.inc"

; lexer object
;
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

; token object
;
; struct {
;     qword,          ; type
;     qword,          ; start index
;     qword,          ; end index  
; }

SIZEOF_TOKEN              equ 24

; input:
;   rsi - address of lexer object
; output:
;   rax - address of token object
global _next_token
_next_token:
    push r12
    push r13
    push r14
    push r15

    ; remember the lexer object
    mov r12, rsi
    ; get the length of the input
    mov rsi, [r12+0]
    call _string_length
    mov r13, rax
.start:
    ; if past the end of input string, return EOF token
    mov r14, [r12+8]
    cmp r14, r13
    jl .read_next_character
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+0], TOKEN_EOF
    mov [rax+8], r14
    mov [rax+16], r14
    jmp .done
.read_next_character:
    mov r15, [r12+8]
    mov rsi, [r12+0]
    mov rdi, r15
    call _string_char_at
    ; increment position
    inc rdi
    mov [r12+8], rdi
.skip_unused_chars:
    ; skip whitespace and control characters
    mov cl, 32
    cmp al, cl
    jle .start
    ; skip del and extended characters
    mov cl, 127
    cmp al, cl
    jge .start
.left_paren:
    mov cl, 40
    cmp al, cl
    jne .right_paren
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+0], TOKEN_LEFT_PAREN
    mov rcx, r15
    mov [rax+8], rcx
    inc rcx
    mov [rax+16], rcx
    jmp .done
.right_paren:
    ; right paren
    mov cl, 41
    cmp al, cl
    jne .next3
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+0], TOKEN_RIGHT_PAREN
    mov rcx, r15
    mov [rax+8], rcx
    inc rcx
    mov [rax+16], rcx
    jmp .done
.next3:

    ; TODO other tokens

   
    mov rax, 0
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    ret




section .rodata
    eof_token: db "[EOF]"
    left_paren_token: db "[LEFT_PAREN]"
    right_paren_token: db "[RIGHT_PAREN]"

section .text

; input:
;   rax - address of token object
global _print_token
_print_token:
    push r12
    mov r12, rax
.eof:
    mov rcx, [r12+0]     ; type tag
    cmp rcx, TOKEN_EOF
    jne .left_paren
    call _new_string
    mov rsi, eof_token
    mov rcx, 5
    call _append_from_buffer
    call _print_string
    jmp .done
.left_paren:
    mov rcx, [r12+0]
    cmp rcx, TOKEN_LEFT_PAREN
    jne .right_paren
    call _new_string
    mov rsi, left_paren_token
    mov rcx, 12
    call _append_from_buffer
    call _print_string
    jmp .done
.right_paren:
    mov rcx, [r12+0]
    cmp rcx, TOKEN_RIGHT_PAREN
    jne .next
    call _new_string
    mov rsi, right_paren_token
    mov rcx, 13
    call _append_from_buffer
    call _print_string
    jmp .done

.next:
    
.done:
    pop r12
    ret













