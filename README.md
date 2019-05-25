# Diy Compiler

A compiler for the diy language. This was a project for the Compiler Course in IST 2018/2019.

The language is briefly described in portuguese in the pdf in root folder.
The text was taken from the Course page, made by professor Pedro Rei dos Santos 2019-02-18

Examples and tests can be found in the root folder.

## Getting Started

### Prerequisites

This is meant to be run on a unix based system. 

To compile the project you will need:

* pburg 
* flex
* byacc
* nasm

Most of these can be installed from the linux system provider. If unavailable, a version of  these is located in the linux64 directory.

## Installation

You can use the make or the detailed version bellow.

To generate the compiler, change to src/
 
```
make
```

this will generate the executable diy

To compile a file using the compiler, 

```
make file.diy
```
The executable a.out will be created, run with ./a.out.

## Detailed Installation

### Compiling the compiler
Go to src folder,

Compile the lib and run modules:
```
make -C lib
make -C run
```

Generate sintax analiser (y.tab.c, y.tab.h e y.output):
```
byacc -dv diy.y
```

Generate the lexical analiser (lex.yy.c):
```
flex -l diy.l
```
	
Generate the postfix code generator for 32bit Pentium processors (yyselect.c):
```
pburg diy.brg
```
  
Generate the compiler executable:
```
gcc -o diy -Ilib lex.yy.c y.tab.c yyselect.c -Llib -lutil
```
  
### Compiling with the compiler

Generate the assembly file:
```
./diy file.diy out.asm
```

Generate the object file:
```
nasm -felf32 -F dwarf -g out.asm
```

Link and create executable:
```
ld -melf_i386 out.o run/libdiy.a
```
The executable a.out will be created, run with ./a.out.


