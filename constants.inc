; linux system calls
SYS_READ        equ   0
SYS_WRITE       equ   1
SYS_MMAP        equ   9
SYS_EXIT        equ  60

; exit codes
EXIT_SUCCESS    equ   0

; MMAP flags
MAP_SHARED      equ   1
MAP_PRIVATE     equ   2
MAP_ANONYMOUS   equ  32
PROT_WRITE      equ   2

; standard file descriptors
STDIN_FILENO    equ   0
STDOUT_FILENO   equ   1
STDERR_FILENO   equ   2

; token types
TOKEN_LEFT_PAREN    equ 1
TOKEN_RIGHT_PAREN   equ 2
TOKEN_SYMBOL        equ 3
TOKEN_STRING        equ 4
TOKEN_INTEGER       equ 5
TOKEN_EOF           equ 6

; object types
TYPE_LIST_OBJ       equ 1
TYPE_STRING_OBJ     equ 2
TYPE_INTEGER_OBJ    equ 3
TYPE_SYMBOL_OBJ     equ 4
TYPE_FUNCTION_OBJ   equ 5


