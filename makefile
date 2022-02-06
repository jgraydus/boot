SRC := $(wildcard *.asm)
OBJ := $(patsubst %.asm,%.o,$(SRC))
INC := $(wildcard *.inc)

ALL: main

main: $(OBJ)
	ld -o $@ $^

%.o: %.asm $(INC)
	nasm -f elf64 -o $@ $<

clean:
	rm -f main $(OBJ)
