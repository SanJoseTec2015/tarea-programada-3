# Macros
ORIGEN1 = progra3
ORIGEN2 = animaciones
ORIGEN3 = cicloprincipal

# Reglas y targets de make
all: build_asm

build_asm: $(ORIGEN1).asm $(ORIGEN2).asm $(ORIGEN3).asm
	yasm -f elf64 -o $(ORIGEN1).o $(ORIGEN1).asm
	yasm -f elf64 -o $(ORIGEN2).o $(ORIGEN2).asm
	yasm -f elf64 -o $(ORIGEN3).o $(ORIGEN3).asm
	ld -o progra $(ORIGEN2).o $(ORIGEN3).o $(ORIGEN1).o
	# Mantener este orden plz