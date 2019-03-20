%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "node.h"
#include "tabid.h"
extern int yylex();
void yyerror(char *s);
%}

%union {
	int i;			/* integer value */
	char* s;
	double d;
};

%token <i> INT
%token <s> STRING ID;
%token <d> NUMBER;
%token VOID PUBLIC CONST IF THEN ELSE WHILE DO FOR IN
%token STEP UPTO DOWNTO BREAK CONTINUE INC DEC LE
%token NE ASSIGN
%%
file	:
	;
%%
char **yynames =
#if YYDEBUG > 0
		 (char**)yyname;
#else
		 0;
#endif
