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
    add_binding "%add", _intrinsic_add
    add_binding "%sub", _intrinsic_sub
    pop r9
    pop r8
    ret

