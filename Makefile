.SUFFIXES: .$(EXT) .asm .obj .exe
LANG=diy
EXT=diy
LIB=lib
RUN=run
AS=nasm -felf32
#ARCH=-DpfARM
#AS=as
CC=gcc
CFLAGS=-g -DYYDEBUG

$(LANG): $(LANG).y $(LANG).l $(LANG).brg
	make -C lib
	make -C run
	byacc -dv $(LANG).y
	flex -l $(LANG).l
	pburg $(LANG).brg
	$(LINK.c) -o $(LANG) -I$(LIB) lex.yy.c y.tab.c yyselect.c -L$(LIB) -lutil

%: %.diy
	./diy $< out.asm
	nasm -felf32 -F dwarf -g out.asm
	ld -melf_i386 out.o run/libdiy.a


clean::
	rm -f *.o $(LANG) lex.yy.c y.tab.c y.tab.h y.output yyselect.c *.asm *~ *.obj *.exe
