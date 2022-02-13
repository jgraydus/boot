%include "constants.inc"
%include "memory.inc"
%include "string.inc"

section .text

; list object 
;
; struct {
;      qword,      ; type
;      ptr,        ; address of object data
;      ptr,        ; address of next node (for list objects)
; }

SIZEOF_LIST_OBJ         equ 24

; input:
;   rax - address of object data
;   rcx - address of next list node (should be set to 0 if there is no next node)
; output:
;   rax - address of new list object
global _make_list_obj
_make_list_obj:
    push rcx
    push rax
    mov rax, SIZEOF_LIST_OBJ
    call _malloc
    mov qword [rax+0], TYPE_LIST_OBJ
    pop rcx
    mov [rax+8], rcx
    pop rcx
    mov [rax+16], rcx 
    ret


; integer object 
;
; struct {
;     qword,        ; type
;     qword,        ; integer value
; }

SIZEOF_INTEGER_OBJ          equ 16

; input:
;   rax - integer value of object
; output:
;   rax - address of new integer object
global _make_integer_obj
_make_integer_obj:
    push rcx
    mov rcx, rax
    mov rax, SIZEOF_INTEGER_OBJ
    call _malloc
    mov qword [rax+0], TYPE_INTEGER_OBJ
    mov [rax+8], rcx
    pop rcx
    ret



; symbol object
;
; struct {
;     qword,         ; type
;     ptr,           ; address of string
; }

SIZEOF_SYMBOL_OBJ           equ 16

; input:
;   rax - address of string
; output:
;   rax - address of new symbol obj
global _make_symbol_obj
_make_symbol_obj:
   push rcx
   mov rcx, rax
   mov rax, SIZEOF_SYMBOL_OBJ
   call _malloc
   mov qword [rax+0], TYPE_SYMBOL_OBJ
   mov [rax+8], rcx
   pop rcx
   ret



; function object
;
; struct {
;     qword,            ; type
;     ptr,              ; address of formal parameters (list of symbols)
;     ptr,              ; address of environment
;     ptr,              ; address of body of function
; }

SIZEOF_FUNCTION_OBJ          equ 32

; input:
;   rax - address of formal param list
;   rcx - address of environment
;   rdx - address of function body
global _make_function_obj
_make_function_obj:
    push rdx
    push rcx
    push rax
    mov rax, SIZEOF_FUNCTION_OBJ
    call _malloc
    mov qword [rax+0], TYPE_FUNCTION_OBJ
    pop rcx
    mov [rax+8], rcx
    pop rcx
    mov [rax+16], rcx
    pop rcx
    mov [rax+24], rcx
    ret


section .rodata
    double_quote: db 34

section .text

; input:
;   rax - address of object
; output:
;   rax - address of string
global _object_to_string
_object_to_string:
    push rcx
    push rsi
    push rbx
    mov rbx, rax
    mov rax, [rbx+0]

.symbol:
    cmp rax, TYPE_SYMBOL_OBJ
    jne .string
    mov rax, [rbx+8]
    jmp .done

.string:
    cmp rax, TYPE_STRING_OBJ
    jne .integer
    call _new_string
    mov rsi, double_quote
    mov rcx, 1
    call _append_from_buffer
    mov rsi, rbx
    call _string_append
    mov rsi, double_quote
    mov rcx, 1
    call _append_from_buffer
    jmp .done

.integer:
    ; TODO

.done:
    pop rbx
    pop rsi
    pop rcx
    ret








