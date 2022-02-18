%include "memory.inc"
%include "vec.inc"

; stack
;
; struct {
;    ptr,      ; vec
;    qword,    ; size
; }

%define SIZEOF_STACK 16

; output:
;   rax - address of stack
global _new_stack
_new_stack:
    push rbx
    mov rax, 16
    call _new_vec
    mov rbx, rax
    mov rax, SIZEOF_STACK
    call _malloc
    mov [rax], rbx   ; vec
    mov qword [rax+8], 0   ; size
    pop rbx
    ret

; input:
;   rax - address of stack
; output:
;   rax - number of items in the stack
global _stack_size
_stack_size:
    mov rax, [rax+8]
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
    mov rax, [rbx+0]    ; vec
    call _vec_append
    mov rax, [rbx+8]    ; increment the size
    inc rax
    mov [rbx+8], rax
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
    mov rax, [rbx+8]
    cmp rax, 0
    je .done
    dec rax            ; decrement count
    mov [rbx+8], rax
    mov rsi, rax       ; index of last item
    mov rax, [rbx+0]   ; vec
    call _vec_get_value_at
.done:
    pop rbx
    ret


