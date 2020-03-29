#include "utils.h"

extern FILE* yyin;
extern int yyparse (void);
extern void yyrestart (FILE *input_file  );
extern int errorNum;
extern struct Node* syntaxTreeRootNode;
extern void printSyntaxTree(struct Node* rootNode);
extern void destroySyntaxTree(struct Node* rootNode);
extern struct FuncSignature funcSig;

int main(int argc, char** argv) {
    if (argc <= 1) 
        return 1;
    FILE* f = fopen(argv[1], "r");
    if (!f) {
        perror(argv[1]);
        return 1;
    }
    char absPathBuf[256];
    if(realpath(argv[1], absPathBuf)) {
        funcSig.filePath = absPathBuf;
    } else {
        printf("the file '%s' is not exist\n", argv[1]);  
        return 1;  
    }
    yyrestart(f);
    int abort = yyparse();
    if (!abort) {
        printf("return type: %s\nparam num: %d\nparam type: %s\n", funcSig.retType, funcSig.paramNum, funcSig.paramType);
        funcSig.doc = "";
        funcSig.keyword = "";
        int funcID = saveToDB(funcSig);
        if (funcID == -1) {
            fprintf(stderr, "error occured when saving to database\n");
        }
        destroySyntaxTree(syntaxTreeRootNode);
        return funcID;
    }
    return -1;
}