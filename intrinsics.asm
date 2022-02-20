%include "constants.inc"
%include "env.inc"
%include "object.inc"
%include "string.inc"

section .text

; all intrinsics take arguments as a list in rax and return their result in rax


_intrinsic_add:
    push r8
    push r9
    mov r8, rax
    call _get_pair_head
    call _integer_get_value
    mov r9, rax
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    call _integer_get_value
    add rax, r9
    call _make_integer_obj
    pop r9
    pop r8
    ret

_intrinsic_sub:
    push r8
    push r9
    mov r8, rax
    call _get_pair_head
    call _integer_get_value
    mov r9, rax
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    call _integer_get_value
    sub r9, rax
    mov rax, r9
    call _make_integer_obj
    pop r9
    pop r8
    ret

_intrinsic_equals:
    push r8
    push r9
    mov r8, rax
    call _get_pair_head
    mov r9, rax
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    mov rcx, r9
    call _obj_equals
    cmp rax, 1
    je .yes
    call _symbol_false
    jmp .done
.yes:
    call _symbol_true
.done:
    pop r9
    pop r8
    ret

_intrinsic_cons:
    push r8
    mov r8, rax
    call _get_pair_tail
    call _get_pair_head
    mov rcx, rax
    mov rax, r8
    call _get_pair_head
    call _make_pair_obj
    pop r8
    ret

_intrinsic_list:
    ; just return the arg list
    ret

_intrinsic_head:
    call _get_pair_head       ; first (only) arg
    call _get_pair_head
    ret

_intrinsic_tail:
    call _get_pair_head       ; first (only) arg
    call _get_pair_tail
    ret

_intrinsic_is_nil:
    call _get_pair_head
    cmp rax, 0
    je .yes
    call _symbol_false
    jmp .done
.yes:
    call _symbol_true
.done:
    ret

%macro make_symbol 1
section .rodata
    %%str: db %1
    %%len: equ $-%%str
section .text
    call _new_string
    mov rsi, %%str
    mov rcx, %%len
    call _append_from_buffer
    call _make_symbol_obj
%endmacro

%macro add_binding 2
    make_symbol %1
    mov r9, rax
    mov rax, %2
    call _make_intrinsic_obj
    mov rdi, rax
    mov rsi, r9
    mov rax, r8
    call _env_add_binding
    mov rax, r8
%endmacro


section .text

global _add_intrinsics_to_env
_add_intrinsics_to_env:
    push r8
    push r9
    mov r8, rax
    add_binding "+", _intrinsic_add
    add_binding "-", _intrinsic_sub
    add_binding "cons", _intrinsic_cons
    add_binding "list", _intrinsic_list
    add_binding "head", _intrinsic_head
    add_binding "tail", _intrinsic_tail
    add_binding "nil?", _intrinsic_is_nil
    add_binding "=", _intrinsic_equals
    pop r9
    pop r8
    ret

