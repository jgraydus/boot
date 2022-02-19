%include "constants.inc"
%include "env.inc"
%include "object.inc"
%include "string.inc"

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
.bool:
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
    mov r11, rax
    ; build proc object
    mov rax, r10                ; formal param list
    mov rcx, r9                 ; env
    mov rdx, r11                ; body of fn
    call _make_procedure_obj
    jmp .done
.quote:
    ; TODO with this implementation quote just returns its argument unchanged
    ; however, it should really walk through the body of the argument and 
    ; evaluate any unquoted symbols
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
    ; get the procedure object to apply
    mov rax, r8
    call _get_pair_head
    call _eval
    ; TODO should check that it's a procedure
    mov r10, rax
    ; get and evaluate the params
    mov rax, r8
    call _get_pair_tail
    call _eval_params
    ; now apply the procedure to the params
    mov rdx, rax
    mov rax, r10
    call _apply
    jmp .done
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
;   rax - address of a list
;   rsi - address of environment
; output:
;   rax - address of a new list consisting of the result of evaluating everything from the input list
_eval_params:
    push r8
    push r9
    mov r8, rax
    cmp rax, 0
    je .done
    call _get_pair_head
    call _eval
    mov r9, rax
    mov rax, r8
    call _get_pair_tail
    call _eval_params 
    mov rcx, rax
    mov rax, r9
    call _make_pair_obj 
.done:
    pop r9
    pop r8
    ret

; input:
;   rax - address of parent env
;   rcx - address of formal param list
;   rdx - address of arguments
_extend_env:
    push rsi
    push rdi
    push r8
    push r9
    push r10
    mov r9, rcx
    mov r10, rdx
    ; create a new environment
    call _make_env
    mov r8, rax
    ; bind each formal param to the corresponding argument
.next:
    mov rax, r9
    cmp rax, 0
    je .done          ; no more formal parameters
    call _get_pair_head
    mov rsi, rax      ; symbol to bind
    mov rax, r10
    call _get_pair_head
    mov rdi, rax      ; value to bind
    ; add the binding to the env
    mov rax, r8       ; env
    call _env_add_binding
    ; increment to next formal param and value
    mov rax, r9
    call _get_pair_tail
    mov r9, rax
    mov rax, r10
    call _get_pair_tail
    mov r10, rax    
    jmp .next
.done:
    mov rax, r8
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    ret

; input:
;   rax - address of procedure object
;   rdx - address of argument list
; output:
;   rax - result of procedure application
_apply:
    push r8
    push r9
    push rcx
    push rsi
    mov r8, rax
    ; intrinsics are built-in procedures
    call _proc_is_intrinsic
    cmp rax, 1
    je .intrinsic
    ; set up a new environment which extends the environment where the procedure
    ; was defined with bindings of the formal params to the provided arguments
    mov rax, r8
    call _get_proc_formal_params
    mov rcx, rax
    mov rax, r8
    call _get_proc_env
    call _extend_env
    ; now evaluate the body of the procedure in the new environment
    mov rsi, rax
    mov rax, r8
    call _get_proc_body
    call _eval_proc
.done:
    pop rsi
    pop rcx
    pop r9
    pop r8 
    ret
.intrinsic:
    mov rax, r8
    call _get_proc_body
    mov r8, rax
    mov rax, rdx
    call r8
    jmp .done



; input:
;   rax - address of procedure body
;   rsi - address of env
; output:
;   rax - the result of the evaluation of the last item in the procedure body
global _eval_proc
_eval_proc:
    ; a procedure body is a list. evaluation must be done left to right.
    ; the last object in the list to be evaluated is the result of the procedure
    push r8
    push r9
    push r10
    mov r10, rsi
    mov r8, rax
    mov r9, 0
.next:
    cmp rax, 0
    je .done
    mov rax, r8
    call _get_pair_head
    mov rsi, r10
    call _eval
    mov r9, rax
    mov rax, r8
    call _get_pair_tail
    mov r8, rax
    jmp .next
.done:
    mov rax, r9
    pop r10
    pop r9
    pop r8
    ret







