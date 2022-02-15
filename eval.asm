%include "constants.inc"


section .text

; input
;   rax - object to evaluate
;   rsi - address of environment
; output:
;   rax - resulting value of evaluating the input
global _eval
eval:
    ret
