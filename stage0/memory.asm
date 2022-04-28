%include "constants.inc"
%include "print.inc"
%include "sys_calls.inc"

HEAP_SIZE         equ 1024*1024*100   ; 100 MB

section .bss
    heap:      resq 1
    next:      resq 1
    remaining: resq 1
    free_list: resq 1
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
    push rax
    push rdi
    push rdx
    push rsi
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
    pop rsi
    pop rdx
    pop rdi
    pop rax
    pop r8
    ret
    
    
    

global _init_heap
_init_heap:
    mov rdi, 0
    mov rsi, HEAP_SIZE
    mov rdx, PROT_WRITE 
    mov r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1                                ; file descriptor (-1 for MAP_ANONYMOUS)
    mov r9, 0                                 ; offset (must be 0 for MAP_ANONYMOUS)
    call _sys_mmap
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
    push rbx
    push r8
    push r9
    push r10
    push r11
    mov r8, rax
    ; first check free list for a chunk of sufficient size
    mov r9, [free_list]
    mov r10, 0           ; previous chunk in list
.next:
    cmp r9, 0
    je .new_allocation   ; no chunk in free list large enough
    mov r11, [r9+8]      ; get size of this chunk
    cmp r11, r8       ; is it large enough?
    jge .reuse        ; strategy: use first chunk that is large enough. simple but wastes memory
    mov r10, r9
    mov r9, [r9+0]    ; go to next chunk in free list
    jmp .next
.reuse:
    mov r11, [r9+0]   ; get pointer to chunk after this one
    cmp r10, 0        ; if the previous chunk is null, then we're replacing the head of the free list
    je .new_head    
    mov [r10+0], r11  ; otherwise, change the previous chunk to point at the one after this one 
    jmp .finish_reuse
.new_head:
    mov [free_list], r11
.finish_reuse:
    lea rax, [r9+16]  ; return the address of the usable memory of the chunk
    jmp .done
.new_allocation:
    ; allocate 2 additional qwords to hold free list pointer and size
    add rax, 16
    cmp rax, [remaining]
    jg .handle_oom
    mov rbx, [remaining]
    sub rbx, rax
    mov [remaining], rbx
    mov rbx, [next]
    add rbx, rax
    mov rax, [next]
    mov [next], rbx
    mov qword [rax], 0   ; first qword is for use in free list (pointer to next cell)
    mov [rax+8], r8      ; second qword is the amount of memory in this chunk
    add rax, 16          ; actual usable memory starts after first two qwords
.done:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbx
    ret
.handle_oom:
    mov rsi, oom
    mov rdx, [omm_len]
    call _flush_print_buffer
    ; exit
    mov rdi, 1
    call _sys_exit


; input:
;   rax - pointer that was previously returned by a call to _malloc
global _free
_free:
    push r8
    ; push the chunk of memory to the front of the free list
    mov r8, [free_list]     ; pointer to head of current free list
    sub rax, 16             ; free list pointer is 2 qwords before the pointer that _malloc hands out
    mov [rax], r8           ; point this chunk at the head of current free list
    mov [free_list], rax    ; this chunk is now the new head of free list
    pop r8
    ret




