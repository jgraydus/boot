%include "constants.inc"
%include "print.inc"

HEAP_SIZE         equ 1024*1024

section .text


section .bss
    heap:      resq 1
    next:      resq 1
    remaining: resq 1
    print_buffer: resb 256

section .data
    oom:       db "ERROR: Out of memory", 10
    omm_len:   dq 21
    heap_size_msg: db   "heap size: ", 0
    used_memory_msg: db "used:      ", 0
    newline: db 10, 0

section .text

global _print_memory_stats
_print_memory_stats:
    push r8
    mov rdi, print_buffer
    mov rdx, 256
    mov rsi, newline
    call _print_zero_terminated_string
    mov rsi, heap_size_msg
    call _print_zero_terminated_string
    mov qword rax, HEAP_SIZE
    call _print_unsigned_int
    mov rsi, newline
    call _print_zero_terminated_string
    mov rsi, used_memory_msg
    call _print_zero_terminated_string
    mov qword rax, HEAP_SIZE
    sub rax, [remaining]
    call _print_unsigned_int
    mov rsi, newline
    call _print_zero_terminated_string
    mov r8, 256
    sub r8, rdx
    mov rdx, r8
    mov rsi, print_buffer
    call _flush_print_buffer
    pop r8
    ret
    
    
    

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





