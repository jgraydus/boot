%include "memory.inc"
%include "vec.inc"

; stack

%define STACK_VEC_SIZE        16

; output:
;   rax - address of stack
global _stack_new
_stack_new:
    mov rax, STACK_VEC_SIZE
    call _vec_new
    ret

; input:
;   rax - address of stack
; output:
;   rax - number of items in the stack
global _stack_size
_stack_size:
    call _vec_length
    ret

; input:
;   rax - address of stack
;   rsi - value to push onto stack
; output:
;   rax - address of stack (unchanged)
global _stack_push
_stack_push:
    call _vec_append
    ret

; input:
;   rax - address of stack
; output:
;   rax - most recent item pushed to stack (or 0 if stack is empty)
global _stack_pop
_stack_pop:
    push r8
    push rsi
    mov r8, rax
    call _vec_length    ; compute index of last item
    cmp rax, 0
    je .done
    dec rax
    mov rsi, rax
    mov rax, r8
    call _vec_remove
.done:
    pop rsi
    pop r8
    ret

; input:
;   rax - address of stack
; output:
;   rax - most recent item pushed to stack (or 0 if stack is empty)
global _stack_peek
_stack_peek:
    push r8
    push rsi
    mov r8, rax
    call _vec_length
    cmp rax, 0
    je .done
    dec rax
    mov rsi, rax
    mov rax, r8
    call _vec_get_value_at
.done
    pop rsi
    pop r8
    ret

; input:
;   rax - address of stack
global _stack_free
_stack_free:
    call _vec_free
    ret

; input
;   rax - address of stack
;   rsi - address of function to call for each element of vec (passed in rax)
global _stack_for_each
_stack_for_each:
    call _vec_for_each
    ret

