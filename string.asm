%include "constants.inc"
%include "memory.inc"

; struct {
;     qword,      ; buffer_length
;     qword,      ; content_length
;     ptr         ; buffer address
; }

SIZEOF_STRING     equ 8*3


; output:
;   rax - address of an empty string with a 16 byte buffer
global _new_string
_new_string:
    ; allocate memory for data
    mov rax, 16
    call _malloc
    mov rcx, rax
    ; allocate memory for wrapper
    mov rax, SIZEOF_STRING
    call _malloc
    ; initialize string 
    mov qword [rax], 16         ; buffer length
    mov qword [rax+8], 0        ; content length
    mov qword [rax+16], rcx     ; pointer to buffer
    ret

; double the buffer size of the given string and copy the existing
; contents to the new buffer
;
; input:
;   rax - pointer to string structure
_double_buffer_size:
    push rbx
    mov rbx, rax    ; need rax to call _malloc
    push rax
    ; remember the current buffer address
    mov rsi, [rbx+16]
    push rsi
    ; double the buffer size
    mov rcx, [rbx]
    shl rcx, 1
    mov [rbx], rcx
    ; allocate a new buffer
    mov rax, rcx
    call _malloc
    mov [rbx+16], rax
    ; copy old buffer to new buffer
    mov rdx, [rbx+8]
.loop:
    cmp rdx, 0
    je .done 
    mov cl, [rsi]
    mov [rax], cl
    inc rsi
    inc rax
    dec rdx
    jmp .loop
.done:
    pop rax     ; free previous buffer
    call _free
    pop rax
    pop rbx
    ret


; input:
;   rax - address of string
global _print_string
_print_string:
    mov rsi, [rax+16]
    mov rdx, [rax+8]
    mov rax, SYS_WRITE
    mov rdi, STDOUT_FILENO
    syscall
    ret 


; input:
;   rax - address of string
;   rsi - address of source buffer
;   rcx - number of bytes to append
; output:
;   rax - address of string (unchanged)
global _append_from_buffer
_append_from_buffer:
.ensure_buffer_length:
    mov r8, [rax]      ; buffer size
    sub r8, [rax+8]    ; subtract content size
    cmp r8, rcx
    jg .copy
    push rsi
    push rcx
    call _double_buffer_size
    pop rcx
    pop rsi
    jmp .ensure_buffer_length
.copy:
    mov rdi, [rax+16]    ; set destination address
    add rdi, [rax+8]     ; skip past existing content
    add [rax+8], rcx     ; increase content length
    push rbx             ; must preserve
.loop:
    cmp rcx, 0
    je .done
    mov bl, [rsi]
    mov [rdi], bl
    inc rsi
    inc rdi
    dec rcx 
    jmp .loop
.done:
    pop rbx
    ret 



