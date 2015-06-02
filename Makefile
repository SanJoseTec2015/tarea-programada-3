# Macros

CC = yasm
CC2 = ld
CFLAGS = -f elf64 -o
CFLAGS2 = -o
SRC = progra3.asm 
OBJ = progra3.o 


# Reglas expl�citas

all:
	$(CC) $(CFLAGS) $(OBJ) $(SRC)
	$(CC2) $(CFLAGS2) progra3 $(OBJ)
