%include "constants.inc"
%include "print.inc"

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
    message: db "hello", 0
    newline: db 10, 0



section .bss
    buffer: resb BUFFER_SIZE



section .text

global _start
_start:

    mov rbx, 0

    mov rdi, buffer
    mov rdx, BUFFER_SIZE
    mov rsi, message
    mov rcx, 5
    call _print_character_array
    add rbx, rax

    mov rsi, message
    mov rcx, 5
    call _print_character_array
    add rbx, rax

    mov rsi, newline
    mov rcx, 1
    call _print_character_array
    add rbx, rax

    ;mov rsi, buffer
    ;mov rdx, rbx
    ;call _flush_print_buffer

    mov qword rax, 12345
    call _print_unsigned_int
    add rbx, rax

    mov rsi, newline
    mov rcx, 1
    call _print_character_array
    add rbx, rax


    mov rsi, buffer
    mov rdx, rbx
    call _flush_print_buffer


    ; exit
    mov rax, SYS_EXIT
    mov rdi, EXIT_SUCCESS
    syscall


