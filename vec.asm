%include "constants.inc"
%include "memory.inc"

; struct vec
;
; struct {
;    qword,      ; buffer size (# of qwords)
;    qword,      ; contents size (# of qwords)
;    ptr,        ; address of buffer
; }

%define vec_buffer_offset      16

%define SIZEOF_VEC 24

; input:
;   rax - initial buffer size (in # of entries)
; output:
;   rax - address of vec
global _vec_new
_vec_new:
    push r8
    push r9
    ; allocate buffer
    mov r8, rax
    mov rax, r8
    shl rax, 3               ; multiply by 8 (size of qword)
    call _malloc
    mov r9, rax
    ; allocate vec
    mov rax, SIZEOF_VEC
    call _malloc
    mov [rax+0], r8         ; buffer size
    mov qword [rax+8], 0    ; contents size (empty)
    mov [rax+vec_buffer_offset], r9        ; buffer address
    pop r9
    pop r8
    ret

; input:
;   rax - address of vec
; output:
;   rax - address of vec (unchanged)
_vec_resize_buffer:
    push r8
    push r9
    push r10
    push rbx
    mov rbx, rax
    ; allocate new buffer
    mov rax, [rbx+0]     ; current buffer size
    shl rax, 1           ; multiply by 2
    mov [rbx+0], rax
    shl rax, 3           ; multiply by 8 (size of qword)
    call _malloc
    ; copy into new buffer
    mov r8, [rbx+vec_buffer_offset]     ; old buffer address
    mov r9, rax          ; new buffer address
    mov r10, [rbx+8]     ; number of items to copy
    push r9
    push r8
.next:
    cmp r10, 0
    je .done
    mov rax, [r8]
    mov [r9], rax
    add r8, 8
    add r9, 8
    dec r10
    jmp .next
.done:
    pop rax        ; free the old buffer memory
    call _free
    pop rax        ; update the vec to point at new buffer
    mov [rbx+vec_buffer_offset], rax
    mov rax, rbx
    pop rbx
    pop r10
    pop r9
    pop r8
    ret

; input:
;   rax - address of vec
;   rsi - value to append
; output:
;   rax - address of vec (unchanged)
global _vec_append
_vec_append:
    push r8
    push rbx
    ; if the buffer is full, resize to fit more stuff
    mov rbx, [rax+8]  ; length
    cmp rbx, [rax+0]  ; = buffer size?
    jne .append
    call _vec_resize_buffer
.append:
    mov r8, [rax+8]    ; current size
    shl r8, 3          ; multiply by 8 (size of each entry)
    add r8, [rax+vec_buffer_offset]   ; add address of buffer
    mov [r8], rsi      ; copy to buffer
    mov r8, [rax+8]    ; increment content size
    inc r8
    mov [rax+8], r8
    pop rbx
    pop r8
    ret

; input:
;   rax - address of the vec
;   rsi - index of item to remove
; output:
;   rax - the removed value
global _vec_remove
_vec_remove:
    push r8
    push r9
    push r10
    mov r8, rax   ; vec
    mov r9, rsi   ; index
    call _vec_get_value_at
    mov r10, rax  ; removed value
    ; move item in last position to this position
    mov rax, r8
    mov rsi, [rax+8]   ; contents size
    sub rsi, 1         ; index of last item
    call _vec_get_value_at
    mov rdi, rax
    mov rax, r8
    mov rsi, r9
    call _vec_set_value_at
    ; decrement size
    mov rax, [r8+8]
    dec rax
    mov [r8+8], rax
    ; done
    mov rax, r10
    pop r10
    pop r9
    pop r8
    ret

; input:
;   rax - address of vec
;   rsi - index of value
; output:
;   rax - value at given index
global _vec_get_value_at
_vec_get_value_at:
    shl rsi, 3         ; multiply by 8
    add rsi, [rax+vec_buffer_offset]  ; add start of buffer
    mov rax, [rsi] 
    ret

; input:
;   rax - address of vec
;   rsi - index of value
;   rdi - value
; ouput:
;   rax - address of vec (unchanged)
global _vec_set_value_at
_vec_set_value_at:
    shl rsi, 3         ; multiply by 8
    add rsi, [rax+vec_buffer_offset]  ; add start of buffer
    mov [rsi], rdi
    ret

; input:
;   rax - address of vec
; output:
;   rax - length of address
global _vec_length
_vec_length:
    push rbx
    mov rbx, rax
    mov rax, [rbx+8]
    pop rbx
    ret

; input:
;   rax - address of vec
global _vec_free
_vec_free:
    push r8
    mov r8, rax
    mov rax, [rax+vec_buffer_offset]
    call _free
    mov rax, r8
    call _free
    pop r8 
    ret

     

    

