%include "constants.inc"
%include "memory.inc"
%include "print.inc"
%include "string.inc"

BUFFER_SIZE              equ 1024

%macro read 3
  section .text
  mov rax, SYS_READ
  mov rdi, STDIN_FILENO
  mov rsi, %1
  mov rdx, %2
  syscall
  mov qword [%3], rax
%endmacro


section .data
    message: db "hell_", 0
    newline: db 10, 0

    foo2:  db "                          "
    foo: db "abcdefghijklmnopqrstuvwxy "


section .bss
    buffer: resb BUFFER_SIZE


section .text

global _start
_start:
    call _init_heap

    call _new_string


    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, foo
    mov qword rcx, 26
    call _append_from_buffer
    mov rsi, newline
    mov qword rcx, 1
    call _append_from_buffer

    call _print_string

    ; exit
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall


