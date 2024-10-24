%{
  #include<stdio.h>
  long long int num;
%}




%%

    /*chars*/
\'[\x20\x21\x23-\x26\x28-\x5b\x5d-\x7e]\' { printf("TOKEN_CHARCONST %s\n", yytext); };
"\'\\\'\'"|"\'\\\\\'"|"\'\\\"\'"|"\'\\n\'"|"\'\\t\'" { printf("TOKEN_CHARCONST %s\n", yytext); };

    /*bug: char*/ 
\'['"\\]\' { printf("error in line  : wrong char\n"); };
\'[^'\n][^'\n][^'\n]*\' { printf("error in line  : wrong char\n"); };
\' { printf("error in line  : char without closing\n"); };

  /*keywords*/
boolean { printf("TOKEN_BOOLEANTYPE boolean\n"); };
break { printf("TOKEN_BREAKSTMT break\n"); };
callout { printf("TOKEN_CALLOUT callout\n"); };
class { printf("TOKEN_CLASS calss\n"); };
continue { printf("TOKEN_CONTINUESTMT continue\n"); };
else { printf("TOKEN_ELSECONDITION else\n"); };
false { printf("TOKEN_BOOLEANCONST false\n"); };
for { printf("TOKEN_LOOP for\n"); };
if { printf("TOKEN_IFCONDITION if\n"); };
int { printf("TOKEN_INTTYPE int\n"); };
return { printf("TOKEN_RETURN return\n"); };
true { printf("TOKEN_BOOLEANCONST true\n"); };
void { printf("TOKEN_VOIDTYPE void\n"); };
Program { printf("TOKEN_PROGRAMCLASS Program\n"); };
main { printf("TOKEN_MAINFUNC main\n"); };

    /*bug: wrong hex number*/
[0][xX][a-zA-Z0-9]*[g-zG-Z][a-zA-Z0-9]* { printf("error: wrong hex number -> Unauthorized letters have been used\n"); };


    /*identifiers*/
[a-zA-Z_][a-zA-Z0-9_]* { printf("TOKEN_ID %s\n", yytext); };

    /*comments*/
\/\/(.*)\n { printf("TOKEN_COMMENT %s", yytext); };

    /*strings*/
\"([^"\n]*)\" { printf("TOKEN_STRINGCONST %s\n", yytext); };
\"([^"\n]*)\\\"([^"\n]*)\" { printf("TOKEN_STRINGCONST %s\n", yytext); };

    /*bug: string*/
\" { printf("error in line  : string without closing\n"); };

    /*whitespaces*/
[ ] { printf("TOKEN_WHITESPACE [space]\n"); };
[\t] { printf("TOKEN_WHITESPACE [tab]\n"); };
[\n] { printf("TOKEN_WHITESPACE [newline]\n"); };

    /*bug: id*/
[0-9]+[a-zA-Z_]+ { printf("error in line  : wrong id definition\n"); };

    /*numbers*/
[-][0-9]+ { compare_neg() ; };
[0-9]+ { compare_pos () ; };
[0][xX][0-9a-fA-F]+ { printf("TOKEN_HEXADECIMALCONST %s\n", yytext); };




    /*operators*/
[+] { printf("TOKEN_ARITHMATICOP +\n"); };
[-] { printf("TOKEN_ARITHMATICOP -\n"); };
[*] { printf("TOKEN_ARITHMATICOP *\n"); };
[/] { printf("TOKEN_ARITHMATICOP /\n"); };
[%] { printf("TOKEN_ARITHMATICOP \%\n"); };
[&][&] { printf("TOKEN_CONDITIONOP &&\n"); };
[|][|] { printf("TOKEN_CONDITIONOP ||\n"); };
[<][=] { printf("TOKEN_RELATIONOP <=\n"); };
[<] { printf("TOKEN_RELATIONOP <\n"); };
[>] { printf("TOKEN_RELATIONOP >\n"); };
[>][=] { printf("TOKEN_RELATIONOP >=\n"); };
[!][=] { printf("TOKEN_EQUALITYOP !=\n"); };
[=][=] { printf("TOKEN_EQUALITYOP ==\n"); };
[=] { printf("TOKEN_ASSIGNOP =\n"); };
[+][=] { printf("TOKEN_ASSIGNOP +=\n"); };
[-][=] { printf("TOKEN_ASSIGNOP -=\n"); };
[!] { printf("TOKEN_LOGICOP !\n"); };
[(] { printf("TOKEN_LP (\n"); };
[)] { printf("TOKEN_RP )\n"); };
[{] { printf("TOKEN_LCB {\n"); };
[}] { printf("TOKEN_RCB }\n"); };
\[ { printf("TOKEN_LB [\n"); };
\] { printf("TOKEN_RB ]\n"); };
[;] { printf("TOKEN_SEMICOLON ;\n"); };
[,] { printf("TOKEN_COMMA ,\n"); };

    /*bug: others*/
. { printf("bad character %s\n", yytext); };
%%


void compare_pos()
{
    if(strlen(yytext) > 10)
    {
        printf("The number is out of range\n");
        return;
    }
    num = atof(yytext);
    if(num > 2147483647)
	printf("The number is out of range\n");
    else
	printf("TOKEN_DECIMALCONST %s\n", yytext);

}


void compare_neg()
{
    if(strlen(yytext) > 11)
    {
        printf("The number is out of range\n");
        return;
    }
    num = atof(yytext);
    if(num < -2147483648)
        printf("The number is out of range\n");
    else
        printf("TOKEN_DECIMALCONST %s\n", yytext);

}

int yywrap(){}

int main()
{
  yyin=fopen("test.cpp","r");
  //yyout=fopen("output.cpp","w");
  yylex();
  return 0;
}
