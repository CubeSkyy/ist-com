LANG=diy
EXT=diy # file extension: .$(EXT)
LIB=lib # compiler library directory
UTIL=util # compiler library: lib$(LIB).a
RUN=run # runtime directory
EXS=exs # examples directory
CC=gcc
CFLAGS=-g -DYYDEBUG


$(LANG): $(LANG).y $(LANG).l
	byacc -dv $(LANG).y
	flex -l $(LANG).l
	$(LINK.c) -o $(LANG) $(ARCH) -I$(LIB) lex.yy.c y.tab.c -L$(LIB) -l$(UTIL)

clean::
	rm -f *.o $(LANG) lex.yy.c y.tab.c y.tab.h y.output yyselect.c *.asm *~
