%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "node.h"
#include "tabid.h"
extern int yylex();
extern void* yyin;

%}

%union {
	int i;			/* integer value */
	char* s;
	double d;
};

%token <i> INT
%token <s> STRING ID;
%token <d> NUM;
%token INT_TYPE STRING_TYPE NUM_TYPE
%token VOID PUBLIC CONST IF THEN ELSE WHILE DO FOR IN
%token STEP UPTO DOWNTO BREAK CONTINUE INC DEC LE
%token NE ASSIGN GE
%%
file	:
	;
%%
int yyerror(char *s) { printf("%s\n",s); return 1; }
char *dupstr(const char*s) { return strdup(s); }

int main(int argc, char *argv[]) {
	 yyin = fopen(argv[1], "r");

	 extern YYSTYPE yylval;
	 int tk;
	 while ((tk = yylex()))
		 if (tk > YYERRCODE)
			 printf("%d:\t%s\n", tk, yyname[tk]);
		 else
			 printf("%d:\t%c\n", tk, tk);
	 return 0;
}
