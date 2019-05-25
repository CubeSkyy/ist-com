%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "node.h"
#include "tabid.h"
extern int yylex();
extern void* yyin;
extern int yyerror(char *s);
char* id;

/*
Binary system for type definition as follows:
 11  |  10   |      9      |    8    |     7    |   6   |    5   |   4  |   3    |   2    |  1
init | index | const_sting | pointer | function | const | public | void | number | string | int

Example:
00000000001 = int
00000010100 = public number
10110110010 = public string := const "any string"
10001001000 = void func() {function block}
*/
%}

%union {
	int i;
	char* s;
	double r;
	Node *n;
};

%token <i> INT
%token <s> STR ID;
%token <r> REAL;
%token INTEGER STRING NUMBER
%token VOID PUBLIC CONST IF THEN ELSE WHILE DO FOR IN
%token STEP UPTO DOWNTO BREAK CONTINUE NE

%token START DECLS NIL DECL INSTRS STRCONST ARGS ARG END GLOBAL INDEX EXPRS ALLOC FCALL BLOCK STMS EXPR FUNC ID_TYPE POINTER TIPO VAR TO LVAL
%type<n> decls decl tipo public const pointer ini init finit lit args corpo stms instrs instr expr lval arg exprs decl_lit

%nonassoc IFX
%nonassoc ELSE
%right ATR
%left '|'
%left '&'
%nonassoc '~'
%left '=' NE
%left '<' '>' GE LE
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS
%nonassoc DE_REF REF '!' INCR DECR
%nonassoc '[' '('

%%
file : decls  {printNode(uniNode(START, $1), 0, yynames);}
	;

decls : 			 {$$ = nilNode(END);} //EMPTY
	| decls decl {$$ = binNode(DECLS, $1, $2);}
	;

decl: public const tipo pointer ID { int type = 0; type = newType($1, $2, $3, $4); IDnew(type, $5, 0);} init ';' {
	$$ = binNode(DECL, binNode(ID_TYPE, strNode(ID, $5), binNode(PUBLIC, $1, binNode(CONST, $2, binNode(TIPO, $3, binNode(POINTER, $4, nilNode(NIL)))))),$7);
	int type = IDfind($5, 0);
	if ($7->info != -1){ //if id was initialized and/or with a constant string, mark it as so and update id table
		type = setType(type, "init");
		if(checkType($7->info, "const_string"))
			type = setType(type, "const_string");
		compareTypes(type, $7->info);
		IDreplace(type, $5, 0);}
	else if (checkType(type, "const") && !checkType(type, "public")) yyerror("Non-public constants must be initialized."); }

	| public const tipo pointer ID '(' {id = $5; int type = 0; type = newType($1, $2, $3, $4); type = setType(type, "function"); IDnew(type, id, 0);IDpush();} finit ';' {
	$$ = binNode(DECL, binNode(ID_TYPE, strNode(ID, $5), binNode(PUBLIC, $1, binNode(CONST, $2, binNode(TIPO, $3, binNode(POINTER, $4, nilNode(NIL)))))),$8);IDpop();
	}
	;


public:	PUBLIC	{$$ = nilNode(PUBLIC); $$->info = 1;} //flags for decl type creation
	|	/*EMPTY*/   {$$ = nilNode(NIL); $$->info = 0;}
	;



const: CONST	 {$$ = nilNode(CONST); $$->info = 1;}
	|	/*EMPTY*/  {$$ = nilNode(NIL); $$->info = 0;}
	;

pointer: '*'	{$$ = nilNode(POINTER); $$->info = 1;}
	| /*EMPTY*/ {$$ = nilNode(NIL); $$->info = 0;}
	;


tipo : INTEGER	{$$ = nilNode(INTEGER); $$->info = 0;}
	| STRING			{$$ = nilNode(STRING); $$->info = 1;}
	| NUMBER			{$$ = nilNode(NUMBER); $$->info = 2;}
	| VOID				{$$ = nilNode(VOID); $$->info = 3;}
	;

init: ATR ini 				 {$$ = binNode(VAR, $2, nilNode(NIL)); $$->info = $2->info;}
	| /*EMPTY*/			     {$$ = nilNode(NIL);$$->info = -1;}
	;

finit: 	args ')' corpo  {$$ = binNode(FUNC, $1, $3); $$->info = 1;} //Flags for initialization check in decl
	| ')' corpo		   			{$$ = binNode(FUNC, nilNode(NIL), $2); $$->info = 1;}
	| args ')' 						{$$ = binNode(FUNC, $1, nilNode(NIL));}
	| ')'									{$$ = binNode(FUNC, nilNode(NIL), nilNode(NIL));}
	;

ini: decl_lit			{$$ = $1; $$->info = $1->info;}
	| CONST STR			{$$ = strNode(STRCONST, $2);int type = 0; type = setType(type, "string"); $$->info = setType(type, "const_string");}
	| ID						{$$ = strNode(ID, $1); $$->info = IDfind($1, 0);}
	;

decl_lit: INT {$$ = intNode(INT, $1); int type = 0; $$->info = setType(type, "int");}
	| '-' INT 	{$$ = intNode(INT, -$2); int type = 0; $$->info = setType(type, "int");}
	| STR 			{$$ = strNode(STR, $1); int type = 0; $$->info = setType(type, "string");}
	| REAL 			{$$ = realNode(REAL, $1); int type = 0; $$->info = setType(type, "number");}
	| '-' REAL  {$$ = realNode(REAL, -$2); int type = 0; $$->info = setType(type, "number");}
	;

lit: INT {$$ = intNode(INT, $1); int type = 0; $$->info = setType(type, "int");}
	| STR  {$$ = strNode(STR, $1); int type = 0; $$->info = setType(type, "string");}
	| REAL {$$ = realNode(REAL, $1); int type = 0; $$->info = setType(type, "number");}
	;

args: arg					{$$ = binNode(ARGS, $1, nilNode(NIL));}
	| args ',' arg  {$$ = binNode(ARGS, $1, $3);}
	;

arg: tipo pointer ID {$$ = binNode(ARG, strNode(ID, $3),binNode(TIPO, $1, binNode(POINTER, $2, nilNode(NIL))));
	int type = 0;
	if($1->info == 0) type = setType(type, "int");
	if($1->info == 1) type = setType(type, "string");
	if($1->info == 2) type = setType(type, "number");
	if($1->info == 3) type = setType(type, "void");
	if($2->info) type = setType(type, "pointer");
	IDnew(type, $3, 0);}
	;

corpo: '{' { IDpush(); IDreplace(setType(IDfind(id, 0), "init"), id, 0);} stms instrs'}' { $$ = binNode(BLOCK, $3, $4); IDpop();}
	;

stms: stms arg ';'	{ $$ = binNode(STMS, $1, $2); }
	| /*EMPTY*/       {$$ = nilNode(NIL);}
	;

instrs: instrs instr  {$$ = binNode(INSTRS, $1, $2);}
	|	/*EMPTY*/   			{$$ = nilNode(NIL);}
	;

instr: IF expr THEN instr %prec IFX {$$ = binNode(IF, $2, $4); }
	| IF expr THEN instr ELSE instr		{$$ = binNode(ELSE, binNode(IF, $2, $4), $6); }
	| DO instr WHILE expr ';' 				{$$ = binNode(WHILE, binNode(DO, nilNode(START), $2), $4); }
	| FOR lval IN expr UPTO expr DO instr 						{$$ = binNode(FOR, binNode(LVAL, $2, binNode(IN, $4, binNode(UPTO, $6, uniNode(STEP, nilNode(NIL))))), binNode(DO, nilNode(START), $8));}
	| FOR lval IN expr DOWNTO expr DO instr						{$$ = binNode(FOR, binNode(LVAL, $2, binNode(IN, $4, binNode(DOWNTO, $6, uniNode(STEP, nilNode(NIL))))), binNode(DO, nilNode(START), $8));}
	| FOR lval IN expr UPTO expr STEP expr DO instr		{$$ = binNode(FOR, binNode(LVAL, $2, binNode(IN, $4, binNode(UPTO, $6, uniNode(STEP, $8)))), binNode(DO, nilNode(START), $10));}
	| FOR lval IN expr DOWNTO expr STEP expr DO instr	{$$ = binNode(FOR, binNode(LVAL, $2, binNode(IN, $4, binNode(DOWNTO, $6, uniNode(STEP, $8)))), binNode(DO, nilNode(START), $10));}
	| expr ';'					{$$ = $1;}
	| corpo     				{$$ = $1;}
	| BREAK ';' 				{$$ = uniNode(BREAK, nilNode(NIL));}
	| BREAK INT ';'	    {$$ = uniNode(BREAK, intNode(INT, $2));}
	| CONTINUE ';'		  {$$ = uniNode(CONTINUE, nilNode(NIL));}
	| CONTINUE INT ';'  {$$ = uniNode(CONTINUE, intNode(INT, $2));}
	| lval '#' expr ';'	{$$ = binNode(ALLOC, $1, $3);}
	;

exprs: expr				 {$$ = binNode(EXPRS, $1, nilNode(NIL));}
	| exprs ',' expr {$$ = binNode(EXPRS, $1, $3);}
	;

expr: lval                {$$ = $1;}
	| lit										{$$ = $1;}
	| '(' expr ')'					{$$ = $2;}
	| ID '(' exprs ')'			{$$ = binNode(FCALL, strNode(ID, $1), $3);
													int type = IDfind($1, 0); if (!checkType(type, "init") && !checkType(type, "public")) yyerror("Non-public funtion must be initialized before call");
													else $$->info = type;}
	| ID '('')'							{$$ = binNode(FCALL, strNode(ID, $1), nilNode(NIL));
													int type = IDfind($1, 0); if (!checkType(type, "init") && !checkType(type, "public")) yyerror("Non-public funtion must be initialized before call");
													else $$->info = type;}
	| '&' lval %prec REF		{$$ = uniNode('&', $2); }
	| '*' lval %prec DE_REF {$$ = uniNode('*', $2);int type = $2->info;
													if (checkType(type, "string")) {type &= ~(1U << 2); $$->info = setType(type, "int");} //If de-referencing a string, remove string type and add int type
													else if (checkType(type, "pointer")) {type &= ~(1U << 8); $$->info = type;}						//If de-referencing a pointer, remove pointer type
													else yyerror("Dereference operand must be a pointer");}
	| '-' expr %prec UMINUS {$$ = uniNode('-', $2); int type = $2->info; if(!checkType(type, "int") && !checkType(type, "number")) yyerror("Wrong type argument to unary minus"); $$->info = type;}
	| '!' expr							{$$ = uniNode('!', $2); $$->info = check1Int($2->info, "Wrong type argument to factorial");}
	| DECR lval							{$$ = binNode(DECR, intNode(INT, checkType($2->info,"pointer") ? 4 : 1), $2); $$->info = check1Int($2->info, "Wrong type argument to decrement operator");}
	| INCR lval							{$$ = binNode(INCR, intNode(INT, checkType($2->info,"pointer") ? 4 : 1), $2); $$->info = check1Int($2->info, "Wrong type argument to increment operator");}
	| lval DECR							{$$ = binNode(DECR, $1, intNode(INT, checkType($1->info,"pointer") ? 4 : 1)); $$->info = check1Int($1->info, "Wrong type argument to decrement operator");}
	| lval INCR							{$$ = binNode(INCR, $1, intNode(INT, checkType($1->info,"pointer") ? 4 : 1)); $$->info = check1Int($1->info, "Wrong type argument to increment operator");}
	| expr '*' expr					{$$ = binNode('*', $1, $3); $$->info = checkRealInt($1->info, $3->info, "Multiply operands must be integers or numbers");}
	| expr '/' expr					{$$ = binNode('/', $1, $3); $$->info = checkRealInt($1->info, $3->info, "Division operands must be integers or numbers");}
	| expr '%' expr					{$$ = binNode('%', $1, $3); $$->info = checkRealInt($1->info, $3->info, "Modulo operands must be integers or numbers");}
	| expr '+' expr					{$$ = binNode('+', $1, $3); $$->info = checkRealInt($1->info, $3->info, "Sum operands must be integers or numbers");}
	| expr '-' expr					{$$ = binNode('-', $1, $3); $$->info = checkRealInt($1->info, $3->info, "Diference operands must be integers or numbers");}
	| expr '<' expr					{$$ = binNode('>', $1, $3); $$->info = checkRealIntToInt($1->info, $3->info, "Less operands must be integers or numbers");}
	| expr '>' expr					{$$ = binNode('<', $1, $3); $$->info = checkRealIntToInt($1->info, $3->info, "Greater operands must be integers or numbers");}
	| expr GE expr					{$$ = binNode(GE, $1, $3);  $$->info = checkRealIntToInt($1->info, $3->info, "Greater or equal operands must be integers or numbers");}
	| expr LE expr					{$$ = binNode(LE, $1, $3);  $$->info = checkRealIntToInt($1->info, $3->info, "Less or equal operands must be integers or numbers");}
	| expr '=' expr					{$$ = binNode('=', $1, $3); $$->info = checkRealIntStrToInt($1->info, $3->info, "Equal operands must be integers/numbers or strings");}
	| expr NE expr					{$$ = binNode(NE, $1, $3);  $$->info = checkRealIntStrToInt($1->info, $3->info, "Not equal operands must be integers/numbers or strings");}
	| '~' expr							{$$ = uniNode('~', $2);			$$->info = check1Int($2->info, "Wrong type argument to logical negation");}
	| expr '&' expr					{$$ = binNode('&', $1, $3); $$->info = checkInt($1->info, $3->info, "Logical AND operands must be integers");}
	| expr '|' expr					{$$ = binNode('|', $1, $3); $$->info = checkInt($1->info, $3->info, "Logical OR operands must be integers");}
	| lval ATR expr					{$$ = binNode(ATR, $3, $1); compareTypes($1->info, $3->info);
													if(!checkType($1->info, "index") && checkType($1->info, "const")) {	yyerror("Constant id can't be modified"); return 1;}
												 	$$->info = $3->info;}
	;

lval: ID							{$$ = strNode(ID, $1); $$->info = IDfind($1, 0);}
	| lval '[' expr ']' {$$ = binNode(INDEX, $1, $3); int type = $1->info; if(!checkType(type, "pointer") && !checkType(type, "string")) yyerror("Indexed value must be a pointer");
											if (checkType(type, "string")) { type &= ~(1U << 2); type = setType(type, "int"); } //If indexed value is a string, clears string type and assigns int type
	 										$$->info = setType(type, "index");}
	;

%%

char **yynames =
#if YYDEBUG > 0
		 (char**)yyname;
#else
		 0;
#endif

/* Sets n'th bit of num to 1*/
int setBit(int num, int n){
	return num | 1U << n;
}

/* Checks if n'th bit of num is 1*/
int checkBit(int num, int n){
	return (num >> n) & 1U;
}

/* Maps each bit of num to a type defined by the string */
int setType(int num, char* type){

	if (strcmp(type, "int") == 0) return setBit(num, 1);
	if (strcmp(type, "string") == 0) return setBit(num, 2);
	if (strcmp(type, "number") == 0) return setBit(num, 3);
	if (strcmp(type, "void") == 0) return setBit(num, 4);
	if (strcmp(type, "public") == 0) return setBit(num, 5);
	if (strcmp(type, "const") == 0) return setBit(num, 6);
	if (strcmp(type, "function") == 0) return setBit(num, 7);
	if (strcmp(type, "pointer") == 0) return setBit(num, 8);
	if (strcmp(type, "const_string") == 0) return setBit(num, 9);
	if (strcmp(type, "index") == 0) return setBit(num, 10);
	if (strcmp(type, "init") == 0) return setBit(num, 11);

	yyerror("Wrong type in setType");
	return 0;
	}

/* Checks the Map created for num and string type */
	int checkType(int num, char* type){
		if (strcmp(type, "int") == 0) return checkBit(num, 1);
		if (strcmp(type, "string") == 0) return checkBit(num, 2);
		if (strcmp(type, "number") == 0) return checkBit(num, 3);
		if (strcmp(type, "void") == 0) return checkBit(num, 4);
		if (strcmp(type, "public") == 0) return checkBit(num, 5);
		if (strcmp(type, "const") == 0) return checkBit(num, 6);
		if (strcmp(type, "function") == 0) return checkBit(num, 7);
		if (strcmp(type, "pointer") == 0) return checkBit(num, 8);
		if (strcmp(type, "const_string") == 0) return checkBit(num, 9);
		if (strcmp(type, "index") == 0) return checkBit(num, 10);
		if (strcmp(type, "init") == 0) return checkBit(num, 11);

		yyerror("Wrong type in getType");
		return 0;
		}

int compareTypes(int t1, int t2){

	if (checkType(t1, "string") && checkType(t1, "index")
			&& !checkType(t2, "int")){
				yyerror("Index must be an integer");
				return 1;
			}


		if(checkType(t1, "index") && checkType(t1, "string")
		&& checkType(t1, "const_string") && checkType(t2, "int")){
			yyerror("Can't modify constant string");
			return 1;
		}

		if (!checkType(t1, "index")) {
			if ( !( ((checkType(t1, "string") && checkType(t2, "int"))
			|| (checkType(t1, "int") && checkType(t2, "string"))
			|| (checkType(t1, "int") && checkType(t2, "int"))
			|| (checkType(t1, "number") && checkType(t2, "number"))
			|| (checkType(t1, "number") && checkType(t2, "int"))
			|| (checkType(t1, "string") && checkType(t2, "string"))
			|| (checkType(t1, "void") && !checkType(t2, "void")))) )
					yyerror("Illegal initialization");
					return 1;
		}

	return 0;
}

/* Checks any combination between real and int. If both are int, returns int, else returns number */
int checkRealInt(int type1, int type2, char* error){
	int type = 0;
	if(checkType(type1, "int") && checkType(type2, "int")) return setType(type, "int");
	else if((checkType(type1, "number") && checkType(type2, "int"))
			 || (checkType(type1, "int") && checkType(type2, "number"))
			 || (checkType(type1, "number") && checkType(type2, "number"))) {
				 return setType(type, "number");}
	else yyerror(error);
}

/* Checks any combination between real and int. Returns int type*/
int checkRealIntToInt(int type1, int type2, char* error){
	int type = 0;
	if( (checkType(type1, "int") && checkType(type2, "int"))
	 || (checkType(type1, "number") && checkType(type2, "int"))
	 || (checkType(type1, "int") && checkType(type2, "number"))
	 || (checkType(type1, "number") && checkType(type2, "number")))
	 		{ return setType(type, "int");}
	else yyerror(error);
}

/* Checks combinations between real, int and string. Returns int type*/
int checkRealIntStrToInt(int type1, int type2, char* error){
	int type = 0;
	if( (checkType(type1, "int") && checkType(type2, "int"))
	 || (checkType(type1, "number") && checkType(type2, "int"))
	 || (checkType(type1, "int") && checkType(type2, "number"))
	 || (checkType(type1, "number") && checkType(type2, "number"))
	 || (checkType(type1, "string") && checkType(type2, "string"))
	 || (checkType(type1, "string") && checkType(type2, "int"))
	 || (checkType(type1, "int") && checkType(type2, "string")))
	 		{ return setType(type, "int");}
	else yyerror(error);
}
/* Checks if type is int. Returns int type*/
int check1Int(int type1,  char* error){
	int type = 0;
	if(checkType(type1, "int") ) return setType(type, "int");
	else yyerror(error);
}

/* Checks if both types are int. Returns int type */
int checkInt(int type1, int type2, char* error){
	int type = 0;
	if(checkType(type1, "int") && checkType(type2, "int")) return setType(type, "int");
	else yyerror(error);
}

/* Given the Nodes, builds a new type with the defined mapping system */
int newType(Node* pu_node, Node* c_node, Node* t_node, Node* po_node){
	int type = 0;
	if(pu_node->info) type = setType(type, "public");
	if(c_node->info) type = setType(type, "const");
	if(t_node->info == 0) type = setType(type, "int");
	if(t_node->info == 1) type = setType(type, "string");
	if(t_node->info == 2) type = setType(type, "number");
	if(t_node->info == 3) type = setType(type, "void");
	if(po_node->info) type = setType(type, "pointer");
	return type;

	}
