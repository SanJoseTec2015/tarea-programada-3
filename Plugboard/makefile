all: build
build: plug.asm
	yasm -f elf64 -o plug.o plug.asm
	ld -o plug plug.o