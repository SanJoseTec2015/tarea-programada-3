all: build_libc

build: stacktest.asm
	yasm -f elf64 -o stacktest.o stacktest.asm
	ld -o stacktest stacktest.o

build_libc: stacktest.asm
	yasm -f elf64 -o stacktest.o stacktest.asm
	gcc -o stacktest stacktest.o