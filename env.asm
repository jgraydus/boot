%include "constants.inc"
%include "object.inc"

; env is a pair w/
;   head is the parent environment
;   tail is the list of bindings
;
; a binding is a pair w/
;   head is the symbol
;   tail is the value

; input:
;   rax - address of parent env
; output:
;   rax - address of new env
global _make_env
_make_env:
    push rcx
    mov rcx, 0
    call _make_pair_obj 
    push rcx
    ret

; input:
;   rax - address of env to modify
;   rsi - address of symbol (name) to bind in the env
;   rdi - address of value to bind to the symbol
; output:
global _env_add_binding
_env_add_binding:
    push r8
    push r9
    push rcx
    mov r8, rax
    ; make a new binding
    mov rax, rsi
    mov rcx, rdi
    call _make_pair_obj
    mov r9, rax
    ; get the binding list and add new binding
    call _get_pair_tail
    mov rcx, rax    ; old bindings are tail of new bindings
    mov rax, r9
    call _make_pair_obj
    mov rcx, rax
    mov rax, r8
    call _set_pair_tail
    ; done
    pop rcx
    pop r9
    pop r8 
    ret

; input:
;   rax - address of env
;   rcx - address of symbol to look up
; output:
;   rax - address of the first binding for the given symbol (or 0 if not found)
_lookup_binding:
    push r8
    push r9
    push r10
    push r11
    ; if input is null, output is null
    cmp rax, 0
    je .not_found
    mov r8, rax
    mov r9, rcx
    ; iterate through current frame looking for symbol
    call _get_pair_tail ; binding list
    mov r10, rax
.next_binding:
    cmp rax, 0
    je .search_parent   ; end of binding list, search parent instead
    call _get_pair_head ; binding
    mov r11, rax        ; remember the whole binding
    call _get_pair_head ; symbol in binding
    mov rcx, r9         ; symbol we're looking for
    call _obj_equals
    je .found
    mov rax, r10        ; binding list
    call _get_pair_tail ; replace with its tail
    mov r10, rax
    jmp .next_binding
.found:
    mov rax, r11        ; binding
    jmp .done
.not_found:
    mov rax, 0
.done:
    pop r11
    pop r10
    pop r9
    pop r8
    ret
.search_parent:
    mov rax, r8            ; current env
    call _get_pair_head    ; parent env
    mov rcx, r9            ; symbol
    call _lookup_binding
    jmp .done



; input:
;   rax - address of env
;   rcx - address of symbol to look up
; output:
;   rax - address of the first binding for the given symbol (or 0 if not found)
global _env_lookup
_env_lookup:
    call _lookup_binding
    cmp rax, 0
    je .done
    call _get_pair_tail
.done:
    ret





