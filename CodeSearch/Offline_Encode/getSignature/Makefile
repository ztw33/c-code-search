# 编译器设定和编译选项
CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -std=c99

# 编译目标：src目录下的所有.c文件
CFILES = $(shell find ./ -name "*.c")
OBJS = $(CFILES:.c=.o)
LFILE = $(shell find ./ -name "*.l")
YFILE = $(shell find ./ -name "*.y")
LFC = $(shell find ./ -name "*.l" | sed s/[^/]*\\.l/lex.yy.c/)
YFC = $(shell find ./ -name "*.y" | sed s/[^/]*\\.y/syntax.tab.c/)
LFO = $(LFC:.c=.o)
YFO = $(YFC:.c=.o)
MAINC = $(shell find ./ -name "main.c")
UTILSC = $(shell find ./ -name "utils.c")
MAINO = $(MAINC:.c=.o)
UTILSO = $(UTILSC:.c=.o)
MYSQL = $(shell mysql_config --cflags --libs)

parser: syntax cfile $(filter-out $(LFO),$(OBJS))
	$(CC) -o parser $(filter-out $(LFO),$(OBJS)) -lfl -ly $(MYSQL)

cfile:
	$(CC) -c $(MAINC) -o $(MAINO) $(MYSQL)
	$(CC) -c $(UTILSC) -o $(UTILSO) $(MYSQL)

syntax: lexical syntax-c
	$(CC) -c $(YFC) -o $(YFO) $(MYSQL)

lexical: $(LFILE)
	$(FLEX) -o $(LFC) $(LFILE)

syntax-c: $(YFILE)
	$(BISON) -o $(YFC) -d $(YFILE)

-include $(patsubst %.o, %.d, $(OBJS))

# 定义的一些伪目标
.PHONY: clean test
test:
	./parser ../Test/test1.cmm
clean:
	rm -f parser
	rm -f $(OBJS) $(OBJS:.o=.d)
	rm -f $(LFC) $(YFC) $(YFC:.c=.h)
	rm -f *~
