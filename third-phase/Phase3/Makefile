all:	
	bison -d p.y
	flex p.l
	g++ p.tab.c lex.yy.c -lfl -o p
	./p sample.file
clean:
	rm lex.yy.c
	rm p.tab.h
	rm p.tab.c
	rm p
	rm Output.asm
	
