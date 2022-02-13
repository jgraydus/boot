%include "constants.inc"
%include "print.inc"

HEAP_SIZE         equ 1024*1024

section .text


section .bss
    heap:      resq 1
    next:      resq 1
    remaining: resq 1

section .data
    oom:       db "ERROR: Out of memory", 10
    omm_len:   dq 21

section .text

global _init_heap
_init_heap:
    mov rax, SYS_MMAP
    mov rdi, 0
    mov rsi, HEAP_SIZE
    mov rdx, PROT_WRITE 
    mov r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1                                ; file descriptor (-1 for MAP_ANONYMOUS)
    mov r9, 0                                 ; offset (must be 0 for MAP_ANONYMOUS)
    syscall
    mov [heap], rax
    mov [next], rax
    mov qword [remaining], HEAP_SIZE
    ret

; input:
;   rax - amount of memory requested (must be multiple of 8)
; output:
;   rax - pointer to allocated memory
global _malloc
_malloc:
    cmp rax, [remaining]
    jg .handle_oom
    push rbx
    mov rbx, [remaining]
    sub rbx, rax
    mov [remaining], rbx
    mov rbx, [next]
    add rbx, rax
    mov rax, [next]
    mov [next], rbx
    pop rbx
    ret

.handle_oom:
    mov rsi, oom
    mov rdx, [omm_len]
    call _flush_print_buffer
    ; exit
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall



global _free
_free:
    ; TODO
    ret





