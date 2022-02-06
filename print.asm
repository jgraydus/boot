%include "constants.inc"


section .text

; input:
;   rdi - address of destination buffer
;   rdx - destination buffer length in bytes (qword)
;   rsi - address of zero terminated string to write to buffer
; output:
;   rax - number of bytes written to buffer (qword)
;   rdi - address into buffer that is 1 greater than the last byte written
;   rdx - remaining buffer length
global _print_zero_terminated_string
_print_zero_terminated_string:
    mov qword rax, 0
    push rcx
.loop:
    ; check if buffer is full
    cmp rdx, 0
    je .done
    ; check if at end of string
    cmp byte [rsi], 0
    je .done
    ; copy next character
    mov cl, [rsi]
    mov [rdi], cl
    inc rdi
    dec rdx
    inc rsi
    inc rax
    jmp .loop
.done:
    pop rcx
    ret


; input:
;   rdi - address of destination buffer
;   rdx - destination buffer length 
;   rsi - address of source buffer 
;   rcx - source buffer length
; output:
;   rax - number of bytes written to buffer (qword)
;   rdi - address into buffer that is 1 greater than the last byte written
;   rdx - remaining buffer length
global _print_character_array
_print_character_array:
    mov qword rax, 0
    push rbx
.loop:
    ; check if buffer is full
    cmp rdx, 0
    je .done
    ; check if done
    cmp rcx, 0
    je .done
    ; copy next character
    mov bl, [rsi]
    mov [rdi], bl
    inc rdi
    dec rdx
    inc rsi
    dec rcx
    inc rax
    jmp .loop
.done:
    pop rbx
    ret


; input:
;   rax - unsigned integer to print to buffer
;   rdi - address of destination buffer
;   rdx - destination buffer length
; output:
;   rax - the number of bytes written to the buffer
;   rdi - address into destination buffer 1 greater than the last byte written
;   rdx - remaining buffer length
global _print_unsigned_int
_print_unsigned_int:
    mov rsi, rdx       ; need rdx for div, so use rsi instead
    mov rdx, 0         ; push 0 on stack to indicate where loop2 should stop
    ; check for 0
    cmp rax, 0
    je .handle_zero
    push rdx
.loop1:
    ; check if done
    cmp rax, 0
    je .next
    ; divide by 10. save the remainder as a character
    mov rdx, 0
    mov rcx, 10
    div rcx
    mov rcx, 48        ; offset of character "0"
    add rdx, rcx
    push rdx
    jmp .loop1
.next:
    mov rcx, 0         ; to keep track of # bytes written 
.loop2:
    ; next character
    pop rdx
    ; check if done
    cmp dl, 0
    je .done
    ; check for full buffer (skip write, but continue so we fix the stack)
    cmp rsi, 0
    je .continue
    mov [rdi], dl
    inc rdi
    dec rsi
    inc rcx
.continue: 
    jmp .loop2
.done:
    mov rdx, rsi
    mov rax, rcx
    ret
.handle_zero:
    ; check for full buffer
    cmp rsi, 0
    je .done
    mov byte [rdi], 48       ; the "0" character
    inc rdi
    dec rsi
    mov rcx, 1               ; bytes written
    jmp .done


global _print_signed_int
_print_signed_int:
    ; TODO
    ret


; input:
;   rsi - address of buffer to write
;   rdx - number of bytes to write
; output:
;   rax - number of bytes written
global _flush_print_buffer
_flush_print_buffer:
    mov rax, SYS_WRITE
    mov rdi, STDOUT_FILENO
    syscall
    ret
  
