%include "constants.inc"
%include "gc.inc"
%include "memory.inc"
%include "string.inc"
%include "vec.inc"
%include "print.inc"

section .text

%define object_type_offset    0
%define object_flags_offset   8

; pair object 
;
; struct {
;      qword,      ; type
;      qword,      ; flags
;      ptr,        ; address of head object
;      ptr,        ; address of tail object
; }

%define SIZEOF_PAIR_OBJ      32

; input:
;   rax - address of head object
;   rcx - address of tail object
; output:
;   rax - address of new pair object
global _make_pair_obj
_make_pair_obj:
    push rcx
    push rax
    mov rax, SIZEOF_PAIR_OBJ
    call _malloc
    mov qword [rax+object_type_offset], TYPE_PAIR_OBJ   ; type
    mov qword [rax+object_flags_offset], 0               ; flags
    pop rcx
    mov [rax+16], rcx                  ; head
    pop rcx
    mov [rax+24], rcx                  ; tail
    call _gc_register_obj
    ret

; input:
;   rax - address of pair object
; output:
;   rax - address of head of the pair
global _get_pair_head
_get_pair_head:
    mov rax, [rax+16]
    ret

; input:
;   rax - address of pair to modify
;   rcx - value to set
; output:
;   rax - address of pair (unchanged)
global _set_pair_head
_set_pair_head:
    mov [rax+16], rcx
    ret

; input:
;   rax - address of pair object
; output:
;   rax - address of tail of the pair
global _get_pair_tail
_get_pair_tail:
    mov rax, [rax+24]
    ret

; input:
;   rax - address of pair to modify
;   rcx - value to set
; output:
;   rax - address of pair (unchanged)
global _set_pair_tail
_set_pair_tail:
    mov [rax+24], rcx
    ret

; integer object 
;
; struct {
;     qword,        ; type
;     qword,        ; flags
;     qword,        ; integer value
; }

%define SIZEOF_INTEGER_OBJ   24

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
    mov qword [rax+object_type_offset], TYPE_INTEGER_OBJ
    mov qword [rax+object_flags_offset], 0
    mov [rax+16], rcx
    call _gc_register_obj
    pop rcx
    ret

; input:
;   rax - address of integer object
; output:
;   rax - integer value
global _integer_get_value
_integer_get_value:
    mov rax, [rax+16]
    ret

; symbol object
;
; struct {
;     qword,         ; type
;     qword,         ; flags
;     ptr,           ; address of string
; }

%define SIZEOF_SYMBOL_OBJ    24
%define symbol_string_offset 16 

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
   mov qword [rax+object_type_offset], TYPE_SYMBOL_OBJ
   mov qword [rax+object_flags_offset], 0
   mov [rax+symbol_string_offset], rcx
   call _gc_register_obj
   pop rcx
   ret

global _symbol_get_string
_symbol_get_string:
    mov rax, [rax+symbol_string_offset]
    ret

section .rodata
     true_txt:   db "#t"
     true_txt_len: equ $-true_txt
     false_txt:  db "#f"
     false_txt_len: equ $-false_txt

%macro _symbol_is 1
section .rodata
    %%str: db %1
    %%len: equ $-%%str
section .text
    push r8
    push r9
    mov r8, [rax+0]
    cmp r8, TYPE_SYMBOL_OBJ
    jne .not
    mov rax, [rax+symbol_string_offset]
    mov r8, %%str    ; buffer
    mov r9, %%len    ; length
    call _string_equals_buffer
    jmp .done
.not:
    mov rax, 0
.done:
    pop r9
    pop r8
    ret
%endmacro

section .text

; input:
;   rax - address of symbol
; ouptut:
;   rax - 1 if the symbol is define, 0 otherwise
global _symbol_is_define
_symbol_is_define:
    _symbol_is "define"

; input:
;   rax - address of symbol
; ouptut:
;   rax - 1 if the symbol is set!, 0 otherwise

global _symbol_is_set
_symbol_is_set:
    _symbol_is "set!"

; input:
;   rax - address of symbol
; ouptut:
;   rax - 1 if the symbol is fn, 0 otherwise
global _symbol_is_fn
_symbol_is_fn:
    _symbol_is "fn"

; input:
;   rax - address of symbol
; ouptut:
;   rax - 1 if the symbol is fn, 0 otherwise
global _symbol_is_macro
_symbol_is_macro:
    _symbol_is "macro"

; input:
;   rax - address of symbol
; ouptut:
;   rax - 1 if the symbol is quote, 0 otherwise
global _symbol_is_quote
_symbol_is_quote:
    _symbol_is "quote"

; input:
;   rax - address of symbol
; ouptut:
;   rax - 1 if the symbol is unquote, 0 otherwise
global _symbol_is_unquote
_symbol_is_unquote:
    _symbol_is "unquote"

global _symbol_is_if
_symbol_is_if:
    _symbol_is "if"

global _symbol_is_true
_symbol_is_true:
    _symbol_is "#t"

global _symbol_is_false
_symbol_is_false:
    _symbol_is "#f"

global _symbol_is_loop
_symbol_is_loop:
    _symbol_is "loop"

global _symbol_true
_symbol_true:
    push rsi
    push rcx
    call _string_new
    mov rsi, true_txt
    mov rcx, true_txt_len
    call _append_from_buffer
    call _make_symbol_obj
    pop rcx
    pop rsi
    ret

global _symbol_false
_symbol_false:
    push rsi
    push rcx
    call _string_new
    mov rsi, false_txt
    mov rcx, false_txt_len
    call _append_from_buffer
    call _make_symbol_obj
    pop rcx
    pop rsi
    ret

global _symbol_is_with_continue_from_here
_symbol_is_with_continue_from_here:
    _symbol_is "with-continue-from-here"

; procedure object
;
; struct {
;     qword,            ; type
;     qword,            ; flags
;     ptr,              ; address of formal parameters (list of symbols)
;     ptr,              ; address of environment
;     ptr,              ; address of body of function
; }

%define SIZEOF_PROCEDURE_OBJ   40
%define proc_params_offset     16
%define proc_env_offset        24
%define proc_body_offset       32

; input:
;   rax - address of formal param list
;   rcx - address of environment
;   rdx - address of procedure body
global _make_procedure_obj
_make_procedure_obj:
    push rdx
    push rcx
    push rax
    mov rax, SIZEOF_PROCEDURE_OBJ
    call _malloc
    mov qword [rax+object_type_offset], TYPE_PROCEDURE_OBJ
    mov qword [rax+object_flags_offset], 0
    pop rcx
    mov [rax+proc_params_offset], rcx
    pop rcx
    mov [rax+proc_env_offset], rcx
    pop rcx
    mov [rax+proc_body_offset], rcx
    call _gc_register_obj
    ret

global _get_proc_formal_params
_get_proc_formal_params:
    mov rax, [rax+proc_params_offset]
    ret

global _get_proc_env
_get_proc_env:
    mov rax, [rax+proc_env_offset]
    ret

global _get_proc_body
_get_proc_body:
    mov rax, [rax+proc_body_offset]
    ret

global _get_proc_macro_flag
_get_proc_macro_flag:
    mov rax, [rax+object_flags_offset]
    and rax, PROC_MACRO_FLAG
    cmp rax, 0
    je .done
    mov rax, 1
.done:
    ret

global _set_proc_macro_flag
_set_proc_macro_flag:
    or QWORD [rax+object_flags_offset], PROC_MACRO_FLAG
    ret

global _get_continuation_flag
_get_continuation_flag:
    mov rax, [rax+object_flags_offset]
    and rax, CONTINUATION_FLAG
    cmp rax, 0
    je .done
    mov rax, 1
.done:
    ret


; input:
;   rax - pointer to native code
; output:
;   rax - address of new procedure object wrapping the given native code
global _make_intrinsic_obj
_make_intrinsic_obj:
    push r8
    mov r8, rax
    mov rax, SIZEOF_PROCEDURE_OBJ
    call _malloc
    mov qword [rax+object_type_offset], TYPE_PROCEDURE_OBJ
    mov qword [rax+object_flags_offset], INTRINSIC_PROC_FLAG
    mov qword [rax+proc_params_offset], 0
    mov qword [rax+proc_env_offset], 0
    mov [rax+proc_body_offset], r8
    call _gc_register_obj
    pop r8
    ret

; input:
;   rax - value of rsp to restore when continuation is invoked
; output
;   rax - address of new continuation object
global _make_continuation_obj
_make_continuation_obj:
    push r8
    mov r8, rax
    mov rax, SIZEOF_PROCEDURE_OBJ
    call _malloc
    mov qword [rax+object_type_offset], TYPE_PROCEDURE_OBJ
    mov qword [rax+object_flags_offset], CONTINUATION_FLAG
    mov qword [rax+proc_params_offset], 0   ; unused
    mov qword [rax+proc_env_offset], 0      ; unused
    mov [rax+proc_body_offset], r8          ; the BSP value to restore
    call _gc_register_obj
    pop r8
    ret

global _proc_is_intrinsic
_proc_is_intrinsic:
    mov rax, [rax+object_flags_offset]
    and rax, INTRINSIC_PROC_FLAG
    cmp rax, INTRINSIC_PROC_FLAG
    je .yes
    mov rax, 0
    jmp .done
.yes:
    mov rax, 1
.done:
    ret

section .rodata
    double_quote: db 34
    function_string: db "<PROCEDURE>"
    nil_object: db "()"
    left_paren: db "("
    right_paren: db ")"
    space: db " "
    pair_sep: db " . "

section .text

; input:
;   rax - address of object
; output:
;   rax - address of string
global _object_to_string
_object_to_string:
    push r8
    push r9
    push r10
    push r11
    push rcx
    push rsi
    push rbx
    ; check for nil
    cmp rax, 0
    jne .go
    call _string_new
    mov rsi, nil_object
    mov rcx, 2
    call _append_from_buffer
    jmp .done
.go:
    mov rbx, rax
    mov rax, [rbx+object_type_offset]
.symbol:
    cmp rax, TYPE_SYMBOL_OBJ
    jne .string
    mov rax, rbx
    call _symbol_get_string
    jmp .done
.string:
    cmp rax, TYPE_STRING_OBJ
    jne .integer
    call _string_new
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
    cmp rax, TYPE_INTEGER_OBJ
    jne .procedure
    mov rax, rbx
    call _integer_get_value
    call _string_from_integer
    jmp .done
.procedure:
    cmp rax, TYPE_PROCEDURE_OBJ
    jne .pair
    call _string_new
    mov rsi, function_string
    mov rcx, 11
    call _append_from_buffer
    jmp .done
.pair:
    cmp rax, TYPE_PAIR_OBJ
    jne .error
    ; if tail is not nil or a list, print as a dotted pair
    mov rax, rbx
    call _get_pair_tail
    cmp rax, 0
    je .list
    mov rax, [rax+object_type_offset]
    cmp rax, TYPE_PAIR_OBJ
    je .list
    ; head to string
    mov rax, rbx
    call _get_pair_head
    call _object_to_string
    mov r10, rax
    ; tail to string
    mov rax, rbx
    call _get_pair_tail
    call _object_to_string
    mov r11, rax
    ; build the string
    call _string_new
    mov rsi, left_paren           ; (
    mov rcx, 1
    call _append_from_buffer
    mov rsi, r10                  ; <head> 
    call _string_append
    mov rsi, pair_sep             ; " . "
    mov rcx, 3
    call _append_from_buffer
    mov rsi, r11                  ; <tail>
    call _string_append
    mov rsi, right_paren          ; )
    mov rcx, 1
    call _append_from_buffer
    jmp .done 
.list:
    mov rax, [rbx+object_type_offset]
    cmp rax, TYPE_PAIR_OBJ
    jne .error
    call _string_new
    mov rsi, left_paren
    mov rcx, 1
    call _append_from_buffer
    mov r8, rax   ; hold the string
    mov r9, rbx   ; hold next list node
.list_next:
    mov rax, rbx
    call _get_pair_head   ; object in list
    call _object_to_string
    mov rsi, rax
    mov rax, r8 
    call _string_append
    mov rax, rbx
    call _get_pair_tail
    ; if the tail is nil, then done
    cmp rax, 0
    je .list_done
    mov rbx, rax
    ; append a space character
    mov rax, r8
    mov rsi, space
    mov rcx, 1
    call _append_from_buffer
    jmp .list_next
.list_done:
    mov rax, r8
    mov rsi, right_paren
    mov rcx, 1
    call _append_from_buffer
    jmp .done
.error:
    ; TODO
.done:
    pop rbx
    pop rsi
    pop rcx
    pop r11
    pop r10
    pop r9
    pop r8
    ret

;l input:
;    rax - address of an object
;    rcx - address of an object
;  output:
;    rax - 1 if the objects are equal, 0 otherwise
global _obj_equals
_obj_equals:
    push r8
    push r9
    mov r8, rax
    mov r9, rcx
    ; if both objects are null, they are equal
    ; if only one of them is null, they are NOT equal
    cmp rax, 0
    je .first_null
    cmp rcx, 0          ; rax is not null here
    jne .both_not_null
    jmp .not_equal      ; rax is not null, rcx is null. not equal
.first_null:
    cmp rcx, 0
    je .equal           ; both null. equal
    jmp .not_equal      ; rax is null, rcx is not null. not equal
.both_not_null:
    ; check that both object have the same type
    mov rax, [r8+object_type_offset]
    cmp rax, [r9+object_type_offset]
    jne .not_equal
    ; compare based on object type
    cmp rax, TYPE_PAIR_OBJ
    jne .string
    ; first compare the head of head pair
    mov rax, r9
    call _get_pair_head
    mov rcx, rax
    mov rax, r8
    call _get_pair_head
    call _obj_equals
    cmp rax, 0
    je .not_equal
    ; then compare the tail of each pair
    mov rax, r9
    call _get_pair_tail
    mov rcx, rax
    mov rax, r8
    call _get_pair_tail
    call _obj_equals
    jmp .done
.string: 
    cmp rax, TYPE_STRING_OBJ
    jne .integer
    mov rax, r8
    mov rcx, r9
    call _string_equals
    jmp .done
.integer:
    cmp rax, TYPE_INTEGER_OBJ
    jne .symbol
    mov rax, r9
    call _integer_get_value
    mov rcx, rax
    mov rax, r8
    call _integer_get_value
    cmp rax, rcx
    je .equal
    jmp .not_equal
.symbol:
    cmp rax, TYPE_SYMBOL_OBJ
    jne .function
    mov rax, r9
    call _symbol_get_string
    mov rcx, rax
    mov rax, r8
    call _symbol_get_string
    call _obj_equals
    jmp .done
.function:
    cmp rax, TYPE_PROCEDURE_OBJ
    jne .not_equal
    ; functions are unique, so can only be equal to themselves
    cmp r8, r9
    jne .not_equal
    jmp .equal
.equal:
    mov rax, 1
    jmp .done
.not_equal:
    mov rax, 0
.done:
    pop r9
    pop r8
    ret

; input:
;   rax - address of object
; output:
;   rax - type tag of object
global _obj_type
_obj_type:
    mov rax, [rax+object_type_offset]
    ret

; input:
;   rax - address of object
;   rdx - flag
; output:
;   rax - 1 if the flag is set. 0 if the flag is not set
global _obj_get_flag
_obj_get_flag:
    push r8
    mov r8, [rax+object_flags_offset]
    and r8, rdx
    cmp r8, 0
    je .false
    mov rax, 1
    jmp .done
.false:
    mov rax, 0
.done:
    pop r8
    ret

; input:
;   rax - address of object
;   rdx - flag
; output:
;   rax - address of object
global _obj_set_flag
_obj_set_flag:
    or [rax+object_flags_offset], rdx
    ret

; input:
;   rax - address of object
;   rdx - flag
; output:
;   rax - address of object
global _obj_unset_flag
_obj_unset_flag:
    not rdx
    and [rax+object_flags_offset], rdx
    not rdx
    ret

