%include "constants.inc"

; input:
;   rsi - address of buffer
;   rdx - maximum # of bytes to read
;   rdi - file handle
global _sys_read
_sys_read:
    push rcx
    push r11
    mov rax, SYS_READ
    syscall
    pop r11
    pop rcx
    ret

; input:
;   rsi - address of buffer
;   rdx - number of bytes to write
;   rdi - file handle
global _sys_write
_sys_write:
    push rcx
    push r11
    mov rax, SYS_WRITE
    syscall
    pop r11
    pop rcx
    ret

; input:
;   rsi - amount of memory
;   rdi - address
;   rdx - protection flags
;   r10 - general flags
;   r8  - file descriptor
;   r9  - offset
global _sys_mmap
_sys_mmap:
    push rcx
    push r11
    mov rax, SYS_MMAP
    syscall
    pop r11
    pop rcx
    ret

; input:
;   rdi - exit code
global _sys_exit
_sys_exit:
    push rcx
    push r11
    mov rax, SYS_EXIT
    syscall
    pop r11
    pop rcx
    ret

; input:
;   rdi - address of file path (null terminated string)
;   rsi - flags
; output:
;   rax - file handle
global _sys_open
_sys_open:
    push rdx
    push rcx
    push r11
    mov rdx, 0
    or rdx, S_IRUSR
    or rdx, S_IWUSR
    or rdx, S_IRGRP
    or rdx, S_IWGRP
    or rdx, S_IROTH
    or rdx, S_IWOTH
    mov rax, SYS_OPEN
    syscall
    pop r11
    pop rcx
    pop rdx
    ret

; input:
;   rdi - address of file handle
global _sys_close
_sys_close:
    push rcx
    push r11
    mov rax, SYS_CLOSE
    syscall
    pop r11
    pop rcx
    ret




