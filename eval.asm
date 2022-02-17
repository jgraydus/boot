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
eval:
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
    jne .string
    mov rax, 0
    jmp .done
    ; get the type tag for the object
    mov rax, r8
    call _obj_type
; strings evaluate to themselves
.string:
    cmp rax, TYPE_STRING_OBJ
    jne .integer
    mov rax, r8
    jmp .done
; integers evaluate to themselves
.integer:
    cmp rax, TYPE_INTEGER_OBJ
    jne .symbol
    mov rax, r8
    jmp .done
; look up symbol in the environment
.symbol:
    cmp rax, TYPE_SYMBOL_OBJ
    jne .pair
    mov rax, r9
    mov rcx, r8
    call _env_lookup
    jmp .done
; evaluation of a pair is either a function application
; or a special form
.pair:
    cmp rax, TYPE_PAIR_OBJ
    jne .procedure
    ; TODO
    ; define, set!, fn,  
; procedure object evaluates to itself
.procedure:
    cmp rax, TYPE_PROCEDURE_OBJ
    jne .error
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
