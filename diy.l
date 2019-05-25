%{
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"

void yyerror(char *s);
int strtoint(char* s, int base), hexdecimal(char* s);
char *dupstr(const char *s);

int nest = 0;
%}
%x COM STR NEWL
%%

"void"     return VOID;
"public"   return PUBLIC;
"const"    return CONST;
"if"       return IF;
"then"     return THEN;
"else"     return ELSE;
"while"    return WHILE;
"do"       return DO;
"for"			 return FOR;
"in"       return IN;
"step"     return STEP;
"upto"     return UPTO;
"downto"   return DOWNTO;
"break"    return BREAK;
"continue" return CONTINUE;
"integer"  return INT_TYPE;
"string"   return STRING_TYPE;
"number"   return NUM_TYPE;
"++"       return INC;
"--"       return DEC;
"<="       return LE;
">="       return GE;
"<>"       return NE;
":="       return ASSIGN;

"=<"      ; BEGIN COM;
"==".*    ;  //inline comments
<COM>"=<" ; nest++;
<COM>"=>" ; if(nest == 0) BEGIN 0; else nest--;
<COM>.|\n ;

<NEWL>" "     ;
<NEWL>\n      BEGIN 0; return ';';  //if newline is found, return ; and leave NEWL state
<NEWL>==.*\n  BEGIN 0; return ';';  //parse inline comments
<NEWL>.       BEGIN 0;yyless(0);    //if anything else is found, leave NEWL state and return the read char to input

\"([^\\\"]|\\.)*\"[ \r\t]*\n?  yylval.s = malloc(yyleng); *yylval.s = 0; REJECT;
\"         BEGIN STR;    //Start processing string after memory allocation
<STR>\"    BEGIN NEWL; return STRING;
<STR>\\\"  strcat(yylval.s, "\"");
<STR>\\n   strcat(yylval.s, "\n");
<STR>\\r   strcat(yylval.s, "\r");
<STR>\\t   strcat(yylval.s, "\t");
<STR>\\[a-fA-F0-9]{1,2} {char temp[2];
                         temp[0] = hexdecimal(yytext+1); //creates string with correct char
                         temp[1] = 0;
                         strcat(yylval.s, temp);}        //and concatenates to s
<STR>\\.   yyerror("invalid escape sequence in string");
<STR>.|\n  strcat(yylval.s, yytext);

[a-zA-Z][a-zA-Z0-9_]*  BEGIN NEWL; yylval.s = dupstr(yytext); return ID;
[1-9][0-9]*            BEGIN NEWL; yylval.i = strtoint(yytext, 10); return INT;
0[0-9]*[ \r\t]*        BEGIN NEWL; yylval.i = strtoint(yytext+1, 8); return INT;
0b[01]+[ \r\t]*        BEGIN NEWL; yylval.i = strtol(yytext+2, 0, 2); return INT;

[0-9]+\.[0-9]+([eE][+-]?[0-9]+)?  {BEGIN NEWL;
                                   errno = 0;
                                   yylval.d = strtod(yytext, 0);
                                   if (errno == ERANGE)
                                      yyerror("number overflow");
                                   return NUM;}

(!|\))                  BEGIN NEWL; return *yytext;
[-+*/%&|~<>(;,\[\]{}#=]	return *yytext;
[ \n\r\t]+		          ;
.		                    yyerror("Unknown character");

%%
int yywrap(void) {
  if (YYSTATE == COM) yyerror("unterminated comment");
  if (YYSTATE == STR) yyerror("unterminated string");
  return 1;
}
char *getyytext() { return yytext; }

//For bases within 1 and 10
//Alternative to strtol that instead returns an int with 32 bit overflow check
int strtoint(char *s, int base){
  int i, a = 0, b = 0;

  for (i = 0; i < strlen(s); i++) {
    if (s[i] < '0' || s[i] > '9') break;
    b = b * base + s[i] - '0';
    if (b < a) {
      yyerror("integer overflow");
      break;
    }
    a = b;
  }
  return a;
}

//Transforms string with hex number to int
int hexdecimal(char *s){
  int i, a = 0, b = 0;

  for (i = 0; i < strlen(s); i++) {
    if (s[i] >= '0' && s[i] <= '9')
      b = b * 16 + s[i] - '0';
    else if (s[i] >= 'A' && s[i] <= 'F')
      b = b * 16 + s[i] - 57;
    else if (s[i] >= 'a' && s[i] <= 'f')
      b = b * 16 + s[i] - 87;
    else
      break;
    if (b < a) {
      yyerror("hex overflow");
      break;
    }
    a = b;
  }
  return a;
}
