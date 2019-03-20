%{
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"

void yyerror(char *s);
int octal(char *s);
char *dupstr(const char *s);

int nest = 0;
%}

%x COM STR
%%


  /*<COM> "=<" ECHO;
  <COM> "=>" ECHO;
  <COM> .|\n ECHO;
  "=<"       BEGIN(COM); */


"void"     ECHO; //return VOID;
"public"   ECHO;//return PUBLIC;
"const"    ECHO; //return CONST;
"if"       ECHO; //return IF;
"then"     ECHO; //return THEN;
"else"     ECHO; //return ELSE;
"while"    ECHO; //return WHILE;
"do"       ECHO; //return DO;
"for"			 ECHO; //return FOR;
"in"       ECHO; //return IN;
"step"     ECHO; //return STEP;
"upto"     ECHO; //return UPTO;
"downto"   ECHO; //return DOWNTO;
"break"    ECHO; //return BREAK;
"continue" ECHO; //return CONTINUE;
"++"       ECHO; //return INC;
"--"       ECHO; //return DEC;
"<="       ECHO; //return LE;
"<>"       ECHO; //return NE;
":="       ECHO; //return ASSIGN;

[a-zA-Z][a-zA-Z0-9_]*   printf("id: %s", yytext); yylval.s = dupstr(yytext); //return ID;


\"([^\\\"]|\\.)*\" 	yylval.s = malloc(yyleng); *yylval.s = 0; REJECT;
\"			   printf("String: \""); BEGIN STR;
<STR>\"    ECHO; BEGIN 0; //return STRING;
<STR>\\\"  ECHO;strcat(yylval.s, "\"");
<STR>\\n   ECHO;strcat(yylval.s, "\n");
<STR>\\r   ECHO;strcat(yylval.s, "\r");
<STR>\\t   ECHO;strcat(yylval.s, "\t");
<STR>\\([a-fA-F0-9]{2}|[a-fA-F0-9]) {char temp[2];
                                    sprintf(temp, "%c", (int) strtol(yytext+1, 0, 16));
                                    strcat(yylval.s, temp);
                                    printf("%s", temp);}
<STR>\\.   yyerror("invalid escape sequence in string");
<STR>.|\n  ECHO; strcat(yylval.s, yytext);
[1-9][0-9]*		         {printf("int dec: %ld", strtol(yytext, 0, 10)); errno = 0; yylval.i = strtol(yytext, 0, 10);
			                  if (errno == ERANGE) yyerror("decimal overflow");
			                 } //return INT; }
0[0-9]*                yylval.i = octal(yytext); printf("int oct: %d\n", octal(yytext)); //return INT;
0b[01]+                yylval.i = strtol(yytext+2, 0, 2); printf("int 0b: %ld", strtol(yytext+2, 0, 2)); //return INT;
[-+*/%!&|~<>();,\[\]{}#=]	ECHO; //return *yytext;


[ \n\r\t]+	ECHO; //	;

.		 yyerror("Unknown character");
%%
int yywrap(void) { return 1; }
char *getyytext() { return yytext; }
int octal(char *s)
{
  int i, a = 0, b = 0;

  for (i = 0; i < strlen(s); i++) {
    if (s[i] < '0' || s[i] > '9') break;
    b = b * 8 + s[i] - '0';
    if (b < a) {
      yyerror("octal overflow");
      break;
    }
    a = b;
  }
  return a;
}
