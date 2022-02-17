%include "constants.inc"
%include "memory.inc"
%include "string.inc"

section .text

; pair object 
;
; struct {
;      qword,      ; type
;      ptr,        ; address of head object
;      ptr,        ; address of tail object
; }

%define SIZEOF_PAIR_OBJ      24

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
    mov qword [rax+0], TYPE_PAIR_OBJ
    pop rcx
    mov [rax+8], rcx
    pop rcx
    mov [rax+16], rcx 
    ret

; input:
;   rax - address of pair object
; output:
;   rax - address of head of the pair
global _get_pair_head
_get_pair_head:
    mov rax, [rax+8]
    ret

; input:
;   rax - address of pair to modify
;   rcx - value to set
; output:
;   rax - address of pair (unchanged)
global _set_pair_head
_set_pair_head:
    mov [rax+8], rcx
    ret

; input:
;   rax - address of pair object
; output:
;   rax - address of tail of the pair
global _get_pair_tail
_get_pair_tail:
    mov rax, [rax+16]
    ret

; input:
;   rax - address of pair to modify
;   rcx - value to set
; output:
;   rax - address of pair (unchanged)
global _set_pair_tail
_set_pair_tail:
    mov [rax+16], rcx
    ret

; integer object 
;
; struct {
;     qword,        ; type
;     qword,        ; integer value
; }

%define SIZEOF_INTEGER_OBJ   16

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

%define SIZEOF_SYMBOL_OBJ    16

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



; procedure object
;
; struct {
;     qword,            ; type
;     ptr,              ; address of formal parameters (list of symbols)
;     ptr,              ; address of environment
;     ptr,              ; address of body of function
; }

%define SIZEOF_PROCEDURE_OBJ   32

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
    mov qword [rax+0], TYPE_PROCEDURE_OBJ
    pop rcx
    mov [rax+8], rcx
    pop rcx
    mov [rax+16], rcx
    pop rcx
    mov [rax+24], rcx
    ret


section .rodata
    double_quote: db 34
    function_string: db "<PROCEDURE>"
    nil_object: db "()"
    left_paren: db "("
    right_paren: db ")"
    space: db " "

section .text

; input:
;   rax - address of object
; output:
;   rax - address of string
global _object_to_string
_object_to_string:
    push r8
    push r9
    push rcx
    push rsi
    push rbx

    ; check for nil
    cmp rax, 0
    jne .go
    call _new_string
    mov rsi, nil_object
    mov rcx, 2
    call _append_from_buffer
    jmp .done

.go:
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
    cmp rax, TYPE_INTEGER_OBJ
    jne .procedure
    mov rax, [rbx+8]
    call _string_from_integer
    jmp .done

.procedure:
    cmp rax, TYPE_PROCEDURE_OBJ
    jne .list
    call _new_string
    mov rsi, function_string
    mov rcx, 10
    call _append_from_buffer
    jmp .done

.list:
    cmp rax, TYPE_PAIR_OBJ
    jne .error
    call _new_string
    mov rsi, left_paren
    mov rcx, 1
    call _append_from_buffer
    mov r8, rax   ; hold the string
    mov r9, rbx   ; hold next list node
.list_next:
    mov rax, [r9+8]  ; object in list
    call _object_to_string
    mov rsi, rax
    mov rax, r8 
    call _string_append
    mov r9, [r9+16]  ; tail of the list
    ; if the tail is nil, then done
    cmp r9, 0
    je .list_done
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
    mov rax, [r8+0]
    cmp rax, [r9+0]
    jne .not_equal
    ; compare based on object type
    cmp rax, TYPE_PAIR_OBJ
    jne .string
    ; first compare the head of head pair
    mov rax, [r8+8]
    mov rcx, [r9+8]
    call _obj_equals
    cmp rax, 0
    je .not_equal
    ; then compare the tail of each pair
    mov rax, [r8+16]
    mov rcx, [r8+16]
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
    mov rax, [r8+8]      ; compare the integer values
    cmp rax, [r9+8]
    je .equal
    jmp .not_equal
.symbol:
    cmp rax, TYPE_SYMBOL_OBJ
    jne .function
    mov rax, [r8+8]      ; compare the string values
    mov rcx, [r9+8]
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
    mov rax, [rax+0]
    ret







