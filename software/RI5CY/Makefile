CC=/opt/riscv/bin/riscv32-unknown-elf-gcc
OPTIMIZATION=-O3 -funroll-loops
CFLAGS=-march=RV32IMCXpulpv2 -Wall $(OPTIMIZATION)
LFLAGS=-T link.riscv.ld -nostartfiles -Wall
EXEC=Coremark-RI5CY.elf
NAME=O3C

all: code.hex

$(EXEC): crt0.o core_list_join.o core_main.o core_matrix.o core_state.o core_util.o core_portme.o driver.o
	$(CC) $(LFLAGS) $^ -o $@

code.hex: $(EXEC)
	mkdir output
	python3 ELF2Mem.py $(EXEC) $(NAME)


%.o:%.c
	$(CC) -o $@ -c $< $(CFLAGS)

crt0.o: crt0.S pulpino.h
	$(CC) -o $@ -c $< $(CFLAGS)

.PHONY: clean purge
clean:
	rm -rf *.o

purge: clean
	rm $(EXEC)
