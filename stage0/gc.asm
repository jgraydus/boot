%include "constants.inc"
%include "memory.inc"
%include "object.inc"
%include "stack.inc"
%include "string.inc"
%include "vec.inc"

section .bss
    gc_root_object: resq 1
    gc_registry: resq 1
    gc_eval_frames: resq 1
    gc_eval_frames_rsp: resq 1

section .text

; initialize the gc. must be invoked before creating any objects
global _gc_init
_gc_init:
    push rax
    ; gc_registry holds pointers to all objects
    mov qword rax, 1024
    call _vec_new 
    mov [gc_registry], rax
    ; gc_eval_frames
    call _stack_new
    mov [gc_eval_frames], rax
    ; gc_eval_frames_rsp
    call _stack_new
    mov [gc_eval_frames_rsp], rax
    pop rax
    ret

; input
;   rax - address of root object
global _gc_set_root_object
_gc_set_root_object:
    mov [gc_root_object], rax
    ret

; input:
;   rax - the value of the stack pointer to associate with this eval frame
global _gc_new_eval_frame
_gc_new_eval_frame:
    push rsi
    mov rsi, rax
    mov rax, [gc_eval_frames_rsp]
    call _stack_push
    mov rax, 4
    call _vec_new
    mov rsi, rax
    mov rax, [gc_eval_frames]
    call _stack_push
    pop rsi
    ret

; input
;   rax - the value of the stack pointer to unwind to
global _gc_pop_eval_frame
_gc_pop_eval_frame:
    push r8
    mov r8, rax
    ; because a continuation can jump up the stack, we
    ; need to keep popping frames until we've popped
    ; the frame for the currently ending eval
.loop:
    mov rax, [gc_eval_frames]
    call _stack_pop
    call _vec_free
    mov rax, [gc_eval_frames_rsp]
    call _stack_pop
    cmp rax, r8
    jne .loop
.done:
    pop r8
    ret

; input:
;   rax - address of object
; output:
;   rax - address of object (unchanged)
global _gc_register_obj
_gc_register_obj:
    push rsi
    mov rsi, rax
    ; add the object to the vec of all objects
    mov rax, [gc_registry]
    call _vec_append
    ; also add the object to the current eval frame
    mov rax, [gc_eval_frames]
    call _stack_peek
    cmp rax, 0         ; might not have a frame yet
    je .done
    call _vec_append
.done:
    mov rax, rsi
    pop rsi
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
    jne .array
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
.array:
    cmp rax, TYPE_ARRAY_OBJ
    jne .done
    mov rax, r8
    call _gc_unmark_array
.done:
    pop rdx
    pop r8
    ret

_gc_unmark_array:
    push r8
    push rcx
    mov r8, rax
    call _array_obj_size
    mov rcx, rax
.next:
    cmp rcx, 0
    je .done
    dec rcx
    mov rax, r8
    call _array_obj_get
    call _gc_unmark
    jmp .next
.done:
    pop rcx
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

_gc_mark_frame:
    push rax
    push rsi
    mov rsi, _gc_unmark
    call _vec_for_each
    pop rsi
    pop rax
    ret

; input:
;   rax - address of root object. all live objects should be reachable from this object
global _gc_run
_gc_run:
    call _gc_mark
    ; unmark objects reachable from root object
    mov rax, [gc_root_object]
    call _gc_unmark
    ; unmark objects reachable from eval frames as well
    mov rax, [gc_eval_frames]
    mov rsi, _gc_mark_frame
    call _stack_for_each
    ; collect unreachable objects
    call _gc_reclaim
    ret


