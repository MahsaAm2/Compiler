%{
  #include<stdio.h>
  #include<string.h>
  #include "p.tab.h"
  
  int compare_neg();
  int compare_pos();
  long long int num;
%}


%option noyywrap

%%

    /*chars*/
\'[\x20\x21\x23-\x26\x28-\x5b\x5d-\x7e]\' { yylval.charVal = yytext[0]; return TOKEN_CHARCONST; };
"\'\\\'\'"|"\'\\\\\'"|"\'\\\"\'"|"\'\\n\'"|"\'\\t\'" { yylval.charVal = yytext[0]; return TOKEN_CHARCONST; };

    /*bug: char*/ 
\'['"\\]\' { printf("error in line  : wrong char\n"); };
\'[^'\n][^'\n][^'\n]*\' { printf("error in line  : wrong char\n"); };
\' { printf("error in line  : char without closing\n"); };

  /*keywords*/
boolean { yylval.strVal = strdup(yytext); return TOKEN_BOOLEANTYPE; };
break { yylval.strVal = strdup(yytext); return TOKEN_BREAKSTMT; };
callout { yylval.strVal = strdup(yytext); return TOKEN_CALLOUT; };
class { yylval.strVal = strdup(yytext); return TOKEN_CLASS; };
continue { yylval.strVal = strdup(yytext); return TOKEN_CONTINUESTMT; };
else { yylval.strVal = strdup(yytext); return TOKEN_ELSECONDITION; };
false { yylval.boolVal = false; return TOKEN_BOOLEANCONST; };
for { yylval.strVal = strdup(yytext); return TOKEN_LOOP; };
if { yylval.strVal = strdup(yytext); return TOKEN_IFCONDITION; };
int { yylval.strVal = strdup(yytext); return TOKEN_INTTYPE; };
return { yylval.strVal = strdup(yytext); return TOKEN_RETURN; };
true { yylval.boolVal = true; return TOKEN_BOOLEANCONST; };
void { yylval.strVal = strdup(yytext); return TOKEN_VOIDTYPE; };
Program { yylval.strVal = strdup(yytext); return TOKEN_PROGRAMCLASS; };
main { yylval.strVal = strdup(yytext); return TOKEN_MAINFUNC; };

    /*bug: wrong hex number*/
[0][xX][a-zA-Z0-9]*[g-zG-Z][a-zA-Z0-9]* { printf("error: wrong hex number -> Unauthorized letters have been used\n"); };


    /*identifiers*/
[a-zA-Z_][a-zA-Z0-9_]* { yylval.strVal = strdup(yytext); return TOKEN_ID; };

    /*comments*/
\/\/(.*)\n { /*yylval.strVal = strdup(yytext); return TOKEN_COMMENT;*/ };

    /*strings*/
\"([^"\n]*)\" { yylval.strVal = strdup(yytext); return TOKEN_STRINGCONST; };
\"([^"\n]*)\\\"([^"\n]*)\" { yylval.strVal = strdup(yytext); return TOKEN_STRINGCONST; };

    /*bug: string*/
\" { printf("error in line  : string without closing\n"); };

    /*whitespaces*/
[ ] { /*return TOKEN_WHITESPACE; */};
[\t] { /*return TOKEN_WHITESPACE; */};
[\n] { /*return TOKEN_WHITESPACE; */};

    /*bug: id*/
[0-9]+[a-zA-Z_]+ { printf("error in line  : wrong id definition\n"); };

    /*numbers*/
[-][0-9]+ { if(strlen(yytext) > 11)
	    {
		printf("The number is out of range\n");
		//return;
	    }
	    else{
	        num = atof(yytext);
	        if(num < -2147483648)
		    printf("The number is out of range\n");
	        else{
		    yylval.numVal = atoi(yytext);
		    return TOKEN_DECIMALCONST;
	        }
	    }
    	  };
[0-9]+ {   if(strlen(yytext) > 10)
	    {
		printf("The number is out of range\n");
		//return;
	    }
	    else{
	       num = atof(yytext);
	       if(num > 2147483647)
		    printf("The number is out of range\n");
	       else{
		    yylval.numVal = atoi(yytext);
		    return TOKEN_DECIMALCONST;
	       } 
	    }
	};
[0][xX][0-9a-fA-F]+ { yylval.numVal = atoi(yytext); return TOKEN_HEXADECIMALCONST; };




    /*operators*/
[+] { yylval.strVal = strdup(yytext); return TOKEN_ARITHMATICOP_PLUS; };
[-] { yylval.strVal = strdup(yytext); return TOKEN_ARITHMATICOP_MINUS; };
[*] { yylval.strVal = strdup(yytext); return TOKEN_ARITHMATICOP_MULT; };
[/] { yylval.strVal = strdup(yytext); return TOKEN_ARITHMATICOP_DIVISION; };
[%] { yylval.strVal = strdup(yytext); return TOKEN_ARITHMATICOP_REMAIN; };
[&][&] { yylval.strVal = strdup(yytext); return TOKEN_CONDITIONOP_AND; };
[|][|] { yylval.strVal = strdup(yytext); return TOKEN_CONDITIONOP_OR; };
[<][=] { yylval.strVal = strdup(yytext); return TOKEN_RELATIONOP_SEQ; };
[<] { yylval.strVal = strdup(yytext); return TOKEN_RELATIONOP_S; };
[>] { yylval.strVal = strdup(yytext); return TOKEN_RELATIONOP_L; };
[>][=] { yylval.strVal = strdup(yytext); return TOKEN_RELATIONOP_LEQ; };
[!][=] { yylval.strVal = strdup(yytext); return TOKEN_EQUALITYOP_NOTEQ; };
[=][=] { yylval.strVal = strdup(yytext); return TOKEN_EQUALITYOP_EQ; };
[=] { yylval.strVal = strdup(yytext); return TOKEN_ASSIGNOP_ASSIGN; };
[+][=] { yylval.strVal = strdup(yytext); return TOKEN_ASSIGNOP_ADDITIONASSIGN; };
[-][=] { yylval.strVal = strdup(yytext); return TOKEN_ASSIGNOP_SUBTRACTIONASSIGN; };
[!] { yylval.strVal = strdup(yytext); return TOKEN_LOGICOP; };
[(] { yylval.strVal = strdup(yytext); return TOKEN_LP; };
[)] { yylval.strVal = strdup(yytext); return TOKEN_RP; };
[{] { yylval.strVal = strdup(yytext); return TOKEN_LCB; };
[}] { yylval.strVal = strdup(yytext); return TOKEN_RCB; };
\[ { yylval.strVal = strdup(yytext); return TOKEN_LB; };
\] { yylval.strVal = strdup(yytext); return TOKEN_RB; };
[;] { yylval.strVal = strdup(yytext); return TOKEN_SEMICOLON; };
[,] { yylval.strVal = strdup(yytext); return TOKEN_COMMA; };

    /*bug: others*/
. { printf("bad character %s\n", yytext); };
%%



/*
int compare_pos()
{
    if(strlen(yytext) > 10)
    {
        printf("The number is out of range\n");
        return;
    }
    num = atof(yytext);
    if(num > 2147483647)
	printf("The number is out of range\n");
    else{
        yylval.numVal = atoi(yytext);
	return TOKEN_DECIMALCONST;
    }
}


int compare_neg()
{
    if(strlen(yytext) > 11)
    {
        printf("The number is out of range\n");
        return;
    }
    num = atof(yytext);
    if(num < -2147483648)
        printf("The number is out of range\n");
    else{
        yylval.numVal = atoi(yytext);
        return TOKEN_DECIMALCONST;
    }
}*/
/*
int yywrap(){}

int main()
{
  yyin=fopen("test.cpp","r");
  //yyout=fopen("output.cpp","w");
  yylex();
  return 0;
}
*/
