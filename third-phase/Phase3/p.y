%{
#include <stdio.h> 
#include <math.h> 
#include <stdlib.h>
#include <iostream>
#include <string.h>
#include <cstdio>
#include <stack>
#include <vector>

using namespace std;

extern int yylex();
extern int yyparse();
extern FILE *yyin;
int yyerror(const char* message);

struct var* findVar(char* varName,string scope);
void addVar(char *varName, string scope, string reg,char type, int value);

struct arr* findArr(char* arrName,string scope);
void addArr(char *arrName, string scope, string reg,char type, int size);

struct function* findFunc(char* funcName);
void addFunc(char* funcName,char returnType,int argsNum);

string setRegister(char registerType);
void freeRegister(string registerName);

FILE* ASM;

struct var{
    char* varName;
    string scope;
    char type;
    string reg;
	int value;
};
vector <struct var*> variables;

struct arr{
	char* arrName;
	string scope;
	char type;
	string reg;
	int *value;
	int size;
};
vector <struct arr*> arrays;

struct function{
    char* funcName;
    char returnType;
    int argsNum;
};
vector <struct function*> functions;

string currScope="global";
string here;
char expType='i';
char expType2;
char typeDec;


stack <string> Stack;
  int Label = 0;//used to index labels
  int Loop = 0;//used to index loop_labels
  int Error = 0;

/*Temporary Registers*/
string t_registers[10] = {"$t0","$t1","$t2","$t3","$t4","$t5","$t6","$t7","$t8","$t9"};
bool t_registers_state[10] = {0};
/*Saved Values Registers*/
string s_registers[8] = {"$s0","$s1","$s2","$s3","$s4","$s5","$s6","$s7"};
bool s_registers_state[8] = {0};
/*Function Argument Registers*/
string a_registers[4] = {"$a0","$a1","$a2","$a3"};
bool a_registers_state[4] = {0};
/*Return Values Registers*/
string v_registers[2] = {"$v0","$v1"};

/*char tmp[20];
int printType;
struct node{
	string name;
	string value;
	struct node* c[15];
	int n;
	int type;
};*/


%}

%define parse.error verbose
%locations

%union{
	int numVal;
	char* strVal;
	bool boolVal;
	char charVal;
	float fVal;
	struct node* nodeVal;
}


%nterm program field_decl field funcbody method_decl main_method method varlist var_decl varDec else_block ifstmt forstmt returnstmt statment stmt block  method_name callout_arg callout_list call_argu arg_list4 arg_list3 arg_list2 arg_list1 arg_list
string_literal ;
%nterm <strVal> id
%nterm <numVal> expr term method_call location literal int_literal decimal_literal hex_literal bool_literal char_literal
%nterm <charVal> type field_name assign_op
%nterm <numVal> funcargs6 funcargs5 funcargs4 funcargs3 funcargs2 funcargs
//return_type
//array_id
//arr_id
//field_type
//funcname

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
	

		
%left TOKEN_ASSIGNOP_ASSIGN TOKEN_ASSIGNOP_ADDITIONASSIGN TOKEN_ASSIGNOP_SUBTRACTIONASSIGN
%left TOKEN_CONDITIONOP_OR
%left TOKEN_CONDITIONOP_AND
%nonassoc TOKEN_EQUALITYOP_EQ TOKEN_EQUALITYOP_NOTEQ
%nonassoc TOKEN_RELATIONOP_L TOKEN_RELATIONOP_LEQ TOKEN_RELATIONOP_S TOKEN_RELATIONOP_SEQ
%left TOKEN_ARITHMATICOP_PLUS TOKEN_ARITHMATICOP_MINUS
%left TOKEN_ARITHMATICOP_MULT TOKEN_ARITHMATICOP_DIVISION TOKEN_ARITHMATICOP_REMAIN
%right TOKEN_LOGICOP
%right UMINUS
%left TOKEN_LB TOKEN_RB
%left TOKEN_LP TOKEN_RP

%start program

%%
program: 	TOKEN_CLASS TOKEN_PROGRAMCLASS TOKEN_LCB 
		{
			ASM = fopen("Output.asm", "a+");
          	fprintf(ASM,".global main\n");
          	fclose(ASM);
		} 
		field method TOKEN_RCB {}
		;
			
field_name:	type id 
		{ 
			addVar($2, currScope, setRegister('s'), $1, 0);
			$$ = $1;
		}
		| type id TOKEN_LB int_literal TOKEN_RB 
		{
			if($4<1){
				string message = "index is less than 1 for array " + string($2);
  				yyerror(message.c_str());
			}
			else{
				addArr($2,currScope,setRegister('s'),$1, $4);

				ASM = fopen("Output.asm", "a+");
				fprintf(ASM,"\taddi $a0,$zero,%d\n", $4*4);
				fprintf(ASM,"\tli $v0,9\n\tsyscall\n");
				fprintf(ASM,"\tmove %s,$v0\n", (findVar($2,currScope)->reg).c_str());
				fclose(ASM);

				$$ = $1;
			}
		}
		| field_name TOKEN_COMMA id 
		{
			addVar($3, currScope, setRegister('s'), $1, 0);
		}
		| field_name TOKEN_COMMA id TOKEN_LB int_literal TOKEN_RB 
		{
			if($5<1){
				string message = "index is less than 1 for array " + string($3);
  				yyerror(message.c_str());
			}
			else{
				addArr($3,currScope,setRegister('s'),$1, $5);

				ASM = fopen("Output.asm", "a+");
				fprintf(ASM,"\taddi $a0,$zero,%d\n", $5*4);
				fprintf(ASM,"\tli $v0,9\n\tsyscall\n");
				fprintf(ASM,"\tmove %s,$v0\n", (findVar($3,currScope)->reg).c_str());
				fclose(ASM);
			}
		}
		;		

field_decl:	field_name TOKEN_SEMICOLON {}
		;		
		
field:		field field_decl { }
		| /*empty*/ { }
		;
		
/*return_type:	type {}
		| TOKEN_VOIDTYPE { }
		;
*/		
/*funcname:	id { }
		;
*/

argum: 	type id
      	{
        	addVar($2,currScope,setRegister('s'),$1, 0);
    	};
		
funcargs6:	argum TOKEN_COMMA argum TOKEN_COMMA argum TOKEN_COMMA argum { $$ = 4;}
		;

funcargs5:	funcargs6 { $$ = $1;}
		| argum TOKEN_COMMA argum TOKEN_COMMA argum {$$ = 3;}
		;
		
funcargs4:	funcargs5 { $$ = $1;}
		| argum TOKEN_COMMA argum {$$ = 2;} 
		;		
		
funcargs3:	funcargs4 { $$ = $1; }
		| argum { $$ = 1;}	
		;
	
funcargs2:	funcargs3 { $$ = $1; }
		| /**/ { $$ = 0; }
		;	

funcargs:	TOKEN_LP funcargs2 TOKEN_RP { $$ = $2; }
		; 
		
funcbody:	block { }
		;
				
method_decl:	type id 
		{
			here = string($2);
    	    currScope = currScope + " " + string($2);
        	ASM = fopen("Output.asm", "a+");
        	fprintf(ASM,"%s:\n", $2);
			fprintf(ASM,"\taddi $sp,$sp,-32\n");
			for(int i=0; i<8; i++)
				fprintf(ASM,"\tsw $s%d, %d($sp)\n", i, i*4);
  			fclose(ASM);
		}
		funcargs 
		{
        	addFunc($2,$1,$4);
		}
		funcbody 
		{
			currScope.erase(currScope.size()-(string($2).size()+1),string($2).size()+1);
        	ASM = fopen("Output.asm", "a+");
        	for(int i=0; i<8; i++)
          		fprintf(ASM,"\tlw $s%d,%d($sp)\n", i, i*4);
        	fprintf(ASM,"\taddi $sp,$sp,32\n");
        	fprintf(ASM,"\tjr $ra\n");
        	fclose(ASM);
        	here="";
		}
		| TOKEN_VOIDTYPE id
		{
			here = string($2);
    	    currScope = currScope + " " + string($2);
        	ASM = fopen("Output.asm", "a+");
        	fprintf(ASM,"%s:\n", $2);
			fprintf(ASM,"\taddi $sp,$sp,-32\n");
			for(int i=0; i<8; i++)
				fprintf(ASM,"\tsw $s%d, %d($sp)\n", i, i*4);
  			fclose(ASM);
		}		 
		funcargs 
		{
        	addFunc($2,'v',$4);
		}
		funcbody 
		{ 
			currScope.erase(currScope.size()-(string($2).size()+1),string($2).size()+1);
        	ASM = fopen("Output.asm", "a+");
        	for(int i=0; i<8; i++)
          		fprintf(ASM,"\tlw $s%d,%d($sp)\n", i, i*4);
        	fprintf(ASM,"\taddi $sp,$sp,32\n");
        	fprintf(ASM,"\tjr $ra\n");
        	fclose(ASM);
        	here="";
		}
		;		
		
main_method:	type TOKEN_MAINFUNC 
		{
			currScope = currScope + " " + "main";
        	ASM = fopen("Output.asm", "a+");
        	fprintf(ASM,"main:\n");
        	fclose(ASM);
        	here="main";
      	}
		TOKEN_LP TOKEN_RP funcbody 
		{ 
        	currScope.erase(currScope.size()-(string("main").size()+1),string("main").size()+1);
        
			ASM = fopen("Output.asm", "a+");
        	fprintf(ASM,"\tli %s,10\n","$v0");
			fprintf(ASM,"\tsyscall\n");
        	fclose(ASM);
		}
		|TOKEN_VOIDTYPE TOKEN_MAINFUNC 
		{
			currScope = currScope + " " + "main";
        	ASM = fopen("Output.asm", "a+");
        	fprintf(ASM,"main:\n");
        	fclose(ASM);
        	here="main";
      	}
		TOKEN_LP TOKEN_RP funcbody 
		{ 
        	currScope.erase(currScope.size()-(string("main").size()+1),string("main").size()+1);
        
			ASM = fopen("Output.asm", "a+");
        	fprintf(ASM,"\tli %s,10\n","$v0");
			fprintf(ASM,"\tsyscall\n");
        	fclose(ASM);
		}
		;
		
method:	method_decl method { }
		| main_method {}
		;
		
varlist:	id 
		{ 
			addVar($1, currScope, setRegister('s'), typeDec, 0);
		}
		| varlist TOKEN_COMMA id 
		{ 
			addVar($3, currScope, setRegister('s'), typeDec, 0);
		}
		;

type:	TOKEN_INTTYPE 
		{ 
			$$ = 'i';
		}
		| TOKEN_BOOLEANTYPE 
		{ 
			$$ = 'b';
		}
		;
		
var_decl:	type {typeDec = $1;} varlist TOKEN_SEMICOLON{ }
		;	
		
varDec:	varDec var_decl {}
		| /**/ { }
		;
		
else_block:	TOKEN_ELSECONDITION 
		{
			currScope.erase(currScope.size()-(string("if").size()+1),string("if").size()+1);
          	currScope=currScope+" "+"else";
    	    Label++;
          	ASM = fopen("Output.asm", "a+");
          	fprintf(ASM,"\tj L%d\n", Label);
          	fprintf(ASM,"\tL%d:\n", Label-1);
          	fclose(ASM);
		}
		block 
		{ 
			currScope.erase(currScope.size()-(string("else").size()+1),string("else").size()+1);
        	ASM = fopen("Output.asm", "a+");
          	fprintf(ASM,"\tL%d : \n", Label);
          	fclose(ASM);
		}
		| /**/ 
		{
          	ASM = fopen("Output.asm", "a+");
          	fprintf(ASM,"\tL%d:\n", Label);
          	fclose(ASM);
			currScope.erase(currScope.size()-(string("if").size()+1),string("if").size()+1);

        }
		;		
		
ifstmt:	TOKEN_IFCONDITION TOKEN_LP expr
		{
			if(expType != 'b')
			{
				string message = "expr for 'if' must be boolean";
  				yyerror(message.c_str());
			}
			else{
				currScope=currScope+" "+"if";
				string Rd = Stack.top();
				Stack.pop();
				Label++;
				ASM = fopen("Output.asm", "a+");
				fprintf(ASM,"\tbeq %s,$zero,L%d\n", Rd.c_str(), Label);
				fclose(ASM);
			}
        }
		TOKEN_RP block else_block 
		{ }
		;
		
		
forstmt:	TOKEN_LOOP id 
		{
			currScope=currScope+" "+"loop";
		} 
		TOKEN_ASSIGNOP_ASSIGN expr 
		{
			if(expType != 'i')
			{
				string message = "start expr in 'for' must be int";
  				yyerror(message.c_str());
			}
		}
		TOKEN_COMMA expr 
		{
         
        	string Rt = Stack.top();
         	Stack.pop();
         	string Rs = Stack.top();
         	Stack.pop();
         
         	if(findVar($2,currScope)==NULL)	
				yyerror(strdup("undefined variable"));
			else if(expType != 'i')
			{
				string message = "end expr in 'for' must be int";
  				yyerror(message.c_str());
			}
			else{
				ASM = fopen("Output.asm", "a+");
				fprintf(ASM,"\taddi %s,$zero,%s\n", (findVar($2,currScope)->reg).c_str(), Rs.c_str());

				Loop++;
				fprintf(ASM,"LOOP%d:\n", Loop);

				string Rd = setRegister('t');
				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd.c_str(), Rt.c_str());
				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rd.c_str(), (findVar($2,currScope)->reg).c_str());
				fprintf(ASM,"\txori %s,%s,1\n", Rd.c_str(), Rd.c_str());
				Label++;
				fprintf(ASM,"\tbeq %s,$zero,L%d\n", Rd.c_str(), Label);

				string Rd2 = setRegister('t');
				fprintf(ASM,"\taddi %s,%s,1\n", Rd2.c_str(), (findVar($2,currScope)->reg).c_str());
				fprintf(ASM,"\tmove %s,%s\n", (findVar($2,currScope)->reg).c_str(), Rd2.c_str());
				freeRegister(Rd2);

				fclose(ASM);
				Stack.push(Rd);
			}
        }
	    block 
		{ 
        	ASM = fopen("Output.asm", "a+");
        	fprintf(ASM,"\tj LOOP%d\n", Loop);
  	    	fprintf(ASM,"L%d:\n", Label);
        	fclose(ASM);
			currScope.erase(currScope.size()-(string("loop").size()+1),string("loop").size()+1);

		}
		;

returnstmt:	TOKEN_RETURN TOKEN_SEMICOLON 
		{ 
			if(findFunc(strdup(here.c_str()))->returnType!='v') 
				yyerror(strdup("wrong return type"));
		}
		| TOKEN_RETURN expr TOKEN_SEMICOLON 
		{ 
			string Rs=Stack.top();
            Stack.pop();
              
			if(findFunc(strdup(here.c_str()))->returnType!=expType) 
				yyerror(strdup("wrong return type"));

            ASM = fopen("Output.asm", "a+");

            if(Rs[0]!='$')
              	fprintf(ASM, "\taddi %s, $zero, %s \n","$v0" , Rs.c_str());
            else{
                fprintf(ASM, "\tmove %s, %s \n","$v0", Rs.c_str());
                
				if(Rs[1] == 't')
                	freeRegister(Rs);
            }
            fclose(ASM);
		}
		;
		
statment:	id assign_op expr TOKEN_SEMICOLON
		{
            struct var* Rt = findVar($1,currScope);
            if(Rt==NULL) 
				yyerror(strdup("undefined variable"));
			else if(Rt->type != expType)
			{
				string message = "operand types is different";
  				yyerror(message.c_str());
			}
			else if(($2 == 'p' || $2 == 'm') && (Rt->type != 'i' || expType != 'i')){
				string message = "operand types for += and -= must be int";
  				yyerror(message.c_str());
			}
			else{
				
				Rt->value = $3;
				string Rs = Stack.top();
				Stack.pop();

				ASM = fopen("Output.asm", "a+");

				if(Rs[0]!='$'){
					if($2 == 'a')
						fprintf(ASM, "\taddi %s, $zero, %s \n", (Rt->reg).c_str(), Rs.c_str());
					else if($2 == 'p')
						fprintf(ASM, "\taddi %s, %s, %s \n", (Rt->reg).c_str(), (Rt->reg).c_str(), Rs.c_str());
					else if($2 == 'm')
						fprintf(ASM, "\taddi %s, %s, %d \n", (Rt->reg).c_str(), (Rt->reg).c_str(), -stoi(Rs));
				}
				else {
					if($2 == 'a')
						fprintf(ASM, "\tmove %s, %s \n", (Rt->reg).c_str(), Rs.c_str());
					else if($2 == 'p')
						fprintf(ASM, "\tadd %s, %s, %s \n", (Rt->reg).c_str(), (Rt->reg).c_str(), Rs.c_str());
					else if($2 == 'm')
						fprintf(ASM, "\tsub %s, %s, %s \n", (Rt->reg).c_str(), (Rt->reg).c_str(), Rs.c_str());
					
					if(Rs[1] == 't')
						freeRegister(Rs);
				}
				fclose(ASM);
			}
        };
		| id TOKEN_LB expr 
		{
			if(expType != 'i')
			{
				string message = "array index expr must be int";
  				yyerror(message.c_str());
			}
		}
		TOKEN_RB assign_op expr TOKEN_SEMICOLON
		{
            struct arr* Rs = findArr($1,currScope);
            if(Rs == NULL){
				string message = "undefined array " + string($1);
  				yyerror(message.c_str());
            }
			else if($3<0 || $3>(Rs->size - 1)){
				string message = "index is out of bound for array " + string($1);
  				yyerror(message.c_str());
			}
			else if(Rs->type != expType)
			{
				string message = "operand types is different";
  				yyerror(message.c_str());
			}
			else if(($6 == 'p' || $6 == 'm') && (Rs->type != 'i' || expType != 'i')){
				string message = "operand types for += and -= must be int";
  				yyerror(message.c_str());
			}
            else{
            	ASM = fopen("Output.asm", "a+");
                
				string vl =Stack.top();
                Stack.pop();
              	string idx = Stack.top();
                Stack.pop();
              	string Rt1 = setRegister('t');
                string Rt2 = setRegister('t');

              	if( vl[0]!='$' && idx[0]!='$'){
					if($6 == 'a')
					{
						fprintf(ASM, "\taddi %s, $zero , %s\n", Rt1.c_str(), vl.c_str());
              			fprintf(ASM, "\tsw %s, %d(%s)\n", Rt1.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );	
					}
					else if($6 == 'p')
					{
						fprintf(ASM, "\tlw %s, %d(%s)\n", Rt1.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );	
						fprintf(ASM, "\taddi %s, %s , %s\n", Rt1.c_str(), Rt1.c_str(), vl.c_str());
              			fprintf(ASM, "\tsw %s, %d(%s)\n", Rt1.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );
					}
					else if($6 == 'm')
					{
						fprintf(ASM, "\tlw %s, %d(%s)\n", Rt1.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );	
						fprintf(ASM, "\taddi %s, %s , %d\n", Rt1.c_str(), Rt1.c_str(), -stoi(vl));
              			fprintf(ASM, "\tsw %s, %d(%s)\n", Rt1.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );
					}
              		
              	}
              	else if(idx[0]!='$' ){
					if($6 == 'a')
					{
	              		fprintf(ASM, "\tsw %s, %d(%s)\n", vl.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );
					}
					else if($6 == 'p')
					{
						fprintf(ASM, "\tlw %s, %d(%s)\n", Rt1.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );	
						fprintf(ASM, "\tadd %s, %s , %s\n", Rt1.c_str(), Rt1.c_str(), vl.c_str());
              			fprintf(ASM, "\tsw %s, %d(%s)\n", Rt1.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );
					}
					else if($6 == 'm')
					{
						fprintf(ASM, "\tlw %s, %d(%s)\n", Rt1.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );	
						fprintf(ASM, "\tsub %s, %s , %s\n", Rt1.c_str(), Rt1.c_str(), vl.c_str());
              			fprintf(ASM, "\tsw %s, %d(%s)\n", Rt1.c_str(), stoi(idx)*4,(findArr($1,currScope)->reg).c_str() );
					}

              	}
              	else if(vl[0]!='$'){
					if($6 == 'a')
					{
	              		fprintf(ASM, "\tsll %s, %s , 2\n", Rt1.c_str(), idx.c_str());
              			fprintf(ASM, "\tadd %s, %s , %s\n", Rt1.c_str(), Rt1.c_str(), (findArr($1,currScope)->reg).c_str() ); //Rt1 = sp + 4 * idx
              			fprintf(ASM, "\taddi %s, $zero , %s\n", Rt2.c_str(), vl.c_str()); // Rt2 = val
              			fprintf(ASM, "\tsw %s, 0(%s)\n", Rt2.c_str(), Rt1.c_str());
					}
					else if($6 == 'p')
					{
						fprintf(ASM, "\tsll %s, %s , 2\n", Rt1.c_str(), idx.c_str());
              			fprintf(ASM, "\tadd %s, %s , %s\n", Rt1.c_str(), Rt1.c_str(), (findArr($1,currScope)->reg).c_str() ); //Rt1 = sp + 4 * idx
						fprintf(ASM, "\tlw %s, 0(%s)\n", Rt2.c_str(), Rt1.c_str() );
						fprintf(ASM, "\taddi %s, %s , %s\n", Rt2.c_str(), Rt2.c_str(), vl.c_str()); // Rt2 = val	
              			fprintf(ASM, "\tsw %s, 0(%s)\n", Rt2.c_str(), Rt1.c_str());
					}
					else if($6 == 'm')
					{
						fprintf(ASM, "\tsll %s, %s , 2\n", Rt1.c_str(), idx.c_str());
              			fprintf(ASM, "\tadd %s, %s , %s\n", Rt1.c_str(), Rt1.c_str(), (findArr($1,currScope)->reg).c_str() ); //Rt1 = sp + 4 * idx
						fprintf(ASM, "\tlw %s, 0(%s)\n", Rt2.c_str(), Rt1.c_str() );
						fprintf(ASM, "\taddi %s, %s , %d\n", Rt2.c_str(), Rt2.c_str(), -stoi(vl)); // Rt2 = val	
              			fprintf(ASM, "\tsw %s, 0(%s)\n", Rt2.c_str(), Rt1.c_str());
					}

              	}
              	else{
					if($6 == 'a')
					{
	              		fprintf(ASM, "\tsll %s, %s , 2\n", Rt1.c_str(), idx.c_str());
              			fprintf(ASM, "\tadd %s, %s , %s\n", Rt1.c_str(), Rt1.c_str(), (findArr($1,currScope)->reg).c_str() ); //Rt1 = sp + 4 * idx
              			fprintf(ASM, "\tsw %s, 0(%s)\n", vl.c_str(), Rt1.c_str());
					}
					else if($6 == 'p')
					{
						fprintf(ASM, "\tsll %s, %s , 2\n", Rt1.c_str(), idx.c_str());
              			fprintf(ASM, "\tadd %s, %s , %s\n", Rt1.c_str(), Rt1.c_str(), (findArr($1,currScope)->reg).c_str() ); //Rt1 = sp + 4 * idx
						fprintf(ASM, "\tlw %s, 0(%s)\n", Rt2.c_str(), Rt1.c_str() );
						fprintf(ASM, "\tadd %s, %s , %s\n", Rt2.c_str(), Rt2.c_str(), vl.c_str()); // Rt2 += val	
              			fprintf(ASM, "\tsw %s, 0(%s)\n", Rt2.c_str(), Rt1.c_str());
					}
					else if($6 == 'm')
					{
						fprintf(ASM, "\tsll %s, %s , 2\n", Rt1.c_str(), idx.c_str());
              			fprintf(ASM, "\tadd %s, %s , %s\n", Rt1.c_str(), Rt1.c_str(), (findArr($1,currScope)->reg).c_str() ); //Rt1 = sp + 4 * idx
						fprintf(ASM, "\tlw %s, 0(%s)\n", Rt2.c_str(), Rt1.c_str() );
						fprintf(ASM, "\tsub %s, %s , %s\n", Rt2.c_str(), Rt2.c_str(), vl.c_str()); // Rt2 = val	
              			fprintf(ASM, "\tsw %s, 0(%s)\n", Rt2.c_str(), Rt1.c_str());
					}
              	}
              	
				freeRegister(Rt1);
              	freeRegister(Rt2);
              	fclose(ASM);
				Rs->value[$3] = $7;
            }
        }
		| method_call TOKEN_SEMICOLON { }
		| ifstmt {}
		| forstmt { }
		| returnstmt { }
		| TOKEN_BREAKSTMT TOKEN_SEMICOLON 
		{
			int sizeScope = currScope.size();
			string r = currScope.substr(sizeScope-4, 4);
			if(r != "loop")	
				yyerror("break isn't in loop");

			ASM = fopen("Output.asm", "a+");
			fprintf(ASM,"\tj L%d\n", Label);
            fclose(ASM);
		}
		| TOKEN_CONTINUESTMT TOKEN_SEMICOLON 
		{
			int sizeScope = currScope.size();
			string r = currScope.substr(sizeScope-4, 4);
			if(r != "loop")	
				yyerror("continue isn't in loop");
			
			ASM = fopen("Output.asm", "a+");
        	fprintf(ASM,"\tj LOOP%d\n", Loop);
            fclose(ASM);
		}
		| block { }
		;		
	
stmt:		stmt statment {}
		| /**/ { }
		;		
		
block:	TOKEN_LCB varDec stmt TOKEN_RCB { }		
		;
		
assign_op:	TOKEN_ASSIGNOP_ASSIGN  { $$ = 'a'; }	
		| TOKEN_ASSIGNOP_ADDITIONASSIGN { $$ = 'p'; }
		| TOKEN_ASSIGNOP_SUBTRACTIONASSIGN {$$ = 'm'; }
		;
		
method_name:	id { }
		;		
		
callout_arg:	expr { }
		| string_literal {}
		;		
		
callout_list:	callout_arg {}
		| callout_list TOKEN_COMMA callout_arg {}
		;		
		
call_argu: 	TOKEN_COMMA callout_list { }
		| /**/	{ }
		;
		
arg_list4:	expr TOKEN_COMMA expr TOKEN_COMMA expr TOKEN_COMMA expr { }
		;		
		
arg_list3:	arg_list4 { }
		| expr TOKEN_COMMA expr TOKEN_COMMA expr { }		
		;
		
arg_list2:	arg_list3 { }
		| expr TOKEN_COMMA expr { }
		;
		
arg_list1:	arg_list2  { }
		| expr  { }
		;

arg_list:	arg_list1 { }
		| /**/ { }
		;		
		
method_call:	method_name TOKEN_LP arg_list TOKEN_RP { }
		| TOKEN_CALLOUT TOKEN_LP string_literal call_argu TOKEN_RP { }
		;
			
location:	id 
		{
			
			struct var* Rs = findVar($1,currScope);
        	if(Rs == NULL)
			{
				yyerror(("undefined variable "+string($1)).c_str());
			}
			$$ = Rs->value;
			//Stack.push(to_string($$));
			Stack.push(Rs->reg);
        	expType=Rs->type;
			
		}
		| id TOKEN_LB expr TOKEN_RB 
		{
  			string Rs = Stack.top();
        	Stack.pop();
        	string Rd = setRegister('t');
        	struct arr* Rt = findArr($1,currScope);
        	
			if(Rt == NULL){
  				string message = "undefined array " + string($1);
  				yyerror(message.c_str());
  			}
			else if(expType != 'i')
			{
				string message = "array index expr must be int";
  				yyerror(message.c_str());
			}
			else if($3<0 || $3>(Rt->size - 1)){
				string message = "index is out of bound for array " + string($1);
  				yyerror(message.c_str());
			}
  			else{
  				ASM = fopen("Output.asm", "a+");
  				if(Rs[0]!='$')
  					fprintf(ASM,"\tlw %s,%d(%s)\n", Rd.c_str(), stoi(Rs)*4, (Rt->reg).c_str());
  				else{
  					fprintf(ASM,"\tsll %s,%s,2\n", Rd.c_str(), Rs.c_str());
  					fprintf(ASM,"\tadd %s,%s,%s\n", Rd.c_str(), Rd.c_str(), (Rt->reg).c_str());
  					fprintf(ASM,"\tlw %s,0(%s)\n", Rd.c_str(), Rd.c_str());
  				}
          		fclose(ASM);
    			Stack.push(Rd);
				$$ = Rt->value[$3];
				expType = Rt->type;
  			}
		}
		;
		
expr:	location 
		{ 
			($$) = $1;
		}
		| method_call 
		{ 
			($$) = $1;
        	Stack.push(to_string($1));
		}
		| literal 
		{ 
			($$) = $1;
			Stack.push(to_string($1));

		}
		| term 
		{ 
			($$) = $1;
		}
		| expr TOKEN_ARITHMATICOP_PLUS 
		{
			if(expType != 'i')
			{
				string message = "PLUS operand must be int";
  				yyerror(message.c_str());
			}
		}
		expr 
		{ 
			if(expType != 'i')
			{
				string message = "PLUS operand must be int";
  				yyerror(message.c_str());
			}

			ASM = fopen("Output.asm", "a+");
			($$)= $1 + $4;
			string Rt = Stack.top();
				Stack.pop();
			
			string Rs = Stack.top();
			Stack.pop();

			string Rd = setRegister('t');
			if(Rs[0]!='$' && Rt[0]!='$')
				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)+stoi(Rt));
			else if(Rs[0]!='$')
				fprintf(ASM,"\taddi %s,%s,%s\n", Rd.c_str(), Rt.c_str(), Rs.c_str());
			else if(Rt[0]!='$')
				fprintf(ASM,"\taddi %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rt.c_str());
			else
				fprintf(ASM,"\tadd %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rt.c_str());
					
				Stack.push(Rd);
				
				if(Rs[1] == 't')
				freeRegister(Rs);
			if(Rt[1] == 't')
				freeRegister(Rt);
			fclose(ASM);
		}
		| expr TOKEN_ARITHMATICOP_MINUS 
		{
			if(expType != 'i')
			{
				string message = "MINUS operand must be int";
  				yyerror(message.c_str());
			}
		}
		expr 
		{ 
			if(expType != 'i')
			{
				string message = "MINUS operand must be int";
  				yyerror(message.c_str());
			}

		    ASM = fopen("Output.asm", "a+");
        	    ($$) = $1 - $4;
  		    string Rt = Stack.top();
        	    Stack.pop();
  		    string Rs = Stack.top();
           	Stack.pop();
            string Rd = setRegister('t');
  		    
			if(Rs[0]!='$' && Rt[0]!='$')
  			fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)-stoi(Rt));
  		    else if(Rs[0]!='$'){
          		fprintf(ASM,"\tsub %s,$zero,%s", Rd.c_str(),Rt.c_str());
          		fprintf(ASM,"\taddi %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rs.c_str());
        		}
        	    else if(Rt[0]!='$')
          		fprintf(ASM,"\taddi %s,%s,-%s\n", Rd.c_str(), Rs.c_str(), Rt.c_str());
  		    else
          		fprintf(ASM,"\tsub %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rt.c_str());
          		
        	Stack.push(Rd);
        	    
        	if(Rs[1] == 't')
  				freeRegister(Rs);
  		    if(Rt[1] == 't')
  				freeRegister(Rt);
  		    fclose(ASM);
  			
		}	
		| expr TOKEN_ARITHMATICOP_MULT 
		{
			if(expType != 'i')
			{
				string message = "MULT operand must be int";
  				yyerror(message.c_str());
			}
		}
		expr 
		{
			if(expType != 'i')
			{
				string message = "MULT operand must be int";
  				yyerror(message.c_str());
			}

		    ASM = fopen("Output.asm", "a+");
        	    ($$) = $1 * $4;
  		    string Rt = Stack.top();
        	    Stack.pop();
  		    string Rs = Stack.top();
        	    Stack.pop();
        	    string Rd = setRegister('t');
  		    if(Rs[0]!='$' && Rt[0]!='$')
  			fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)*stoi(Rt));
  		    else if(Rs[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s", Rd.c_str(),Rs.c_str());
          		fprintf(ASM,"\tmul %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rt.c_str());
		        }
       	    else if(Rt[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s", Rd.c_str(),Rt.c_str());
          		fprintf(ASM,"\tmul %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rd.c_str());
        	}
  		    else
          		fprintf(ASM,"\tmul %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rt.c_str());
          		
        	Stack.push(Rd);
        	    
        	if(Rs[1] == 't')
  				freeRegister(Rs);
  		    if(Rt[1] == 't')
  				freeRegister(Rt);
  		    fclose(ASM);
  			
		}	
		| expr TOKEN_ARITHMATICOP_DIVISION 
		{
			if(expType != 'i')
			{
				string message = "DIVISION operand must be int";
  				yyerror(message.c_str());
			}
		}
		expr 
		{
			if(expType != 'i')
			{
				string message = "DIVISION operand must be int";
  				yyerror(message.c_str());
			}

		    ASM = fopen("Output.asm", "a+");
        	($$)= $1 / $4;
  		    string Rt = Stack.top();
        	Stack.pop();
  		    string Rs = Stack.top();
        	Stack.pop();
        	string Rd = setRegister('t');
        	    
        	if($4==0)
        	    cout<<"divide by zero" << endl;
  		    if(Rs[0]!='$' && Rt[0]!='$')
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)/stoi(Rt));
  		    else if(Rs[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s", Rd.c_str(),Rs.c_str());
          		fprintf(ASM,"\tdiv %s,%s\n", Rd.c_str(), Rt.c_str());
				fprintf(ASM,"\tmflo %s\n", Rd.c_str());
        	}
        	else if(Rt[0]!='$'){
		        fprintf(ASM,"\taddi %s,$zero,%s", Rd.c_str(),Rt.c_str());
          		fprintf(ASM,"\tdiv %s,%s\n", Rs.c_str(), Rd.c_str());
				fprintf(ASM,"\tmflo %s\n", Rd.c_str());
        	}
  		    else{
          		fprintf(ASM,"\tdiv %s,%s\n", Rs.c_str(), Rt.c_str());
				fprintf(ASM,"\tmflo %s\n", Rd.c_str());
			}
        	Stack.push(Rd);
        	    
        	if(Rs[1] == 't')
  				freeRegister(Rs);
  		    if(Rt[1] == 't')
  				freeRegister(Rt);
  		    fclose(ASM);
  		    
		}
		| expr TOKEN_ARITHMATICOP_REMAIN 
		{
			if(expType != 'i')
			{
				string message = "REMAIN operand must be int";
  				yyerror(message.c_str());
			}
		}
		expr 
		{ 
			if(expType != 'i')
			{
				string message = "REMAIN operand must be int";
  				yyerror(message.c_str());
			}

		    ASM = fopen("Output.asm", "a+");
        	($$)= $1 % $4;
  		    string Rt = Stack.top();
        	Stack.pop();
  		    string Rs = Stack.top();
        	Stack.pop();
        	string Rd = setRegister('t');
        	    
        	if($4==0)
        	    cout << "divide by zero" << endl;
  		    if(Rs[0]!='$' && Rt[0]!='$')
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)%stoi(Rt));
  		    else if(Rs[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s", Rd.c_str(),Rs.c_str());
          		fprintf(ASM,"\tdiv %s,%s\n", Rd.c_str(), Rt.c_str());
				fprintf(ASM,"\tmfhi %s\n", Rd.c_str());
        	}
        	else if(Rt[0]!='$'){
		        fprintf(ASM,"\taddi %s,$zero,%s", Rd.c_str(),Rt.c_str());
          		fprintf(ASM,"\tdiv %s,%s\n", Rs.c_str(), Rd.c_str());
				fprintf(ASM,"\tmfhi %s\n", Rd.c_str());
        	}
  		    else{
          		fprintf(ASM,"\tdiv %s,%s\n", Rs.c_str(), Rt.c_str());
				fprintf(ASM,"\tmfhi %s\n", Rd.c_str());
			}
        	Stack.push(Rd);
        	    
        	if(Rs[1] == 't')
  				freeRegister(Rs);
  		    if(Rt[1] == 't')
  				freeRegister(Rt);
  		    fclose(ASM);
		}	
		| expr TOKEN_RELATIONOP_SEQ 
		{
			if(expType != 'i')
			{
				string message = "Relational operand must be int";
  				yyerror(message.c_str());
			}
		}
		expr 
		{ 
			if(expType != 'i')
			{
				string message = "Relational operand must be int";
  				yyerror(message.c_str());
			}

			ASM = fopen("Output.asm", "a+");
        	($$) = $1<=$4 ? 1 : 0;
  			string Rt = Stack.top();
        	Stack.pop();
  			string Rs = Stack.top();
       		Stack.pop();
        	string Rd = setRegister('t');
			string Rd2 = setRegister('t');
			string Rd3 = setRegister('t');


			if(Rs[0]!='$' && Rt[0]!='$'){
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)<=stoi(Rt));
			}
  			else if(Rs[0]!='$'){
  				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd3.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rd3.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rt.c_str(), Rd3.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd2.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  			}
  			else if(Rt[0]!='$'){
  				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd3.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rd3.c_str());
				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rd3.c_str(), Rs.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd2.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  			}
			else{
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rt.c_str());
				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rt.c_str(), Rs.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd2.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
			}

  			fclose(ASM);
  			Stack.push(Rd);
			freeRegister(Rd2);
			freeRegister(Rd3);
		}
		| expr TOKEN_RELATIONOP_LEQ 
		{
			if(expType != 'i')
			{
				string message = "Relational operand must be int";
  				yyerror(message.c_str());
			}
		}
		expr
		{ 
			if(expType != 'i')
			{
				string message = "Relational operand must be int";
  				yyerror(message.c_str());
			}

			ASM = fopen("Output.asm", "a+");
        	($$) = $1>=$4 ? 1 : 0;
  			string Rt = Stack.top();
        	Stack.pop();
  			string Rs = Stack.top();
       		Stack.pop();
        	string Rd = setRegister('t');
			string Rd2 = setRegister('t');
			string Rd3 = setRegister('t');


			if(Rs[0]!='$' && Rt[0]!='$'){
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)>=stoi(Rt));
			}
  			else if(Rs[0]!='$'){
  				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd3.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rd3.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rt.c_str(), Rd3.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  			}
  			else if(Rt[0]!='$'){
  				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd3.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rd3.c_str());
				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rd3.c_str(), Rs.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  			}
			else{
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rt.c_str());
				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rt.c_str(), Rs.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
			}

  			fclose(ASM);
			freeRegister(Rd2);
			freeRegister(Rd3);
  			Stack.push(Rd);
		}	
		| expr TOKEN_RELATIONOP_S 
		{
			if(expType != 'i')
			{
				string message = "Relational operand must be int";
  				yyerror(message.c_str());
			}
		}
		expr 
		{ 
			if(expType != 'i')
			{
				string message = "Relational operand must be int";
  				yyerror(message.c_str());
			}
		
        	ASM = fopen("Output.asm", "a+");
        	($$) = $1<$4 ? 1 : 0;
  			string Rt = Stack.top();
        	Stack.pop();
  			string Rs = Stack.top();
        	Stack.pop();
        	string Rd = setRegister('t');
  			if(Rs[0]!='$' && Rt[0]!='$')
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)<stoi(Rt));
  			else if(Rs[0]!='$'){
  				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rt.c_str());
  			}
  			else if(Rt[0]!='$'){
  				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rd.c_str());
			}
  			else
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rs.c_str(), Rt.c_str());
  			fclose(ASM);
  			Stack.push(Rd);
		}	
		| expr TOKEN_RELATIONOP_L 
		{
			if(expType != 'i')
			{
				string message = "Relational operand must be int";
  				yyerror(message.c_str());
			}
		}
		expr 
		{ 
			if(expType != 'i')
			{
				string message = "Relational operand must be int";
  				yyerror(message.c_str());
			}

			ASM = fopen("Output.asm", "a+");
        	($$) = $1>$4 ? 1 : 0;
  			string Rt = Stack.top();
        	Stack.pop();
  			string Rs = Stack.top();
        	Stack.pop();
        	string Rd = setRegister('t');
  			if(Rs[0]!='$' && Rt[0]!='$')
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)>stoi(Rt));
  			else if(Rs[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s\n", Rd.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rt.c_str(), Rd.c_str());
        	}
			else if(Rt[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s\n", Rd.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rs.c_str());
        	}
  			else
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd.c_str(), Rt.c_str(), Rs.c_str());
  			fclose(ASM);
  			Stack.push(Rd);
		}	
		| expr TOKEN_EQUALITYOP_EQ 
		{
			expType2 = expType;
		}
		expr 
		{ 
			if(expType != expType2)
			{
				string message = "EQUAL operand must be same";
  				yyerror(message.c_str());
			}
			ASM = fopen("Output.asm", "a+");
        	($$) = $1==$4 ? 1 : 0;
  			string Rt = Stack.top();
        	Stack.pop();
  			string Rs = Stack.top();
        	Stack.pop();
        	string Rd1 = setRegister('t');
        	string Rd2 = setRegister('t');
  			
			if(Rs[0]!='$' && Rt[0]!='$')
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd1.c_str(),stoi(Rs)==stoi(Rt));
  			else if(Rs[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s\n", Rd1.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd1.c_str(), Rd1.c_str(), Rt.c_str());
          		fprintf(ASM,"\tslti %s,%s,%s\n", Rd2.c_str(), Rt.c_str(), Rs.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd1.c_str(), Rd1.c_str(), Rd2.c_str());
        	}
        	else if(Rt[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s\n", Rd1.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd1.c_str(), Rd1.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslti %s,%s,%s\n", Rd2.c_str(), Rs.c_str(), Rt.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd1.c_str(), Rd1.c_str(), Rd2.c_str());
        	}
  			else{
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd1.c_str(), Rs.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rt.c_str(), Rs.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd1.c_str(), Rd1.c_str(), Rd2.c_str());
  			}

  			Stack.push(Rd1);
	        freeRegister(Rd2);
    	    if(Rs[1] == 't')
  				freeRegister(Rs);
  			if(Rt[1] == 't')
  				freeRegister(Rt);
  			fclose(ASM);
		}
		| expr TOKEN_EQUALITYOP_NOTEQ 
		{
			expType2 = expType;
		}
		expr 
		{ 
			if(expType != expType2)
			{
				string message = "NOT EQUAL operand must be same";
  				yyerror(message.c_str());
			}
			ASM = fopen("Output.asm", "a+");
        	($$) = $1!=$4 ? 1 : 0;
  			string Rt = Stack.top();
        	Stack.pop();
  			string Rs = Stack.top();
        	Stack.pop();
        	string Rd = setRegister('t');
	        string Rd2 = setRegister('t');
			string Rd3 = setRegister('t');

  			if(Rs[0]!='$' && Rt[0]!='$')
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)!=stoi(Rt));
  			else if(Rs[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s\n", Rd.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rd.c_str(), Rt.c_str());
          		fprintf(ASM,"\tslt %s,%s,%s\n", Rd3.c_str(), Rt.c_str(), Rd.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd3.c_str(), Rd2.c_str());
        	}
        	else if(Rt[0]!='$'){
          		fprintf(ASM,"\taddi %s,$zero,%s\n", Rd.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rd.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd3.c_str(), Rs.c_str(), Rd.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd3.c_str(), Rd2.c_str());
        	}
  			else{
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd3.c_str(), Rs.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,%s\n", Rd2.c_str(), Rt.c_str(), Rs.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd3.c_str(), Rd2.c_str());
  			}

  			Stack.push(Rd);

        	freeRegister(Rd2);
			freeRegister(Rd3);

        	if(Rs[1] == 't')
  				freeRegister(Rs);
  			if(Rt[1] == 't')
  				freeRegister(Rt);
  			fclose(ASM);
		}
		| expr TOKEN_CONDITIONOP_AND 
		{
			if(expType != 'b')
			{
				string message = "AND operand must be boolean";
  				yyerror(message.c_str());
			}
		}
		expr 
		{ 
			if(expType != 'b')
			{
				string message = "AND operand must be boolean";
  				yyerror(message.c_str());
			}

			ASM = fopen("Output.asm", "a+");
        	($$) = $1 && $4 ? 1 : 0;
  			string Rt = Stack.top();
        	Stack.pop();
  			string Rs = Stack.top();
        	Stack.pop();
        	string Rd = setRegister('t');
        	string Rd2 = setRegister('t');
        	string Rd3 = setRegister('t');
  			
			if(Rs[0]!='$' && Rt[0]!='$')
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)&&stoi(Rt));
  			else if(Rs[0]!='$'){
				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd3.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd.c_str(), Rd3.c_str());
          		fprintf(ASM,"\tslt %s,$zero,%s\n", Rd2.c_str(), Rd3.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				Label++;
  				fprintf(ASM,"\tbeq %s,$zero, L%d\n", Rd.c_str(), Label);
  				fprintf(ASM,"\tslt %s,$zero, %s\n", Rd3.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rt.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd3.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tL%d:\n", Label);
        	}
        	else if(Rt[0]!='$'){
          		fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rs.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				Label++;
  				fprintf(ASM,"\tbeq %s,$zero,L%d\n", Rd.c_str(), Label);
  				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd3.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rd3.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rd3.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tL%d:\n",Label);
    	    }
  			else{
        		fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero \n", Rd2.c_str(), Rs.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd2.c_str(), Rd.c_str());
  				Label++;
  				fprintf(ASM,"\tbeq %s,$zero,L%d\n", Rd.c_str(), Label);
  				fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rt.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tL%d:\n", Label);
        	}

			Stack.push(Rd);

	        freeRegister(Rd2);
    	    freeRegister(Rd3);
        	if(Rs[1] == 't')
  					freeRegister(Rs);
  			if(Rt[1] == 't')
  					freeRegister(Rt);
  			fclose(ASM);
		}
		| expr TOKEN_CONDITIONOP_OR 
		{
			if(expType != 'b')
			{
				string message = "OR operand must be boolean";
  				yyerror(message.c_str());
			}
		}
		expr 
		{ 
			if(expType != 'b')
			{
				string message = "OR operand must be boolean";
  				yyerror(message.c_str());
			}
			
			ASM = fopen("Output.asm", "a+");
        	($$) = $1 || $4 ?1:0;
  			string Rt = Stack.top();
        	Stack.pop();
  			string Rs = Stack.top();
        	Stack.pop();
        	string Rd = setRegister('t');
        	string Rd2 = setRegister('t');
        	string Rd3 = setRegister('t');

  			if(Rs[0]!='$' && Rt[0]!='$')
  				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(),stoi(Rs)||stoi(Rt));
  			else if(Rs[0]!='$'){
  				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd3.c_str(), Rs.c_str());
          		fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rd3.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rd3.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				Label++;
  				fprintf(ASM,"\tbeq %s,$zero, L%d\n", Rd.c_str(), Label);
  				fprintf(ASM,"\tslt %s,$zero %s\n", Rd.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rt.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tL%d:\n", Label);
        	}
        	else if(Rt[0]!='$'){
          		fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rs.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				Label++;
  				fprintf(ASM,"\tbeq %s,$zero,L%d\n", Rd.c_str(), Label);
  				fprintf(ASM,"\taddi %s,$zero,%s\n", Rd3.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rd3.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rd3.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tL%d:\n",Label);
        	}
  			else{
          		fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero \n", Rd2.c_str(), Rs.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				Label++;
  				fprintf(ASM,"\tbeq %s,$zero,L%d\n",  Rd.c_str(), Label);
  				fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rt.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rt.c_str());
  				fprintf(ASM,"\tor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());
  				fprintf(ASM,"\tL%d:\n", Label);
			}
			Stack.push(Rd);

			freeRegister(Rd2);
			freeRegister(Rd3);
			if(Rs[1] == 't')
				freeRegister(Rs);
			if(Rt[1] == 't')
				freeRegister(Rt);
			fclose(ASM);
		}
		;

term:	TOKEN_LP expr TOKEN_RP 
		{ 
			$$ = $2;
    		Stack.push(to_string($2));
		}
		| TOKEN_LOGICOP expr 
		{ 
			if(expType != 'b')
			{
				string message = "LOGIC NOT operand must be boolean";
  				yyerror(message.c_str());
			}

			($$) = !$2;
  			string Rs = Stack.top();
        	Stack.pop();
			string Rd = setRegister('t');
          	string Rd2 = setRegister('t');
  			ASM = fopen("Output.asm", "a+");
        	
			if(Rs[0]!='$'){
  				if( Rs[0] == '0')
					fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(), 1);
  				else
  					fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(), 0);
        	}
        	else{
          		
  				fprintf(ASM,"\tslt %s,$zero,%s\n", Rd.c_str(), Rs.c_str());
  				fprintf(ASM,"\tslt %s,%s,$zero\n", Rd2.c_str(), Rs.c_str());
  				fprintf(ASM,"\tnor %s,%s,%s\n", Rd.c_str(), Rd.c_str(), Rd2.c_str());  				
  			}

    		Stack.push(Rd);

			freeRegister(Rd2);
  			if(Rs[1] == 't')
  				freeRegister(Rs);
         	fclose(ASM);
		}
		| '-' expr %prec UMINUS 
		{ 
			if(expType != 'i')
			{
				string message = "'- expr' operand must be int";
  				yyerror(message.c_str());
			}

			($$) = -$2;
  			string Rs = Stack.top();
        	Stack.pop();
			string Rd = setRegister('t');
  			ASM = fopen("Output.asm", "a+");
        	if(Rs[0]!='$')
				fprintf(ASM,"\taddi %s,$zero,%d\n", Rd.c_str(), -$2);
  			else{
  				fprintf(ASM,"\tsub %s,$zero,%s\n", Rd.c_str(), Rs.c_str());
  			}
    		Stack.push(Rd);
          	fclose(ASM);
		}
		;

literal: int_literal 
		{ 
			($$) = $1;
			expType = 'i';
		}
		| char_literal 
		{ 
			($$) = $1;
			expType = 'c';
		}
		| bool_literal 
		{ 
			($$) = $1;
			expType = 'b';
		}
		;
		
id:		TOKEN_ID 
		{ 
			$$ = $1;
		}
		;
		
int_literal:	decimal_literal { $$ = $1;}
		| hex_literal { $$ = $1;}
		;
		
decimal_literal: TOKEN_DECIMALCONST { $$ = $1;}
		;
		
hex_literal:	TOKEN_HEXADECIMALCONST { $$=$1; }
		;		
		
bool_literal:	TOKEN_BOOLEANCONST { $$= $1;}
		;
		
char_literal:	TOKEN_CHARCONST { $$ = $1;}
		;
		
string_literal: TOKEN_STRINGCONST { /*$$ = $1;*/}
		;
								
%%



int main(int argc, char *argv[])
{
	yyin = fopen(argv[1], "r");
	if(yyin == 0){
		cout << argv[1] << " file not exist" << endl;
		return 0;
	}



//cout<<"ok1"<< endl;
	yyparse();
//cout<<"ok2"<< endl;

	if(Error){
//		cout<<"error"<< endl;

		fclose(ASM);
		remove("Output.asm");
//		cout<<"error2"<< endl;

		return 0;
	}
	//cout<<"ok3"<< endl;

	return 0;
}

int yyerror(const char* message){
	cout<<"Error " << message << endl;
	remove("Output.asm");
  	Error++;
	return 0;
}

void addVar(char *varName, string scope, string reg,char type, int value){
  struct var *ns=new var();
  ns->varName=varName;
  ns->scope=scope;
  ns->reg=reg;
  ns->type=type;
  ns->value = value;
  variables.push_back(ns);
}

struct var* findVar(char* varName,string scope){
	for(int i=0;i<variables.size();i++)
	{
		if (strcmp(varName,variables[i]->varName)==0&&scope==variables[i]->scope){
		return variables[i];
		}
	}
	int m=scope.find_last_of(" ");
	while(m!=-1){
		string newscope=scope.substr(0,m);
		for(int i=0;i<variables.size();i++)
		{
		if (strcmp(varName,variables[i]->varName)==0&&newscope==variables[i]->scope){
			return variables[i];
		}
		}
		m=newscope.find_last_of(" ");
	}
	return NULL;
}

void addArr(char *arrName, string scope, string reg,char type, int size){
	struct arr *ns = new arr();
  	ns->arrName = arrName;
  	ns->scope = scope;
  	ns->reg = reg;
  	ns->type = type;
  	ns->size = size;

	ns->value = new int(size);
	for(int i=0; i<size; i++)
		ns->value[i] = 0;
  	arrays.push_back(ns);
}
struct arr* findArr(char* arrName,string scope){
	for(int i=0;i<arrays.size();i++)
	{
		if (strcmp(arrName,arrays[i]->arrName) == 0 && scope == arrays[i]->scope){
			return arrays[i];
		}
	}

	int m = scope.find_last_of(" ");
	while(m != -1){
		string newscope = scope.substr(0,m);
		for(int i=0;i<arrays.size();i++)
		{
			if (strcmp(arrName,arrays[i]->arrName) == 0 && newscope == arrays[i]->scope){
				return arrays[i];
			}
		}
		m = newscope.find_last_of(" ");
	}
	return NULL;
}

struct function* findFunc(char* funcName){
  for(int i=0;i<functions.size();i++)
    if(strcmp(funcName,functions[i]->funcName)==0)
      return functions[i];
  return NULL;
}

void addFunc(char* funcName,char returnType,int argsNum){
  struct function* nf=new function();
  nf->returnType=returnType;
  nf->funcName=funcName;
  nf->argsNum=argsNum;
  functions.push_back(nf);
}

string setRegister(char registerType){
  // registerType : 't','s','a'
  switch(registerType){
		case 't':
				for(int i=0; i<=9; i++)
					if(t_registers_state[i] == 0)
						{t_registers_state[i] = 1;return "$t"+to_string(i);}
				break;
		case 's':
				for(int i=0; i<=7; i++)
					if(s_registers_state[i] == 0)
						{s_registers_state[i] = 1;return "$s"+to_string(i);}
				break;
		case 'a':
				for(int i=0; i<=3; i++)
					if(a_registers_state[i] == 0)
						{a_registers_state[i] = 1;return "$a"+to_string(i);}
				break;
	}
  return "$";
}

void freeRegister(string registerName){
  // reg ~ '$t0'
	
  switch(registerName[1]){
		case 't':
			t_registers_state[registerName[2]-'0'] = 0;
			break;
		case 's':
			s_registers_state[registerName[2]-'0'] = 0;
			break;
		case 'a':
			a_registers_state[registerName[2]-'0'] = 0;
			break;
	}
}

