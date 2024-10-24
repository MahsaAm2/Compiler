%{
#include <stdio.h> 
#include <math.h> 
#include <stdlib.h>
#include <iostream>
#include <string.h>
#include <cstdio>

using namespace std;

extern int yylex();
extern int yyparse();
extern FILE *yyin;

int yyerror(const char* message);

char tmp[20];
int printType;
struct node{
	string name;
	string value;
	struct node* c[15];
	int n;
	int type;
};
struct node* nonT(string name, string val );
struct node* tokenNode(string name, string val);
void preorderVal(struct node*, int tabNum);

%}

%union{
	int numVal;
	char* strVal;
	bool boolVal;
	char charVal;
	float fVal;
	struct node* nodeVal;
}


%nterm <nodeVal> program arr_id field_type field_name field_decl field funcname funcargs6 funcargs5 
funcargs4 funcargs3 funcargs2 funcargs funcbody method_decl main_method method varlist type var_decl varDec else_block ifstmt forstmt returnstmt statment stmt block assign_op method_name callout_arg callout_list call_argu arg_list4 arg_list3 arg_list2 arg_list1 arg_list
method_call array_id location expr term literal id int_literal decimal_literal hex_literal bool_literal char_literal string_literal ;

%token<strVal> TOKEN_STRINGCONST TOKEN_ID 
%token<numVal> TOKEN_DECIMALCONST TOKEN_HEXADECIMALCONST
%token<boolVal> TOKEN_BOOLEANCONST 
%token<charVal> TOKEN_CHARCONST 
%token<strVal>
	TOKEN_CLASS  TOKEN_PROGRAMCLASS TOKEN_VOIDTYPE
	TOKEN_INTTYPE TOKEN_BOOLEANTYPE TOKEN_ELSECONDITION
	TOKEN_IFCONDITION TOKEN_LOOP TOKEN_RETURN
	TOKEN_BREAKSTMT TOKEN_CONTINUESTMT
	TOKEN_CALLOUT TOKEN_MAINFUNC
%token<strVal> 
	TOKEN_ASSIGNOP_ASSIGN TOKEN_ASSIGNOP_ADDITIONASSIGN TOKEN_ASSIGNOP_SUBTRACTIONASSIGN 
	TOKEN_CONDITIONOP_OR TOKEN_CONDITIONOP_AND TOKEN_EQUALITYOP_EQ TOKEN_EQUALITYOP_NOTEQ
	TOKEN_RELATIONOP_L TOKEN_RELATIONOP_LEQ TOKEN_RELATIONOP_S TOKEN_RELATIONOP_SEQ
	TOKEN_ARITHMATICOP_PLUS TOKEN_ARITHMATICOP_MINUS
	TOKEN_ARITHMATICOP_MULT TOKEN_ARITHMATICOP_DIVISION TOKEN_ARITHMATICOP_REMAIN
	TOKEN_LOGICOP TOKEN_LB TOKEN_RB TOKEN_LP TOKEN_RP TOKEN_RCB TOKEN_LCB
	TOKEN_SEMICOLON TOKEN_COMMA
	
/*%token<strVal> TOKEN_STRINGCONST "string" TOKEN_ID "identifier"
%token<numVal> TOKEN_DECIMALCONST "DecNumber" TOKEN_HEXADECIMALCONST "hexNumber"
%token<boolVal> TOKEN_BOOLEANCONST "bool"
%token<charVal> TOKEN_CHARCONST "char"
%token
	TOKEN_CLASS "class"  TOKEN_PROGRAM "program" TOKEN_VOIDTYPE "void"
	TOKEN_INTTYPE "int" TOKEN_BOOLEANTYPE "boolean" TOKEN_ELSECONDITION "else"
	TOKEN_IFCONDITION "if" TOKEN_LOOP "for" TOKEN_RETURN "return"
	TOKEN_BREAKSTMT "break" TOKEN_CONTINUESTMT "continue"
	TOKEN_CALLOUT "callout" TOKEN_MAINFUNC "main"
*/
/*	
%left arith_op
%left cond_op
%left eq_op
%left rel_op
*/
		
%left TOKEN_ASSIGNOP_ASSIGN TOKEN_ASSIGNOP_ADDITIONASSIGN TOKEN_ASSIGNOP_SUBTRACTIONASSIGN
%left TOKEN_CONDITIONOP_OR
%left TOKEN_CONDITIONOP_AND
%nonassoc TOKEN_EQUALITYOP_EQ TOKEN_EQUALITYOP_NOTEQ
%nonassoc TOKEN_RELATIONOP_L TOKEN_RELATIONOP_LEQ TOKEN_RELATIONOP_S TOKEN_RELATIONOP_SEQ
%left TOKEN_ARITHMATICOP_PLUS TOKEN_ARITHMATICOP_MINUS
%left TOKEN_ARITHMATICOP_MULT TOKEN_ARITHMATICOP_DIVISION TOKEN_ARITHMATICOP_REMAIN
%right TOKEN_LOGICOP UMINUS
%left TOKEN_LB TOKEN_RB
%left TOKEN_LP TOKEN_RP

%start program

%%
program: 	TOKEN_CLASS TOKEN_PROGRAMCLASS TOKEN_LCB field method TOKEN_RCB {$$ = nonT("<program>", "<program>"); $$->c[0] = tokenNode("TOKEN_CLASS", string($1)); $$->c[1] = tokenNode("TOKEN_PROGRAMCLASS", string($2)); $$->c[2] = tokenNode("TOKEN_LCB", string($3)); $$->c[3] = $4; $$->c[4] = $5; $$->c[5] = tokenNode("TOKEN_RCB", string($6)); $$->n=6; /*cout << "parse" << endl;*/ preorderVal($$, 1); cout << endl;}
		;
		
arr_id:	TOKEN_LB int_literal TOKEN_RB { $$ = nonT("<arr_id>", "<arr_id>"); $$->c[0] = tokenNode("TOKEN_LB", string($1)); $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_RB", string($3));$$->n=3;}
		| /**/	{ $$ = nonT("<arr_id>", "<arr_id>");$$->n=0;}
		;
		
field_type: 	id arr_id { $$ = nonT("<field_type>", "<field_type>"); $$->c[0] = $1; $$->c[1] =$2; $$->n=2;}
		;
			
field_name:	field_type { $$ = nonT("<field_name>", "<field_name>"); $$->c[0] = $1; $$->n=1;}
		| field_name TOKEN_COMMA field_type { $$ = nonT("<field_name>", "<field_name>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_COMMA", string($2)); $$->c[2] = $3; $$->n=3;}
		;		
				
field_decl:	type field_name TOKEN_SEMICOLON { $$ = nonT("<field_decl>", "<field_decl>"); $$->c[0] = $1; $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_SEMICOLON", string($3)); $$->n=3;}
		;
		
field:		field field_decl { $$ = nonT("<field>", "<field>"); $$->c[0] = $1; $$->c[1] = $2; $$->n=2;}
		| /*empty*/ { $$ = nonT("<field>", "<field>"); $$->n=0;}
		;
		
/*return_type:	type { $$ = nonT("<return_type>", "<return_type>"); $$->c[0] = $1; $$->n=1;}
		| TOKEN_VOIDTYPE { $$ = nonT("<return_type>", "<return_type>"); $$->c[0] = tokenNode("TOKEN_VOIDTYPE", string($1)); $$->n=1;}
		;
*/
		
funcname:	id { $$ = nonT("<funcname>", "<funcname>"); $$->c[0] = $1; $$->n=1;}
		;

funcargs6:	type id TOKEN_COMMA type id TOKEN_COMMA type id TOKEN_COMMA type id { $$ = nonT("<funcargs6>", "<funcargs6>"); $$->c[0] = $1; $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_COMMA", string($3)); $$->c[3] = $4; $$->c[4] = $5; $$->c[5] = tokenNode("TOKEN_COMMA", string($6)); $$->c[6] = $7; $$->c[7] = $8; $$->c[8] = tokenNode("TOKEN_COMMA", string($9)); $$->c[9] = $10; $$->c[10] = $11; $$->n=11;}
		;

funcargs5:	funcargs6 { $$ = nonT("<funcargs5>", "<funcargs5>"); $$->c[0] = $1; $$->n = 1;}
		| type id TOKEN_COMMA type id TOKEN_COMMA type id { $$ = nonT("<funcargs5>", "<funcargs5>"); $$->c[0] = $1; $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_COMMA", string($3)); $$->c[3] = $4; $$->c[4] = $5; $$->c[5] = tokenNode("TOKEN_COMMA", string($6)); $$->c[6] = $7; $$->c[7] = $8; $$->n=8;}
		;
		
funcargs4:	funcargs5 { $$ = nonT("<funcargs4>", "<funcargs4>"); $$->c[0] = $1; $$->n = 1;}
		| type id TOKEN_COMMA type id { $$ = nonT("<funcargs4>", "<funcargs4>"); $$->c[0] = $1; $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_COMMA", string($3)); $$->c[3] = $4; $$->c[4] = $5; $$->n=5;}
		;		
		
funcargs3:	funcargs4 { $$ = nonT("<funcargs3>", "<funcargs3>"); $$->c[0] = $1; $$->n = 1;}
		| type id { $$ = nonT("<funcargs3>", "<funcargs3>"); $$->c[0] = $1; $$->c[1] = $2; $$->n=2;}	
		;
	
funcargs2:	funcargs3 { $$ = nonT("<funcargs2>", "<funcargs2>"); $$->c[0] = $1; $$->n = 1;}
		| /**/ { $$ = nonT("<funcargs2>", "<funcargs2>"); $$->n = 0;}
		;	

funcargs:	TOKEN_LP funcargs2 TOKEN_RP { $$ = nonT("<funcargs>", "<funcargs>"); $$->c[0] = tokenNode("TOKEN_LP", string($1)); $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_RP", string($3)); $$->n = 3;}
		; 
		
funcbody:	block { $$ = nonT("<funcbody>", "<funcbody>"); $$->c[0] = $1; $$->n = 1;}
		;
				
method_decl:	type funcname funcargs funcbody { $$ = nonT("<method_decl>", "<method_decl>"); $$->c[0] = $1; $$->c[1] = $2; $$->c[2] = $3; $$->c[3] = $4; $$->n = 4;}
		| TOKEN_VOIDTYPE funcname funcargs funcbody { $$ = nonT("<method_decl>", "<method_decl>"); $$->c[0] = tokenNode("TOKEN_VOIDTYPE", string($1)); $$->c[1] = $2; $$->c[2] = $3; $$->c[3] = $4; $$->n = 4;}
		;		
		
main_method:	type TOKEN_MAINFUNC TOKEN_LP TOKEN_RP funcbody { $$ = nonT("<main_method>", "<main_method>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_MAINFUNC", string($2)); $$->c[2] = tokenNode("TOKEN_LP", string($3)); $$->c[3] = tokenNode("TOKEN_RP", string($4)); $$->c[4] = $5; $$->n = 5;}
		| TOKEN_VOIDTYPE TOKEN_MAINFUNC TOKEN_LP TOKEN_RP funcbody { $$ = nonT("<main_method>", "<main_method>"); $$->c[0] = tokenNode("TOKEN_VOIDTYPE", string($1)); $$->c[1] = tokenNode("TOKEN_MAINFUNC", string($2)); $$->c[2] = tokenNode("TOKEN_LP", string($3)); $$->c[3] = tokenNode("TOKEN_RP", string($4)); $$->c[4] = $5; $$->n = 5;}
		;
		
method:	method_decl method{ $$ = nonT("<method>", "<method>"); $$->c[0] = $1; $$->c[1] = $2; $$->n = 2;}
		| main_method { $$ = nonT("<method>", "<method>"); $$->c[0] = $1; $$->n = 1;}
		;
		
varlist:	id { $$ = nonT("<varlist>", "<varlist>"); $$->c[0] = $1; $$->n = 1;}
		| varlist TOKEN_COMMA id { $$ = nonT("<varlist>", "<varlist>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_COMMA", string($2)); $$->c[2]= $3; $$->n = 3;}
		;

type:		TOKEN_INTTYPE { $$ = nonT("<type>", "<type>"); $$->c[0] = tokenNode("TOKEN_INTTYPE", string($1)); $$->n = 1;}
		| TOKEN_BOOLEANTYPE { $$ = nonT("<type>", "<type>"); $$->c[0] = tokenNode("TOKEN_BOOLEANTYPE", string($1)); $$->n = 1;}
		;
		
var_decl:	type varlist TOKEN_SEMICOLON{ $$ = nonT("<var_decl>", "<var_decl>"); $$->c[0] = $1; $$->c[1]=$2; $$->c[2]=tokenNode("TOKEN_SEMICOLON", string($3)); $$->n = 3; }
		;	
		
varDec:	varDec var_decl { $$ = nonT("<varDec>", "<varDec>"); $$->c[0] = $1; $$->c[1] = $2; $$->n = 2;}
		| /**/ { $$ = nonT("<varDec>", "<varDec>"); $$->n = 0;}
		;
		
else_block:	TOKEN_ELSECONDITION block { $$ = nonT("<else_block>", "<else_block>"); $$->c[0] = tokenNode("TOKEN_ELSECONDITION", string($1)); $$->c[1] = $2; $$->n = 2;}
		| /**/ { $$ = nonT("<else_block>", "<else_block>"); $$->n = 0;}
		;		
		
ifstmt:	TOKEN_IFCONDITION TOKEN_LP expr TOKEN_RP block else_block { $$ = nonT("<ifstmt>", "<ifstmt>"); $$->c[0] = tokenNode("TOKEN_IFCONDITION", string($1)); $$->c[1] = tokenNode("TOKEN_LP", string($2)); $$->c[2] = $3; $$->c[3] = tokenNode("TOKEN_RP", string($4)); $$->c[4] = $5; $$->c[5] = $6; $$->n = 6;}
		;
		
forstmt:	TOKEN_LOOP id TOKEN_ASSIGNOP_ASSIGN expr TOKEN_COMMA expr block { $$ = nonT("<forstmt>", "<forstmt>"); $$->c[0] = tokenNode("TOKEN_LOOP", string($1)); $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_ASSIGNOP_ASSIGN", string($3)); $$->c[3] = $4; $$->c[4] = tokenNode("TOKEN_COMMA", string($5)); $$->c[5] = $6; $$->c[6] = $7; $$->n = 7;}
		;		
/*		
return_val:	expr
		| 
		;		
*/

returnstmt:	TOKEN_RETURN TOKEN_SEMICOLON { $$ = nonT("<returnstmt>", "<returnstmt>"); $$->c[0] = tokenNode("TOKEN_RETURN", string($1)); $$->c[1] = tokenNode("TOKEN_SEMICOLON", string($2)); $$->n = 2;}
		| TOKEN_RETURN expr TOKEN_SEMICOLON { $$ = nonT("<returnstmt>", "<returnstmt>"); $$->c[0] = tokenNode("TOKEN_RETURN", string($1)); $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_SEMICOLON", string($3)); $$->n = 3;}
		;
/*				
returnstmt:	TOKEN_RETURN return_val
		;*/
		
statment:	location assign_op expr TOKEN_SEMICOLON { $$ = nonT("<statment>", "<statment>"); $$->c[0] = $1; $$->c[1] = $2; $$->c[2] = $3; $$->c[3] = tokenNode("TOKEN_SEMICOLON", string($4)); $$->n = 4;}
		| method_call TOKEN_SEMICOLON { $$ = nonT("<statment>", "<statment>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_SEMICOLON", string($2)); $$->n = 2;}
		| ifstmt { $$ = nonT("<statment>", "<statment>"); $$->c[0] = $1; $$->n = 1;}
		| forstmt { $$ = nonT("<statment>", "<statment>"); $$->c[0] = $1; $$->n = 1;}
		| returnstmt { $$ = nonT("<statment>", "<statment>"); $$->c[0] = $1; $$->n = 1;}
		| TOKEN_BREAKSTMT TOKEN_SEMICOLON { $$ = nonT("<statment>", "<statment>"); $$->c[0] = tokenNode("TOKEN_BREAKSTMT", string($1)); $$->c[1] = tokenNode("TOKEN_SEMICOLON", string($2)); $$->n = 2;}
		| TOKEN_CONTINUESTMT TOKEN_SEMICOLON { $$ = nonT("<statment>", "<statment>"); $$->c[0] = tokenNode("TOKEN_CONTINUESTMT", string($1)); $$->c[1] = tokenNode("TOKEN_SEMICOLON", string($2)); $$->n = 2;}
		| block { $$ = nonT("<statment>", "<statment>"); $$->c[0] = $1; $$->n = 1;}
		;		
	
stmt:		stmt statment { $$ = nonT("<stmt>", "<stmt>"); $$->c[0] = $1; $$->c[1] = $2; $$->n = 2;}
		| /**/ { $$ = nonT("<stmt>", "<stmt>"); $$->n = 0;}
		;		
		
block:		TOKEN_LCB varDec stmt TOKEN_RCB { $$ = nonT("<block>", "<block>"); $$->c[0] = tokenNode("TOKEN_LCB", string($1)); $$->c[1] = $2; $$->c[2] = $3; $$->c[3] = tokenNode("TOKEN_RCB", string($4)); $$->n = 4;}		
		;
		
assign_op:	TOKEN_ASSIGNOP_ASSIGN  { $$ = nonT("<assign_op>", "<assign_op>"); $$->c[0] = tokenNode("TOKEN_ASSIGNOP_ASSIGN", string($1)); $$->n = 1;}	
		| TOKEN_ASSIGNOP_ADDITIONASSIGN { $$ = nonT("<assign_op>", "<assign_op>"); $$->c[0] = tokenNode("TOKEN_ASSIGNOP_ADDITIONASSIGN", string($1)); $$->n = 1;}
		| TOKEN_ASSIGNOP_SUBTRACTIONASSIGN { $$ = nonT("<assign_op>", "<assign_op>"); $$->c[0] = tokenNode("TOKEN_ASSIGNOP_SUBTRACTIONASSIGN", string($1)); $$->n = 1;}
		;
		
method_name:	id { $$ = nonT("<method_name>", "<method_name>"); $$->c[0] = $1; $$->n = 1;}
		;		
		
callout_arg:	expr { $$ = nonT("<callout_arg>", "<callout_arg>"); $$->c[0] = $1; $$->n = 1;}
		| string_literal { $$ = nonT("<callout_arg>", "<callout_arg>"); $$->c[0] = $1; $$->n = 1;}
		;		
		
callout_list:	callout_arg { $$ = nonT("<callout_list>", "<callout_list>"); $$->c[0] = $1; $$->n = 1;}
		| callout_list TOKEN_COMMA callout_arg { $$ = nonT("<callout_list>", "<callout_list>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_COMMA", string($2)); $$->c[2] = $3; $$->n = 3;}
		;		
		
call_argu: 	TOKEN_COMMA callout_list { $$ = nonT("<call_argu>", "<call_argu>"); $$->c[0] = tokenNode("TOKEN_COMMA", string($1)); $$->c[1] = $2; $$->n = 2;}
		| /**/	{ $$ = nonT("<call_argu>", "<call_argu>"); $$->n = 0;}
		;
		
arg_list4:	expr TOKEN_COMMA expr TOKEN_COMMA expr TOKEN_COMMA expr { $$ = nonT("<arg_list4>", "<arg_list4>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_COMMA", string($2)); $$->c[2] = $3; $$->c[3] = tokenNode("TOKEN_COMMA", string($4)); $$->c[4] = $5; $$->c[5] = tokenNode("TOKEN_COMMA", string($6)); $$->c[6] = $7; $$->n=7;}
		;		
		
arg_list3:	arg_list4 { $$ = nonT("<arg_list3>", "<arg_list3>"); $$->c[0] = $1; $$->n=1;}
		| expr TOKEN_COMMA expr TOKEN_COMMA expr { $$ = nonT("<arg_list3>", "<arg_list3>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_COMMA", string($2)); $$->c[2] = $3; $$->c[3] = tokenNode("TOKEN_COMMA", string($4)); $$->c[4] = $5; $$->n=5;}		
		;
		
arg_list2:	arg_list3 { $$ = nonT("<arg_list2>", "<arg_list2>"); $$->c[0] = $1; $$->n=1;}
		| expr TOKEN_COMMA expr { $$ = nonT("<arg_list2>", "<arg_list2>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_COMMA", string($2)); $$->c[2] = $3; $$->n=3;}
		;
		
arg_list1:	arg_list2  { $$ = nonT("<arg_list1>", "<arg_list1>"); $$->c[0] = $1; $$->n=1;}
		| expr  { $$ = nonT("<arg_list1>", "<arg_list1>"); $$->c[0] = $1; $$->n=1;}
		;

arg_list:	arg_list1 { $$ = nonT("<arg_list>", "<arg_list>"); $$->c[0] = $1; $$->n=1;}
		| /**/ { $$ = nonT("<arg_list>", "<arg_list>"); $$->n=0;}
		;		
		
method_call:	method_name TOKEN_LP arg_list TOKEN_RP { $$ = nonT("<method_call>", "<method_call>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_LP", string($2)); $$->c[2] = $3; $$->c[3] = tokenNode("TOKEN_RP", string($4)); $$->n=4;}
		| TOKEN_CALLOUT TOKEN_LP string_literal call_argu TOKEN_RP { $$ = nonT("<method_call>", "<method_call>"); $$->c[0] = tokenNode("TOKEN_CALLOUT", string($1)); $$->c[1] = tokenNode("TOKEN_LP", string($2)); $$->c[2] = $3;  $$->c[3] = $4; $$->c[4] = tokenNode("TOKEN_RP", string($5)); $$->n=5;}
		;
		
array_id:	TOKEN_LB expr TOKEN_RB { $$ = nonT("<array_id>", "<array_id>"); $$->c[0] = tokenNode("TOKEN_LB", string($1)); $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_RB", string($3)); $$->n=3;}
		| /**/ { $$ = nonT("<array_id>", "<array_id>"); $$->n=0;}
		;		
		
location:	id array_id { $$ = nonT("<location>", "<location>"); $$->c[0] = $1; $$->c[1] = $2; $$->n=2;}
		;
/*
expr:		location
		| method_call
		| literal
		| expr bin_op expr
		| term
		;*/
		
expr:		location { $$ = nonT("<expr>", "<expr>"); $$->c[0] = $1; $$->n=1;}
		| method_call { $$ = nonT("<expr>", "<expr>"); $$->c[0] = $1; $$->n=1;}
		| literal { $$ = nonT("<expr>", "<expr>"); $$->c[0] = $1; $$->n=1;}
		| term { $$ = nonT("<expr>", "<expr>"); $$->c[0] = $1; $$->n=1;}
		| expr TOKEN_ARITHMATICOP_PLUS expr { $$=nonT("<expr>", "<expr>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_ARITHMATICOP_PLUS", string($2)); $$->c[2]= $3; $$->n = 3;}
		| expr TOKEN_ARITHMATICOP_MINUS expr { $$=nonT("<expr>", "<expr>"); $$->c[0]= $1; $$->c[1]= tokenNode("TOKEN_ARITHMATICOP_MINUS", string($2)); $$->c[2]= $3; $$->n = 3;}	
		| expr TOKEN_ARITHMATICOP_MULT expr { $$=nonT("<expr>", "<expr>"); $$->c[0] = $1; $$->c[1] = tokenNode("TOKEN_ARITHMATICOP_MULT", string($2)); $$->c[2]= $3; $$->n = 3;}	
		| expr TOKEN_ARITHMATICOP_DIVISION expr {$$=nonT("<expr>", "<expr>");$$->c[0]=$1; $$->c[1]=tokenNode("TOKEN_ARITHMATICOP_DIVISION", string($2)); $$->c[2]=$3; $$->n= 3;} 
		| expr TOKEN_ARITHMATICOP_REMAIN expr { $$=nonT("<expr>", "<expr>");$$->c[0] =$1; $$->c[1] =tokenNode("TOKEN_ARITHMATICOP_REMAIN", string($2)); $$->c[2]=$3; $$->n = 3;}	
		| expr TOKEN_RELATIONOP_SEQ expr { $$=nonT("<expr>", "<expr>");$$->c[0] =$1; $$->c[1] =tokenNode("TOKEN_RELATIONOP_SEQ", string($2)); $$->c[2]=$3; $$->n = 3;}
		| expr TOKEN_RELATIONOP_LEQ expr { $$=nonT("<expr>", "<expr>");$$->c[0] =$1; $$->c[1] =tokenNode("TOKEN_RELATIONOP_LEQ", string($2)); $$->c[2]=$3; $$->n = 3;}	
		| expr TOKEN_RELATIONOP_S expr { $$=nonT("<expr>", "<expr>");$$->c[0] =$1; $$->c[1] =tokenNode("TOKEN_RELATIONOP_S", string($2)); $$->c[2]=$3; $$->n = 3;}	
		| expr TOKEN_RELATIONOP_L expr { $$=nonT("<expr>", "<expr>");$$->c[0] =$1; $$->c[1] =tokenNode("TOKEN_RELATIONOP_L", string($2)); $$->c[2]=$3; $$->n = 3;}	
		| expr TOKEN_EQUALITYOP_EQ expr { $$=nonT("<expr>", "<expr>");$$->c[0] =$1; $$->c[1] =tokenNode("TOKEN_EQUALITYOP_EQ", string($2)); $$->c[2]=$3; $$->n = 3;}
		| expr TOKEN_EQUALITYOP_NOTEQ expr { $$=nonT("<expr>", "<expr>");$$->c[0] =$1; $$->c[1] =tokenNode("TOKEN_EQUALITYOP_NOTEQ", string($2)); $$->c[2]=$3; $$->n = 3;} 
		| expr TOKEN_CONDITIONOP_AND expr { $$=nonT("<expr>", "<expr>");$$->c[0] =$1; $$->c[1] =tokenNode("TOKEN_CONDITIONOP_AND", string($2)); $$->c[2]=$3; $$->n = 3;}
		| expr TOKEN_CONDITIONOP_OR expr { $$=nonT("<expr>", "<expr>");$$->c[0] =$1; $$->c[1] =tokenNode("TOKEN_CONDITIONOP_OR", string($2)); $$->c[2]=$3; $$->n = 3;}
		;

term:		TOKEN_LP expr TOKEN_RP { $$ = nonT("<term>", "<term>"); $$->c[0] = tokenNode("TOKEN_LP", string($1)); $$->c[1] = $2; $$->c[2] = tokenNode("TOKEN_RP", string($3)); $$->n = 3;}
		| TOKEN_LOGICOP expr { $$ = nonT("<term>", "<term>"); $$->c[0] = tokenNode("TOKEN_LOGICOP", string($1)); $$->c[1] = $2; $$->n = 2;}
		| '-' expr %prec UMINUS { $$ = nonT("<term>", "<term>"); $$->c[0] = tokenNode("TOKEN_NEG", "-"); $$->c[1] = $2; $$->n = 2;}
		;
/*		
expr:		location
		| method_call
		| literal
		| expr bin_op expr
		| '-' expr
		| '!' expr
		| '(' expr ')'
		;
		
bin_op:	arith_op
		| rel_op
		| eq_op
		| cond_op
		;
		
arith_op:	'+'
		| '-'
		| '*'
		| '/'
		| '%'
		;
		
rel_op:	'<'
		| '>'
		| "<="
		| ">="
		;
		
eq_op:		"=="
		| "!="
		;
		
cond_op: 	"&&"
		| "||"
		;
		*/
literal:	int_literal { $$ = nonT("<literal>", "<literal>"); $$->c[0] = $1; $$->n=1;}
		| char_literal { $$ = nonT("<literal>", "<literal>"); $$->c[0] = $1; $$->n=1;}
		| bool_literal { $$ = nonT("<literal>", "<literal>"); $$->c[0] = $1; $$->n=1;}
		;
		
id:		TOKEN_ID { $$ = nonT("<id>", "<id>"); $$->c[0] = tokenNode("TOKEN_ID", string($1)); $$->n = 1;}	
		;
		
int_literal:	decimal_literal { $$ = nonT("<int_literal>", "<int_literal>"); $$->c[0] = $1; $$->n=1;}
		| hex_literal { $$ = nonT("<int_literal>", "<int_literal>"); $$->c[0] = $1; $$->n=1;}
		;
		
decimal_literal: TOKEN_DECIMALCONST { $$ = nonT("<decimal_literal>", "<decimal_literal>"); sprintf(tmp, "%d", $1); $$->c[0] = tokenNode("TOKEN_DECIMALCONST", string(tmp) ); $$->n = 1;}
		;
		
hex_literal:	TOKEN_HEXADECIMALCONST { $$ = nonT("<hex_literal>", "<hex_literal>"); sprintf(tmp, "%d", $1); $$->c[0] = tokenNode("TOKEN_HEXADECIMALCONST", string(tmp) ); $$->n = 1;}
		;		
		
bool_literal:	TOKEN_BOOLEANCONST { $$ = nonT("<bool_literal>", "<bool_literal>"); $$->c[0] = tokenNode("TOKEN_BOOLEANCONST", $1? "true": "false" ); $$->n = 1;}
		;
		
char_literal:	TOKEN_CHARCONST { $$ = nonT("<char_literal>", "<char_literal>"); $$->c[0] = tokenNode("TOKEN_CHARCONST",  string(1,$1) ); $$->n = 1;}
		;
		
string_literal: TOKEN_STRINGCONST { $$ = nonT("<string_literal>", "<string_literal>"); $$->c[0] = tokenNode("TOKEN_STRINGCONST", string($1)); $$->n = 1;}
		;
								
%%

node* nonT(string name, string val ){
    struct node* n = (struct node*)malloc(sizeof(struct node));
    n->name = name;
    n->value = val;
    n->type = 0; //non terminal
    return n;
}
node* tokenNode(string name, string val){
    struct node* x = (struct node*)malloc(sizeof(struct node));
    x->name = name;
    x->value = val;
    x->type = 1; // termianl
    return x;
}

void preorderVal(struct node* n, int tabNum){
	//cout << printType << endl;
    if(printType == 0)
        cout << n->value << " " ;
    else
        cout << n->name << " " ;
        
    cout << endl;    
        
    for(int i=0; i < n->n; i++){
    	for(int j=0; j<tabNum; j++)
            cout << "." << "\t";
    	if(n->c[i]->type == 1){
    	    if(printType == 0)
    	        cout << n->c[i]->value << " ";
    	    else
    	        cout << n->c[i]->name << " ";
    	    cout << endl;
    	}
    	else
    	    preorderVal(n->c[i], tabNum+1); 
    }
}


int main(int x, char** arg){
  FILE *myfile = fopen("sample.file", "r");
  // Make sure it is valid:
  if (!myfile) {
    cout << "I can't open a.snazzle.file!" << endl;
    return -1;
  }
  // Set Flex to read from it instead of defaulting to STDIN:
  yyin = myfile;
  printType = atoi(arg[1]);
  
  yyparse();
  return 0;
}

int yyerror(const char* message){
	printf("%s\n", message);
	return 0;
}

