%include "memory.inc"
%include "vec.inc"

; stack
;
; struct {
;    ptr,      ; vec
;    qword,    ; size
; }

%define stack_vec_offset      0
%define stack_size_offset     8
%define SIZEOF_STACK          16
%define STACK_VEC_SIZE        16

; output:
;   rax - address of stack
global _new_stack
_new_stack:
    push rbx
    mov rax, STACK_VEC_SIZE
    call _vec_new
    mov rbx, rax
    mov rax, SIZEOF_STACK
    call _malloc
    mov [rax], rbx   ; vec
    mov qword [rax+stack_size_offset], 0   ; size
    pop rbx
    ret

; input:
;   rax - address of stack
; output:
;   rax - number of items in the stack
global _stack_size
_stack_size:
    mov rax, [rax+stack_size_offset]
    ret

; input:
;   rax - address of stack
;   rsi - value to push onto stack
; output:
;   rax - address of stack (unchanged)
global _stack_push
_stack_push:
    push rbx
    mov rbx, rax
    mov rax, [rbx+stack_vec_offset]    ; vec
    call _vec_append
    mov rax, [rbx+stack_size_offset]    ; increment the size
    inc rax
    mov [rbx+stack_size_offset], rax
    mov rax, rbx
    pop rbx
    ret

; input:
;   rax - address of stack
; output:
;   rax - most recent item pushed to stack (or 0 if stack is empty)
global _stack_pop
_stack_pop:
    push rbx
    mov rbx, rax
    mov rax, [rbx+stack_size_offset]
    cmp rax, 0
    je .done
    dec rax            ; decrement count
    mov [rbx+stack_size_offset], rax
    mov rsi, rax       ; index of last item
    mov rax, [rbx+stack_vec_offset]   ; vec
    call _vec_get_value_at
.done:
    pop rbx
    ret

; input:
;   rax - address of stack
global _stack_free
_stack_free:
    push r8
    mov r8, rax
    mov rax, [r8+stack_vec_offset]
    call _vec_free
    mov rax, r8
    call _free
    pop r8     
    ret







