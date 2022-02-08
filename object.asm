%include "constants.inc"
%include "memory.inc"

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
    push rax
    mov rax, SIZEOF_INTEGER_OBJ
    call _malloc
    mov qword [rax+0], TYPE_INTEGER_OBJ
    pop rcx
    mov [rax+8], rcx
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
   push rax
   mov rax, SIZEOF_SYMBOL_OBJ
   call _malloc
   mov qword [rax+0], TYPE_SYMBOL_OBJ
   pop rcx
   mov [rax+8], rcx
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








