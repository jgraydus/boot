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
    cmp rax, TYPE_SYMBOL_OBJ
    jne .pair
    ; #t and #f evaluate to themselves
    mov rax, r8
    call _symbol_is_true
    cmp rax, 1
    je .bool
    mov rax, r8
    call _symbol_is_false
    cmp rax, 1
    je .bool
    ; look up symbol in the environment
    mov rax, r9
    mov rcx, r8
    call _env_lookup
    jmp .done
.bool
    mov rax, r8
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
    ; get the symbol
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    mov r10, rax
    ; get the value
    mov rax, r8
    call _get_pair_tail
    call _get_pair_tail
    call _get_pair_head
    mov rsi, r9
    call _eval
    ; update the environment
    mov rdx, rax
    mov rax, r9
    mov rcx, r10
    call _env_set_binding
    mov rax, 0     ; result of set! is nil
    jmp .done
.fn:
    mov rax, r10
    call _symbol_is_fn
    cmp rax, 1
    jne .quote
    ; get the param list
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    mov r10, rax
    ; get the body
    mov rax, r8
    call _get_pair_tail
    call _get_pair_tail
    call _get_pair_head
    mov r11, rax
    ; build proc object
    mov rax, r10                ; formal param list
    mov rcx, r9                 ; env
    mov rdx, r11                ; body of fn
    call _make_procedure_obj
    jmp .done
.quote:
    mov rax, r10
    call _symbol_is_quote
    jne .if
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    jmp .done
.if:
    mov rax, r10
    call _symbol_is_if
    jne .apply_proc
    ; get and evaluate the condition
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    mov rsi, r9
    call _eval
    ; if the condition evaluates to nil or #f
    cmp rax, 0
    je .false_branch
    call _symbol_is_false
    cmp rax, 1
    je .false_branch
    ; evaluate the true branch
    mov rax, r8
    call _get_pair_tail
    call _get_pair_tail
    call _get_pair_head
    mov rsi, r9
    call _eval
    jmp .done
.false_branch: 
    mov rax, r8
    call _get_pair_tail
    call _get_pair_tail
    call _get_pair_tail
    call _get_pair_head
    mov rsi, r9
    call _eval
    jmp .done
; end of special forms
.apply_proc:

.other:
    ; other object types evaluate to themselves
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

; input:
;   rax - address of procedure object
;   rsi - address of environment
;   rdi - address of argument list
; output:
;   rax - result of procedure application
_apply:
    
    ret












