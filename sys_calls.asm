%include "constants.inc"

; input:
;   rsi - address of buffer
;   rdx - maximum # of bytes to read
;   rdi - file handle
global _sys_read
_sys_read:
    mov rax, SYS_READ
    syscall
    ret

; input:
;   rsi - address of buffer
;   rdx - number of bytes to write
;   rdi - file handle
global _sys_write
_sys_write:
    mov rax, SYS_WRITE
    syscall
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
