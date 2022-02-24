%include "constants.inc"
%include "memory.inc"
%include "string.inc"
%include "vec.inc"

%define newline_char           10
%define space_char             32
%define bang_char              33
%define double_quote_char      34
%define left_paren_char        40
%define right_paren_char       41
%define semicolon_char         59
%define tilde_char            126
%define del_char              127
%define ascii_digit_offset     48

section .text

; lexer object
;
; struct {
;     ptr,       ; address of input string
;     qword,     ; index of next character to read
;     ptr,       ; address of vec of tokens
;     qword,     ; line number
; }

%define input_string_offset           0
%define next_character_index_offset   8
%define token_vec_offset              16
%define line_number_offset            24
%define SIZEOF_LEXER                  24
%define LEXER_VEC_SIZE                32

; input:
;   rax - address of input string object
; output:
;   rax - address of lexer object
_lexer_new:
    push r8
    push r9
    mov r8, rax
    mov rax, SIZEOF_LEXER
    call _malloc
    mov r9, rax
    mov rax, LEXER_VEC_SIZE
    call _vec_new
    mov       [r9+input_string_offset],          r8
    mov qword [r9+next_character_index_offset],   0
    mov       [r9+token_vec_offset],            rax
    mov qword [r9+line_number_offset],            1
    mov rax, r9
    pop r9
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

%define token_type_offset             0
%define token_start_index_offset      8
%define token_end_index_offset       16
%define token_value_offset           24
%define SIZEOF_TOKEN                 32

; input:
;   rax - address of token
; output:
;   rax - token type
global _token_type
_token_type:
    push rbx
    mov rbx, rax
    mov rax, [rbx+token_type_offset]
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
    mov rax, [rbx+token_value_offset]
    pop rbx
    ret

; input:
;   rax - size of input string
; output:
;   rax - eof token
_make_eof:
    push r8
    mov r8, rax
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+token_type_offset],        TOKEN_EOF
    mov       [rax+token_start_index_offset],        r8
    mov       [rax+token_end_index_offset],          r8
    pop r8
    ret

; input:
;   rax - index of current character
; output:
;   rax - address of left paren token
_make_left_paren:
    push r8
    mov r8, rax
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+token_type_offset],        TOKEN_LEFT_PAREN
    mov       [rax+token_start_index_offset], r8
    inc r8
    mov       [rax+token_end_index_offset],   r8
    pop r8
    ret

; input:
;   rax - index of current character
; output:
;   rax - address of left paren token
_make_right_paren:
    push r8
    mov r8, rax
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+token_type_offset],        TOKEN_RIGHT_PAREN
    mov       [rax+token_start_index_offset], r8
    inc r8
    mov       [rax+token_end_index_offset],   r8
    pop r8
    ret

; input:
;   rax - address of lexer object
; output:
;   rax - next character of input string
_lexer_peek_next_character:
    push rsi
    push rdi
    mov rsi, [rax+input_string_offset]
    mov rdi, [rax+next_character_index_offset]
    call _string_char_at
    pop rdi
    pop rsi
    ret

; input:
;   rax - address of lexer
_lexer_advance:
    push rdi
    push rsi
    push r8
    push r9
    mov r8, rax
    ; increment position
    mov r9, [r8+next_character_index_offset]
    inc r9
    mov [r8+next_character_index_offset], r9
    ; at end of input?
    mov rax, [r8+input_string_offset]
    call _string_length
    cmp r9, rax
    je .done
    ; if next character is newline, increment line count
    mov rsi, [r8+input_string_offset]
    mov rdi, [r8+next_character_index_offset]
    call _string_char_at
    cmp rax, newline_char
    jne .done
    mov r9, [r8+line_number_offset]
    inc r9
    mov [r8+line_number_offset], r9
.done:
    pop r9
    pop r8
    pop rsi
    pop rdi
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
    mov rax, [r12+input_string_offset]
    call _string_length
    mov r13, rax
.start:
    ; if past the end of input string, return EOF token
    mov r14, [r12+next_character_index_offset]
    cmp r14, r13
    jl .read_next_character
    mov rax, r13
    call _make_eof
    jmp .done
.read_next_character:
    mov rax, r12
    call _lexer_peek_next_character
    push rax
    mov rax, r12
    call _lexer_advance
    pop rax
.skip_unused_chars:
    ; skip whitespace and control characters
    cmp al, space_char
    jle .start
    ; skip del and extended characters
    cmp al, del_char
    jge .start
    ; skip comments
    cmp al, semicolon_char
    jne .left_paren
.skip_to_newline:
    ; if character is newline, then start tokenizing again
    cmp al, newline_char 
    je .start
    ; otherwise read next character 
    mov rax, r12
    call _lexer_peek_next_character
    push rax
    mov rax, r12
    call _lexer_advance
    pop rax
    jmp .skip_to_newline
.left_paren:
    cmp al, left_paren_char
    jne .right_paren
    mov rax, [r12+next_character_index_offset]
    dec rax
    call _make_left_paren
    jmp .done
.right_paren:
    cmp al, right_paren_char
    jne .string
    mov rax, [r12+next_character_index_offset]
    dec rax
    call _make_right_paren
    jmp .done
.string:
    cmp al, double_quote_char
    jne .integer
    mov r15, [r12+next_character_index_offset]
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+token_type_offset], TOKEN_STRING
    mov       [rax+token_start_index_offset], r15    ; position of first character
    mov r14, rax
.string_loop:
    mov r15, [r12+next_character_index_offset]
    cmp r15, r13
    je .string_done
    mov rax, r12
    call _lexer_peek_next_character
    push rax
    mov rax, r12
    call _lexer_advance
    pop rax
    ; stop at next "
    cmp al, double_quote_char
    jne .string_loop 
.string_done:
    mov r15, [r12+next_character_index_offset]
    dec r15
    mov [r14+token_end_index_offset], r15
    ; copy string into token
    mov rax, [r12+input_string_offset]        ; input string
    mov r8,  [r14+token_start_index_offset]   ; from index
    mov r9,  [r14+token_end_index_offset]     ; to index
    call _substring
    mov [r14+token_value_offset], rax
    mov rax, r14
    jmp .done
.integer:
    ; first digit
    cmp al, ascii_digit_offset + 0
    jl .symbol
    cmp al, ascii_digit_offset + 9
    jg .symbol
    ; accumulate integer value into r8
    sub rax, ascii_digit_offset
    mov r8, rax
    ; create token
    mov r15, [r12+next_character_index_offset]
    dec r15
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+token_type_offset], TOKEN_INTEGER
    mov       [rax+token_start_index_offset], r15
    mov r14, rax
.integer_next_digit:
    mov rax, r12
    call _lexer_peek_next_character
    cmp al, ascii_digit_offset + 0 
    jl .integer_done
    cmp al, ascii_digit_offset + 9 
    jg .integer_done
    push rax
    ; multiply previous value by 10 and add value of new digit
    mov rax, 10
    mul r8
    mov r8, rax
    pop rax
    sub rax, ascii_digit_offset
    add r8, rax
    mov rax, r12
    call _lexer_advance
    jmp .integer_next_digit 
.integer_done:
    mov r15, [r12+next_character_index_offset]
    mov [r14+token_end_index_offset], r15
    mov [r14+token_value_offset], r8      ; integer value
    mov rax, r14
    jmp .done
.symbol:
    ; can't start with tokens less than ! and greater than ~
    cmp al, bang_char
    jl .next
    cmp al, tilde_char
    jg .next
    ; start index
    mov r15, [r12+next_character_index_offset]
    dec r15
    ; make the symbol token
    mov rax, SIZEOF_TOKEN
    call _malloc
    mov qword [rax+token_type_offset],        TOKEN_SYMBOL
    mov       [rax+token_start_index_offset], r15
    mov r15, rax 
.symbol_next_character:
    mov rax, r12
    call _lexer_peek_next_character
    ; done if the next character isn't a legal symbol character
    cmp al, bang_char
    jl .symbol_done
    cmp al, tilde_char
    jg .symbol_done
    cmp al, left_paren_char
    je .symbol_done
    cmp al, right_paren_char
    je .symbol_done
    mov rax, r12
    call _lexer_advance
    jmp .symbol_next_character
.symbol_done:
    mov rax, [r12+next_character_index_offset]
    mov [r15+token_end_index_offset], rax
    ; copy string into token 
    mov rax, [r12+input_string_offset]        ; input string
    mov r8,  [r15+token_start_index_offset]   ; from index
    mov r9,  [r15+token_end_index_offset]     ; to index
    call _substring
    mov [r15+token_value_offset], rax
    mov rax, r15
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
    eof_token:           db "[EOF]"
    left_paren_token:    db "[LEFT_PAREN]"
    right_paren_token:   db "[RIGHT_PAREN]"
    string_token_start:  db "[STRING ", double_quote_char
    string_token_end:    db double_quote_char, "]"
    integer_token_start: db "[INTEGER "
    integer_token_end:   db "]"
    symbol_token_start:  db "[SYMBOL "
    symbol_token_end:    db "]"

section .text

; input:
;   rax - address of token object
global _print_token
_print_token:
    push r12
    mov r12, rax
.eof:
    mov rcx, [r12+token_type_offset]     ; type tag
    cmp rcx, TOKEN_EOF
    jne .left_paren
    call _new_string
    mov rsi, eof_token
    mov rcx, 5
    call _append_from_buffer
    call _print_string
    jmp .done
.left_paren:
    mov rcx, [r12+token_type_offset]
    cmp rcx, TOKEN_LEFT_PAREN
    jne .right_paren
    call _new_string
    mov rsi, left_paren_token
    mov rcx, 12
    call _append_from_buffer
    call _print_string
    jmp .done
.right_paren:
    mov rcx, [r12+token_type_offset]
    cmp rcx, TOKEN_RIGHT_PAREN
    jne .string
    call _new_string
    mov rsi, right_paren_token
    mov rcx, 13
    call _append_from_buffer
    call _print_string
    jmp .done
.string:
    mov rcx, [r12+token_type_offset]
    cmp rcx, TOKEN_STRING
    jne .integer
    call _new_string
    ; prefix
    mov rsi, string_token_start
    mov rcx, 9
    call _append_from_buffer
    ; string
    mov rsi, [r12+token_value_offset]
    call _string_append
    ; suffix
    mov rsi, string_token_end
    mov rcx, 2
    call _append_from_buffer
    call _print_string
    jmp .done
.integer:
    mov rcx, [r12+token_type_offset]
    cmp rcx, TOKEN_INTEGER
    jne .symbol
    call _new_string
    ; prefix
    mov rsi, integer_token_start
    mov rcx, 9
    call _append_from_buffer
    ; integer value
    push rax
    mov rax, [r12+token_value_offset]
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
    mov rcx, [r12+token_type_offset]
    cmp rcx, TOKEN_SYMBOL
    jne .error
    call _new_string
    ; prefix
    mov rsi, symbol_token_start
    mov rcx, 8
    call _append_from_buffer
    ; string
    mov rsi, [r12+token_value_offset]
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
    call _lexer_new
    mov r8, rax
    mov r9, [rax+token_vec_offset]           ; vec to store tokens
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



