rt_tests.asm: rt_tests.0 rt.0 rt_*.0
	../stage0/main rt_tests.0

rt_tests.o: rt_tests.asm
	nasm -f elf64 rt_tests.asm -o rt_tests.o

rt_tests: rt_tests.o
	ld -o rt_tests rt_tests.o

clean:
	rm -f rt_tests.asm rt_tests.o rt_tests
