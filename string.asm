%include "constants.inc"
%include "memory.inc"

; struct {
;     qword,      ; string object type tag
;     qword,      ; buffer_length
;     qword,      ; content_length
;     ptr         ; buffer address
; }

SIZEOF_STRING_OBJ     equ 32


; output:
;   rax - address of an empty string with a 16 byte buffer
global _new_string
_new_string:
    ; allocate memory for data
    mov rax, 16
    call _malloc
    mov rcx, rax
    ; allocate memory for wrapper
    mov rax, SIZEOF_STRING_OBJ
    call _malloc
    ; initialize string
    mov qword [rax+0], TYPE_STRING_OBJ
    mov qword [rax+8], 16       ; buffer length
    mov qword [rax+16], 0       ; content length
    mov qword [rax+24], rcx     ; pointer to buffer
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
    mov rsi, [rbx+24]
    push rsi
    ; double the buffer size
    mov rcx, [rbx+8]
    shl rcx, 1
    mov [rbx+8], rcx
    ; allocate a new buffer
    mov rax, rcx
    call _malloc
    mov [rbx+24], rax
    ; copy old buffer to new buffer
    mov rdx, [rbx+16]
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
    mov rsi, [rax+24]
    mov rdx, [rax+16]
    mov rax, SYS_WRITE
    mov rdi, STDOUT_FILENO
    syscall
    ret 

READ_SIZE         equ 1024

; output:
;   rax - address of string read from stdin
global _read_string
_read_string:
    ; create a string
    call _new_string
    push rbx
    mov rbx, rax
.prep_and_read:
    ; make sure there's enough remaining room in the string's buffer
    mov r8, [rbx+8]
    sub r8, [rbx+16]  ; (buffer size) - (content size)
    cmp r8, READ_SIZE 
    jge .read
    mov rax, rbx
    call _double_buffer_size
    jmp .prep_and_read 
.read:
    mov rax, SYS_READ
    mov rdi, STDIN_FILENO
    mov rsi, [rbx+24]
    add rsi, [rbx+16]
    mov rdx, READ_SIZE
    syscall
    cmp rax, 0            ; done when 0 bytes are read
    je .done
    add [rbx+16], rax      ; increase size of content by bytes read
    jmp .prep_and_read
.done:
    mov rax, rbx
    pop rbx
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
    mov r8, [rax+8]      ; buffer size
    sub r8, [rax+16]    ; subtract content size
    cmp r8, rcx
    jg .copy
    push rsi
    push rcx
    call _double_buffer_size
    pop rcx
    pop rsi
    jmp .ensure_buffer_length
.copy:
    mov rdi, [rax+24]    ; set destination address
    add rdi, [rax+16]     ; skip past existing content
    add [rax+16], rcx     ; increase content length
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



