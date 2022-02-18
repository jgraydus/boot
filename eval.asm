%include "constants.inc"
%include "env.inc"
%include "object.inc"

section .text

; input
;   rax - object to evaluate
;   rsi - address of environment
; output:
;   rax - resulting value of evaluating the input
global _eval
_eval:
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    ; remember the input
    mov r8, rax    ; object
    mov r9, rsi    ; environment
    ; null evaluates to null
    cmp r8, 0
    jne .go
    mov rax, 0
    jmp .done
.go:
    ; get the type tag for the object
    mov rax, r8
    call _obj_type
.symbol:
    ; look up symbol in the environment
    cmp rax, TYPE_SYMBOL_OBJ
    jne .pair
    mov rax, r9
    mov rcx, r8
    call _env_lookup
    jmp .done
.pair:
    ; evaluation of a pair is either a function application
    ; or a special form
    cmp rax, TYPE_PAIR_OBJ
    jne .other
    mov rax, r8
    call _get_pair_head
    mov r10, rax
; special forms
.define:
    call _symbol_is_define
    cmp rax, 1
    jne .set
    mov rax, r8
    call _get_pair_tail
    mov r11, rax
    call _get_pair_head    ; this is the symbol to bind
    mov r12, rax          
    mov rax, r11
    call _get_pair_tail
    call _get_pair_head    ; this is the value to bind
    mov rsi, r9
    call _eval
    mov rdi, rax   ; value
    mov rsi, r12   ; symbol
    mov rax, r9    ; env
    call _env_add_binding
    mov rax, 0   ; the result is nil
    jmp .done
.set:
    mov rax, r10
    call _symbol_is_set
    cmp rax, 1
    jne .fn
    ; TODO
    jmp .done
.fn:
    mov rax, r10
    call _symbol_is_fn
    cmp rax, 1
    jne .quote
    ; TODO 
    jmp .done
.quote:
    mov rax, r10
    call _symbol_is_quote
    jne .apply_proc
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    jmp .done
; end of special forms
.apply_proc:

.other:
    ; other object types evaluate to themselves
    ; strings evaluate to themselves
    mov rax, r8
    jmp .done
.error:
    ; TODO 
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    ret


