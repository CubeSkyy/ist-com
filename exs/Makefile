.SUFFIXES: .$(EXT) .asm
COMP=../diy # compiler
EXT=diy # file extension: .$(EXT)
LIB=diy # runtime library: lib$(LIB).a
RUN=../run # runtime directory
AS=nasm -felf32 # assembler command
LD=ld -melf_i386 # loader command
SRC= iter.diy recurs.diy factorial.diy


EXE=$(SRC:%.diy=%)

#all:: compiler runtime $(EXE)
all:: compiler $(EXE) 

compiler::
	make -C ..

#runtime::
#	make -C $(RUN)

iter.asm: iter.diy
	$(COMP) $<

recurs.asm: recurs.diy
	$(COMP) $<

iter.o: iter.asm
	$(AS) iter.asm -o iter.o

recurs.o: recurs.asm
	$(AS) recurs.asm -o recurs.o

iter: iter.o factorial.o
	$(LD) -o $@ $*.o -L$(RUN) -l$(LIB)
recurs: recurs.o factorial.o
	$(LD) -o $@ $*.o -L$(RUN) -l$(LIB)


%:%.$(EXT)
	$(COMP) $<
	$(AS) $*.asm -o $*.o
	$(LD) -o $@ $*.o -L$(RUN) -l$(LIB)


clean::
	rm -f *.o *.asm *.s *~ $(EXE)
