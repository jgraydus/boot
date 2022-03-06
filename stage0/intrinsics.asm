%include "constants.inc"
%include "env.inc"
%include "eval.inc"
%include "lexer.inc"
%include "memory.inc"
%include "object.inc"
%include "parser.inc"
%include "string.inc"
%include "sys_calls.inc"

section .text

; all intrinsics take arguments as a list in rax and return their result in rax

_intrinsic_env:
    mov rax, rsi
    ret

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

_intrinsic_mult:
    push r8
    push r9
    push rdx
    mov rdx, 0
    mov r8, rax
    call _get_pair_head
    call _integer_get_value
    mov r9, rax
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    call _integer_get_value
    imul r9
    call _make_integer_obj
    pop rdx
    pop r9
    pop r8
    ret

_intrinsic_div:
    push r8
    push r9
    push rdx
    mov rdx, 0
    mov r8, rax
    call _get_pair_tail
    call _get_pair_head
    call _integer_get_value
    mov r9, rax
    mov rax, r8
    call _get_pair_head
    call _integer_get_value
    idiv r9
    call _make_integer_obj
    pop rdx
    pop r9
    pop r8
    ret

_intrinsic_mod:
    push r8
    push r9
    push rdx
    mov rdx, 0
    mov r8, rax
    call _get_pair_tail
    call _get_pair_head
    call _integer_get_value
    mov r9, rax
    mov rax, r8
    call _get_pair_head
    call _integer_get_value
    idiv r9
    mov rax, rdx
    call _make_integer_obj
    pop rdx
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

_intrinsic_greater_than:
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
    cmp r9, rax
    jg .yes
    call _symbol_false
    jmp .done
.yes:
    call _symbol_true
.done:
    pop r9
    pop r8
    ret

_intrinsic_less_than:
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
    cmp r9, rax
    jl .yes
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

_intrinsic_bool:
    call _get_pair_head
    call _to_bool
    ret

_to_bool:
    cmp rax, 0
    je .false
    call _symbol_is_false
    cmp rax, 1
    je .false
    call _symbol_true
    jmp .done
.false:
    call _symbol_false
.done:
    ret

_intrinsic_and:
    push rcx
    push r8
    mov r8, rax
    call _get_pair_head
    call _to_bool
    call _symbol_is_true
    cmp rax, 0
    je .false
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    call _to_bool
    call _symbol_is_true
    cmp rax, 0
    je .false
    call _symbol_true
    jmp .done
.false:
    call _symbol_false
.done:
    pop r8
    pop rcx
    ret

_intrinsic_exit:
    push rdi
    mov rdi, 0
    cmp rax, 0
    je .no_arg
    call _get_pair_head
    call _integer_get_value
.no_arg:
    mov rdi, rax
    call _sys_exit
    pop rdi
    ret

_intrinsic_print:
    call _get_pair_head
    call _object_to_string
    call _print_string
    call _print_newline
    mov rax, 0
    ret

_intrinsic_read:
    push rdi
    push rsi
    push r8
    push r9
    push r10
    ; open file
    call _get_pair_head
    call _string_to_null_terminated
    mov r8, rax ; remember this string so we can free it
    mov rdi, rax
    mov rsi, 0
    call _sys_open
    mov r9, rax
    ; read file
    call _read_string
    mov r10, rax
    ; clean up
    mov rax, r8         ; free the file name
    call _free
    mov rdi, r9         ; close the file
    call _sys_close
.done:
    mov rax, r10
    pop r10
    pop r9
    pop r8
    pop rsi
    pop rdi
    ret

_intrinsic_parse:
    call _get_pair_head
    call _tokenize
    call _parse
    ret

_intrinsic_eval:
    call _get_pair_head
    call _eval_proc
    ret

_intrinsic_string_append:
    push r8
    push r9
    push r10
    mov r8, rax
    call _get_pair_head
    mov r9, rax
    mov rax, r8
    call _get_pair_tail
    call _get_pair_head
    mov r10, rax
    call _string_new
    mov rsi, r9
    call _string_append
    mov rsi, r10
    call _string_append 
    pop r10 
    pop r8
    pop r8
    ret

_intrinsic_substring:
    push r8
    push r9
    push r10
    mov r10, rax
    call _get_pair_tail
    call _get_pair_head
    call _integer_get_value
    mov r8, rax
    mov rax, r10
    call _get_pair_tail
    call _get_pair_tail
    call _get_pair_head
    call _integer_get_value
    mov r9, rax
    mov rax, r10
    call _get_pair_head
    call _substring
    pop r10
    pop r9
    pop r8
    ret

_intrinsic_string_length:
    call _get_pair_head
    call _string_length 
    call _make_integer_obj
    ret

section .rodata
    gen_sym: db "sym-"
    gen_sym_len: equ $-gen_sym
section .bss
    gen_sym_counter: resq 1

section .text

_intrinsic_gen_sym:
    push r8
    push rsi
    push rcx
    mov rax, [gen_sym_counter]
    inc rax
    mov [gen_sym_counter], rax
    call _make_integer_obj
    call _object_to_string
    mov r8, rax
    call _string_new
    mov rsi, gen_sym
    mov rcx, gen_sym_len
    call _append_from_buffer 
    mov rsi, r8
    call _string_append
    call _make_symbol_obj
    pop rcx
    pop rsi
    pop r8
    ret

%macro make_symbol 1
section .rodata
    %%str: db %1
    %%len: equ $-%%str
section .text
    call _string_new
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
    add_binding "env", _intrinsic_env
    add_binding "+", _intrinsic_add
    add_binding "-", _intrinsic_sub
    add_binding "cons", _intrinsic_cons
    add_binding "list", _intrinsic_list
    add_binding "head", _intrinsic_head
    add_binding "tail", _intrinsic_tail
    add_binding "nil?", _intrinsic_is_nil
    add_binding "bool", _intrinsic_bool
    add_binding "and", _intrinsic_and
    add_binding "=", _intrinsic_equals
    add_binding ">", _intrinsic_greater_than
    add_binding "<", _intrinsic_less_than
    add_binding "*", _intrinsic_mult
    add_binding "/", _intrinsic_div
    add_binding "mod", _intrinsic_mod
    add_binding "exit", _intrinsic_exit
    add_binding "print", _intrinsic_print
    add_binding "read", _intrinsic_read
    add_binding "parse", _intrinsic_parse
    add_binding "eval", _intrinsic_eval
    add_binding "string-append", _intrinsic_string_append
    add_binding "string-length", _intrinsic_string_length
    add_binding "substring", _intrinsic_substring
    add_binding "gen-sym", _intrinsic_gen_sym
    pop r9
    pop r8
    ret
