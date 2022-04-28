%include "constants.inc"
%include "memory.inc"
%include "object.inc"
%include "string.inc"
%include "vec.inc"

section .bss
    gc_registry: resq 1
    gc_root_list: resq 1

section .text

; initialize the gc. must be invoked before creating any objects
global _gc_init
_gc_init:
    push rax
    mov qword rax, 1024
    call _vec_new 
    mov [gc_registry], rax
    pop rax
    ret

; input:
;   rax - address of object
; output:
;   rax - address of object (unchanged)
global _gc_register_obj
_gc_register_obj:
    push rax
    push rsi
    mov rsi, rax
    mov rax, [gc_registry]
    call _vec_append
    pop rsi
    pop rax
    ret

; set the gc mark flag on all objects
_gc_mark:
    push r8
    push rsi
    push rax
    push rdx
    mov rax, [gc_registry]
    call _vec_length
    mov r8, rax
.next:
    cmp r8, 0
    je .done
    dec r8
    ; get object
    mov rax, [gc_registry]
    mov rsi, r8
    call _vec_get_value_at
    ; set mark flag
    mov rdx, GC_MARK_FLAG
    call _obj_set_flag
    ; go to next object
    jmp .next
.done:
    pop rdx
    pop rax
    pop rsi
    pop r8
    ret

; input:
;   rax - root object
_gc_unmark:
    push r8
    push rdx
    mov r8, rax
    ; nothing to do for nil
    cmp r8, 0
    je .done
    ; stop if already unmarked
    mov rax, r8
    mov rdx, GC_MARK_FLAG
    call _obj_get_flag
    cmp rax, 0
    je .done
    mov rax, r8
    mov rdx, GC_MARK_FLAG
    call _obj_unset_flag
    ; follow references inside objects
    ; get object type
    mov rax, r8
    call _obj_type
.pair:
    cmp rax, TYPE_PAIR_OBJ
    jne .string
    mov rax, r8
    call _get_pair_head
    call _gc_unmark
    mov rax, r8
    call _get_pair_tail
    call _gc_unmark
    jmp .done
.string:
    cmp rax, TYPE_STRING_OBJ
    jne .integer
    ; no op
    jmp .done
.integer:
    cmp rax, TYPE_INTEGER_OBJ
    jne .symbol
    ; no op
    jmp .done
.symbol:
    cmp rax, TYPE_SYMBOL_OBJ
    jne .procedure
    mov rax, r8
    call _symbol_get_string
    call _gc_unmark
    jmp .done
.procedure:
    cmp rax, TYPE_PROCEDURE_OBJ
    jne .done
    ; don't do anything for intrinsics
    mov rax, r8
    call _proc_is_intrinsic
    cmp rax, 1
    je .done
    mov rax, r8
    call _get_proc_formal_params
    call _gc_unmark
    mov rax, r8
    call _get_proc_body
    call _gc_unmark
    mov rax, r8
    call _get_proc_env
    call _gc_unmark
    jmp .done
.done:
    pop rdx
    pop r8
    ret

; free all eligible objects which have the gc mark flag set
_gc_reclaim:
    push rsi
    push r8
    push r9
    push r10
    mov r8, [gc_registry]
    ; get the number of objects
    mov rax, r8
    call _vec_length
    mov r9, rax
.next:
    cmp r9, 0
    je .done
    dec r9
    ; get the next object
    mov rax, r8
    mov rsi, r9
    call _vec_get_value_at
    mov r10, rax
    ; if the gc mark flag is set, free the object
    mov rdx, GC_MARK_FLAG
    call _obj_get_flag
    cmp rax, 0
    je .next
    mov rax, r10
    mov rax, r8
    mov rsi, r9
    call _vec_remove
    call _gc_free_obj
    jmp .next
.done:
    pop r10
    pop r9
    pop r8
    pop rsi
    ret

_gc_free_obj:
    push r8
    mov r8, rax
    call _obj_type
    ; strings are special because they have to free their buffer
    cmp rax, TYPE_STRING_OBJ
    jne .other
    mov rax, r8
    call _string_free
    jmp .done
.other:
    ; nothing extra to do for other object types 
    mov rax, r8
    call _free
.done:
    pop r8
    ret

; input:
;   rax - address of root object. all live objects should be reachable from this object
global _gc_run
_gc_run:
    push r8
    mov r8, rax
    call _gc_mark
    mov rax, r8
    call _gc_unmark
    mov rax, r8
    call _gc_reclaim
    pop r8
    ret


