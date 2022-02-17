%include "constants.inc"
%include "memory.inc"
%include "print.inc"

; struct {
;     qword,      ; string object type tag
;     qword,      ; buffer_length
;     qword,      ; content_length
;     ptr         ; buffer address
; }

%define SIZEOF_STRING_OBJ       32
%define NEW_STRING_BUFFER_SIZE  16


; output:
;   rax - address of an empty string with a 16 byte buffer
global _new_string
_new_string:
    push rcx
    ; allocate memory for data
    mov rax, NEW_STRING_BUFFER_SIZE
    call _malloc
    mov rcx, rax
    ; allocate memory for wrapper
    mov rax, SIZEOF_STRING_OBJ
    call _malloc
    ; initialize string
    mov qword [rax+0], TYPE_STRING_OBJ
    mov qword [rax+8], NEW_STRING_BUFFER_SIZE       ; buffer length
    mov qword [rax+16], 0       ; content length
    mov qword [rax+24], rcx     ; pointer to buffer
    pop rcx
    ret

; double the buffer size of the given string and copy the existing
; contents to the new buffer
;
; input:
;   rax - pointer to string structure
_double_buffer_size:
    push r8
    push rsi
    push rcx
    push rdx
    push rbx
    push rax
    mov rbx, rax    ; need rax to call _malloc
    ; remember the current buffer address
    mov rsi, [rbx+24]
    mov r8, rsi
    ; double the buffer size
    mov rcx, [rbx+8]
    shl rcx, 1
    mov [rbx+8], rcx
    ; allocate a new buffer
    mov rax, rcx
    call _malloc
    mov [rbx+24], rax
    ; copy old buffer to new buffer
    mov rdx, [rbx+16]   ; number of bytes to copy
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
    mov rax, r8     ; free previous buffer
    call _free
    pop rax
    pop rbx
    pop rdx
    pop rcx
    pop rsi
    pop r8
    ret


; input:
;   rax - address of string
global _print_string
_print_string:
    push rax
    push rsi
    push rdx
    push rdi
    mov rsi, [rax+24]
    mov rdx, [rax+16]
    mov rax, SYS_WRITE
    mov rdi, STDOUT_FILENO
    syscall
    pop rdi
    pop rdx
    pop rsi
    pop rax
    ret 

READ_SIZE         equ 1024

; output:
;   rax - address of string read from stdin
global _read_string
_read_string:
    push r8
    push rsi
    push rdi
    push rdx
    push rbx
    ; create a string
    call _new_string
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
    pop rdx
    pop rdi
    pop rsi
    pop r8
    ret



; input:
;   rax - address of string
;   rsi - address of source buffer
;   rcx - number of bytes to append
; output:
;   rax - address of string (unchanged)
global _append_from_buffer
_append_from_buffer:
    push r8
    push rdi
    push rbx
.ensure_buffer_length:
    mov r8, [rax+8]      ; destination  buffer size
    sub r8, [rax+16]     ; subtract content size
    cmp r8, rcx
    jg .copy
    call _double_buffer_size
    jmp .ensure_buffer_length
.copy:
    mov rdi, [rax+24]     ; set destination address
    add rdi, [rax+16]     ; skip past existing content
    add [rax+16], rcx     ; increase content length
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
    pop rdi
    pop r8
    ret 

; input:
;   rax - address of string to modify
;   rsi - address of string to append
; output:
;   rax - address of string (unchanged)
global _string_append
_string_append:
   push rcx
   push rdx
   mov rcx, [rsi+16]  ; # of bytes to append
   mov rdx, rsi
   mov rsi, [rdx+24]  ; source string's buffer
   call _append_from_buffer
   pop rdx
   pop rcx
   ret 

; input:
;   rsi - address of string
; output:
;   rax - length of the string content
global _string_length
_string_length:
    mov rax, [rsi+16] 
    ret


; input:
;   rsi - address of string
;   rdi - index into the string
; output:
;   al - the character in the string at the given index
;        (zeros out the rest of rax)
global _string_char_at
_string_char_at:
    push r8
    mov r8, [rsi+24]    ; buffer address
    add r8, rdi
    mov rax, 0
    mov al, [r8]
    pop r8
    ret

; input;
;   rax - address of string
;   r8 - index of first character
;   r9 - index 1 greater than last character
; output:
;   rax - the specified substring of the input string
global _substring
_substring:
    push rsi
    push rbx
    push rcx
    mov rbx, rax
    call _new_string
    mov rsi, [rbx+24]
    add rsi, r8   ; start
    mov rcx, r9
    sub rcx, r8   ; length
    call _append_from_buffer
    pop rcx
    pop rbx
    pop rsi
    ret

section .rodata
    least_signed_integer: db "-9223372036854775808"  ; 20 characters
    minus_sign: db "-"

STRING_FROM_INTEGER_BUFFER_SIZE          equ 32
section .bss
    string_from_integer_buffer: resb STRING_FROM_INTEGER_BUFFER_SIZE

section .text

; input:
;   rax - (signed) integer value
; output:
;   rax - address of string
global _string_from_integer
_string_from_integer:
    push r8
    push rcx
    push rsi
    push rdi
    push rdx
    push rbx
    mov rbx, rax
    call _new_string
    ; first check for least integer values as a special case
    mov r8, -9223372036854775808
    cmp rbx, r8
    jne .next1
    mov rsi, least_signed_integer
    mov rcx, 20
    call _append_from_buffer
    jmp .done
.next1:
    ; check for negative value
    cmp rbx, 0
    jns .next2
    ; insert a negative sign and negate the value to make it positive
    mov rsi, minus_sign
    mov rcx, 1
    call _append_from_buffer
    push rax
    mov rax, -1
    imul rbx
    mov rbx, rax
    pop rax 
.next2:
    ; handle positive value
    push rax
    mov rax, rbx
    mov rdi, string_from_integer_buffer
    mov rdx, 32
    call _print_unsigned_int
    mov rcx, rax
    pop rax
    mov rsi, string_from_integer_buffer
    call _append_from_buffer
.done:
    pop rbx
    pop rdx
    pop rdi
    pop rsi
    pop rcx
    pop r8
    ret 

; input:
;   rax - first string
;   rcx - second string
; output:
;   rax - 1 if the strings are equal, 0 if not
global _string_equals
_string_equals:
    push r8
    push r9
    push rbx
    mov r8, rax
    mov r9, rcx
    ; if addresses are the same, it's the same object
    cmp rax, rcx
    je .done
    ; if lengths are different, they can't be equal 
    mov rax, [r8+16]
    cmp rax, [r9+16]
    jne .not_equal 
    ; ok, i suppose we need to compare character by character
    mov rbx, [r8+16]   ; length 
    mov r8, [r8+24]    ; buffers
    mov r9, [r9+24]
.next_char:
    cmp rbx, 0
    je .done           ; no characters left to compare. they must be equal
    mov al, [r8]
    mov cl, [r9]
    cmp al, cl
    jne .not_equal
    inc r8
    inc r9 
    dec rbx
    jmp .next_char
.not_equal:
    mov rax, 0
    jmp .done
.equal:
    mov rax, 1
    jmp .done
.done:
    pop rbx
    pop r9
    pop r8    
    ret










