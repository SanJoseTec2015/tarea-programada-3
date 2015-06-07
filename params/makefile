all: build

build: stacktest.asm
	yasm -f elf64 -o stacktest.o stacktest.asm
	gcc -o stacktest stacktest.o