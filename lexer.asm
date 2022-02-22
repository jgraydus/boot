%include "constants.inc"
%include "memory.inc"
%include "string.inc"
%include "vec.inc"

section .text

; lexer object
;
; struct {
;     ptr,       ; address of input string
;     qword,     ; index of next character to read
;     ptr,       ; address of vec of tokens
; }

%define SIZEOF_LEXER    24

; input:
;   rax - address of input string object
; output:
;   rax - address of lexer object
_new_lexer:
    push r8
    mov r8, rax
    mov rax, SIZEOF_LEXER
    call _malloc
    mov rbx, rax
    mov rax, 32
    call _new_vec
    mov [rbx+0], r8
    mov qword [rbx+8], 0
    mov [rbx+16], rax
    mov rax, rbx
    pop r8
    ret

; token object
;
; struct {
;     qword,          ; type
;     qword,          ; start index
;     qword,          ; end index
;     ptr or qword,   ; other stuff (depends on token) 
; }

%define SIZEOF_TOKEN     32

; input:
;   rax - address of token
; output:
;   rax - token type
global _token_type
_token_type:
    push rbx
    mov rbx, rax
    mov rax, [rbx+0]
    pop rbx
    ret

; input:
;   rax - address of token
; output:
;   rax - value of token
global _token_value
_token_value:
    push rbx
    mov rbx, rax
    mov rax, [rbx+24]
    pop rbx
    ret
        

; input:
;   rax - address of lexer object
; output:
;   rax - address of token object
global _next_token
_next_token:
    push r8
    push r9
    push r12
    push r13
    push r14
    push r15
    push rdi
    push rcx

    ; remember the lexer object
    mov r12, rax
    ; get the length of the input
    mov rax, [r12+0]
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
    ; skip comments
    mov cl, 59       ; semicolon
    cmp al, cl
    jne .left_paren
.skip_to_newline:
    ; if character is newline, then start tokenizing again
    mov cl, 10       ; newline
    cmp al, cl
    je .start
    ; otherwise read next character 
    mov r15, [r12+8]
    mov rsi, [r12+0]
    mov rdi, r15
    call _string_char_at
    ; increment position
    inc rdi
    mov [r12+8], rdi
    jmp .skip_to_newline
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
    jne .string
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+0], TOKEN_RIGHT_PAREN
    mov rcx, r15
    mov [rax+8], rcx
    inc rcx
    mov [rax+16], rcx
    jmp .done
.string:
    mov cl, 34      ; " character
    cmp al, cl
    jne .integer
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+0], TOKEN_STRING
    mov r8, r15
    inc r8
    mov [rax+8], r8    ; position of first character
    push rax
.string_loop:
    mov r15, [r12+8]
    cmp r15, r13
    je .string_done
    mov rsi, [r12+0]
    mov rdi, r15
    call _string_char_at
    ; increment position
    inc rdi
    mov [r12+8], rdi
    ; stop at next "
    mov cl, 34
    cmp al, cl
    jne .string_loop 
.string_done:
    pop rax
    push rbx
    mov rbx, rax   ; token 
    mov [rbx+16], r15
    ; copy string into token
    mov rax, [r12+0]  ; input string
    mov r8, [rbx+8]   ; from index
    mov r9, [rbx+16]  ; to index
    call _substring
    mov [rbx+24], rax
    mov rax, rbx
    pop rbx
    jmp .done
.integer:
    ; first digit
    cmp al, 48     ; '0'
    jl .symbol
    cmp al, 57     ; '9'
    jg .symbol
    ; accumulate integer value into r8
    sub rax, 48     ; shift ascii value to numeric value of digit
    mov r8, rax
    ; create token
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+0], TOKEN_INTEGER
    mov [rax+8], r15
    push rax
.integer_next_digit:
    mov r15, [r12+8]
    mov rsi, [r12+0]
    mov rdi, r15
    push r8
    call _string_char_at
    pop r8
    cmp al, 48       ; '0'
    jl .integer_done
    cmp al, 57       ; '9'
    jg .integer_done
    inc rdi
    mov [r12+8], rdi
    ; multiply previous value by 10 and add value of new digit
    push rax
    mov rax, 10
    mul r8
    mov r8, rax
    pop rax
    sub rax, 48
    add r8, rax
    jmp .integer_next_digit 
.integer_done:
    pop rax
    mov [rax+16], r15
    mov [rax+24], r8      ; integer value   
    jmp .done
.symbol:
    cmp al, 33
    jl .next
    cmp al, 126
    jg .next
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+0], TOKEN_SYMBOL
    mov [rax+8], r15
    push rax 
.symbol_next_character:
    mov r15, [r12+8]
    mov rsi, [r12+0]
    mov rdi, r15
    call _string_char_at
    cmp al, 33
    jl .symbol_done
    cmp al, 126
    jg .symbol_done
    cmp al, 40          ; (
    je .symbol_done
    cmp al, 41          ; )
    je .symbol_done
    inc rdi
    mov [r12+8], rdi
    jmp .symbol_next_character
.symbol_done:
    pop rax
    push rbx
    mov rbx, rax   ; token 
    mov [rbx+16], r15
    ; copy string into token 
    mov rax, [r12+0]  ; input string
    mov r8, [rbx+8]   ; from index
    mov r9, [rbx+16]  ; to index
    call _substring
    mov [rbx+24], rax
    mov rax, rbx
    pop rbx
    jmp .done
.next:
    ; TODO other tokens

   
    mov rax, 0
.done:
    pop rcx
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop r9
    pop r8
    ret




section .rodata
    eof_token: db "[EOF]"
    left_paren_token: db "[LEFT_PAREN]"
    right_paren_token: db "[RIGHT_PAREN]"
    string_token_start: db "[STRING ", 34    ; 34 is " character
    string_token_end: db 34, "]"
    integer_token_start: db "[INTEGER "
    integer_token_end: db "]"
    symbol_token_start: db "[SYMBOL "
    symbol_token_end: db "]"

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
    jne .string
    call _new_string
    mov rsi, right_paren_token
    mov rcx, 13
    call _append_from_buffer
    call _print_string
    jmp .done
.string:
    mov rcx, [r12+0]
    cmp rcx, TOKEN_STRING
    jne .integer
    call _new_string
    ; prefix
    mov rsi, string_token_start
    mov rcx, 9
    call _append_from_buffer
    ; string
    mov rsi, [r12+24]
    call _string_append
    ; suffix
    mov rsi, string_token_end
    mov rcx, 2
    call _append_from_buffer
    call _print_string
    jmp .done
.integer:
    mov rcx, [r12+0]
    cmp rcx, TOKEN_INTEGER
    jne .symbol
    call _new_string
    ; prefix
    mov rsi, integer_token_start
    mov rcx, 9
    call _append_from_buffer
    ; integer value
    push rax
    mov rax, [r12+24]
    call _string_from_integer
    mov rsi, rax
    pop rax
    call _string_append
    ; suffix
    mov rsi, integer_token_end
    mov rcx, 1
    call _append_from_buffer
    call _print_string
    jmp .done
.symbol:
    mov rcx, [r12+0]
    cmp rcx, TOKEN_SYMBOL
    jne .error
    call _new_string
    ; prefix
    mov rsi, symbol_token_start
    mov rcx, 8
    call _append_from_buffer
    ; string
    mov rsi, [r12+24]
    call _string_append
    ; suffix
    mov rsi, symbol_token_end
    mov rcx, 1
    call _append_from_buffer
    call _print_string
    jmp .done

.error:
    ; TODO
    
.done:
    pop r12
    ret


; input:
;   rax - address of input string
; output:
;   rax - addres of vec of tokens
global _tokenize
_tokenize:
    push r8                    ; lexer
    push r9                    ; vec
    push r10                   ; token
    push rsi
    ; create the lexer
    call _new_lexer
    mov r8, rax
    mov r9, [rax+16]           ; vec to store tokens
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



