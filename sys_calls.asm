%include "constants.inc"

; input:
;   rsi - address of buffer
;   rdx - maximum # of bytes to read
global _sys_read
_sys_read:
    push rdi
    mov rax, SYS_READ
    mov rdi, STDIN_FILENO
    syscall
    pop rdi
    ret

; input:
;   rsi - address of buffer
;   rdx - number of bytes to write
global _sys_write
_sys_write:
    push rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT_FILENO
    syscall
    pop rdi
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
    mov rax, SYS_MMAP
    syscall
    ret

; input:
;   rdi - exit code
global _sys_exit
_sys_exit:
    mov rax, SYS_EXIT
    syscall
    ret
