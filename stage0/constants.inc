; linux system calls
SYS_READ        equ   0
SYS_WRITE       equ   1
SYS_OPEN        equ   2
SYS_CLOSE       equ   3
SYS_MMAP        equ   9
SYS_EXIT        equ  60

; flags for open sys call
O_RDONLY        equ     0     ; read only
O_WRONLY        equ     1     ; write only
O_RDWR          equ     2     ; read and write
O_CREAT         equ    64     ; create the file if it doesn't exist
O_TRUNC         equ   512     ; truncate (delete existing contents)
O_APPEND        equ  1024     ; append to existing file

; file modes
S_IRWXU   equ   448  ; user (file owner) has read, write, and execute permission
S_IRUSR   equ   256  ; user has read permission
S_IWUSR   equ   128  ; user has write permission
S_IXUSR   equ   64   ; user has execute permission
S_IRWXG   equ   56   ; group has read, write, and execute permission
S_IRGRP   equ   32   ; group has read permission
S_IWGRP   equ   16   ; group has write permission
S_IXGRP   equ   8    ; group has execute permission
S_IRWXO   equ   7    ; others have read, write, and execute permission
S_IROTH   equ   4    ; others have read permission
S_IWOTH   equ   2    ; others have write permission
S_IXOTH   equ   1    ; others have execute permission

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
TYPE_PAIR_OBJ       equ 1
TYPE_STRING_OBJ     equ 2
TYPE_INTEGER_OBJ    equ 3
TYPE_SYMBOL_OBJ     equ 4
TYPE_PROCEDURE_OBJ  equ 5
TYPE_ARRAY_OBJ      equ 6

; object flags
%define GC_MARK_FLAG            1
%define CONTINUATION_FLAG       4
%define INTRINSIC_PROC_FLAG     8
%define PROC_MACRO_FLAG        16

