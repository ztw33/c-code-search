%locations
%{
    #include <stdio.h>
    #include <string.h>
    #include <stdarg.h>
    #include "lex.yy.c"
    #include "utils.h"

    void yyerror(const char* s);

    int errorNum = 0;
    int lastErrorLineno = 0;

    /* 
     * Type of the node:
     *  - NonTerm: Non-Terminal, line number should be printed
     *  - NonValToken: Token without value, print node name only
     *  - ValToken: Token with value, value should be printed
     */
    enum NodeType { NonTerm, NonValToken, ValToken };
    struct Node {
        char* nodeName;
        enum NodeType nodeType;
        int lineNum;
        union {
            int intVal;
            float floatVal;
            char* stringVal;
        };
        struct Node* firstChild;
        struct Node* nextSibling;
    };

    struct Node* syntaxTreeRootNode = NULL;

    struct Node* createNewNode(char* nodeName, enum NodeType nodeType, int lineNum);
    void buildRel(struct Node* fatherNode, int childNodeNum, ...);
    void printSyntaxTree(struct Node* rootNode);

    void printError(char errorType, int lineno, char* msg);
    int isNewError(int errorLineno);

    // 提取函数签名
    void getParamNumAndType(struct Node* ValList);
    struct FuncSignature funcSig;
%}

/* declared types */
%union {
    int type_int;
    float type_float;
    char* type_string;
    struct Node* type_pnode;
}

/* declared tokens */
%token RELOP ASSIGNOP
%token SEMI COMMA
%token PLUS MINUS STAR DIV AND OR NOT
%token DOT
%token LP RP LB RB LC RC
%token <type_int> INT
%token <type_float> FLOAT
%token <type_string> ID TYPE
%token IF ELSE WHILE STRUCT RETURN

/* declared non-terminals */
%type <type_pnode> FuncSig Specifier VarDec FunDec VarList ParamDec

/* precedence and associativity */
%nonassoc error
%right ASSIGNOP
%left OR
%left AND
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right NOT
%left LP RP LB RB DOT

%%
FuncSig : Specifier FunDec {
        struct Node* nodeFuncSig = createNewNode("FuncSig", NonTerm, @$.first_line);
        buildRel(nodeFuncSig, 2, $1, $2);
        $$ = nodeFuncSig;
        syntaxTreeRootNode = $$;

        funcSig.retType = $1->firstChild->stringVal;
        YYACCEPT;
    }
Specifier : TYPE {
            struct Node* nodeTYPE = createNewNode("TYPE", ValToken, @1.first_line);
            nodeTYPE->stringVal = $1;
            struct Node* nodeSpecifier = createNewNode("Specifier", NonTerm, @$.first_line);
            buildRel(nodeSpecifier, 1, nodeTYPE);
            $$ = nodeSpecifier;
        }
    | TYPE STAR {
            struct Node* nodeTYPE = createNewNode("TYPE", ValToken, @1.first_line);
            nodeTYPE->stringVal = strcat($1, "*");
            struct Node* nodeSpecifier = createNewNode("Specifier", NonTerm, @$.first_line);
            buildRel(nodeSpecifier, 1, nodeTYPE);
            $$ = nodeSpecifier;
        }
    ;
VarDec : ID {
            struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
            nodeID->stringVal = $1;
            struct Node* nodeVarDec = createNewNode("VarDec", NonTerm, @$.first_line);
            nodeVarDec->firstChild = nodeID;
            $$ = nodeVarDec;
        }
    | VarDec LB INT RB {
            struct Node* nodeLB = createNewNode("LB", NonValToken, @2.first_line);
            struct Node* nodeINT = createNewNode("INT", ValToken, @3.first_line);
            nodeINT->intVal = $3;
            struct Node* nodeRB = createNewNode("RB", NonValToken, @4.first_line);
            struct Node* nodeVarDec = createNewNode("VarDec", NonTerm, @$.first_line);
            buildRel(nodeVarDec, 4, $1, nodeLB, nodeINT, nodeRB);
            $$ = nodeVarDec;
        }
    | VarDec LB error RB {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error between \"[]\"");
                struct Node* nodeLB = createNewNode("LB", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);
                struct Node* nodeRB = createNewNode("RB", NonValToken, @4.first_line);
                struct Node* nodeVarDec = createNewNode("VarDec", NonTerm, @$.first_line);
                buildRel(nodeVarDec, 4, $1, nodeLB, nodeError, nodeRB);
                $$ = nodeVarDec;
            }
        }
    ;
FunDec : ID LP VarList RP {
            struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
            nodeID->stringVal = $1;
            struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
            struct Node* nodeRP = createNewNode("RP", NonValToken, @4.first_line);
            struct Node* nodeFunDec = createNewNode("FunDec", NonTerm, @$.first_line);
            buildRel(nodeFunDec, 4, nodeID, nodeLP, $3, nodeRP);
            $$ = nodeFunDec;
            funcSig.funcName = nodeID->stringVal;
            getParamNumAndType($3);
        }
    | ID LP RP {
            struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
            nodeID->stringVal = $1;
            struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
            struct Node* nodeRP = createNewNode("RP", NonValToken, @3.first_line);
            struct Node* nodeFunDec = createNewNode("FunDec", NonTerm, @$.first_line);
            buildRel(nodeFunDec, 3, nodeID, nodeLP, nodeRP);
            $$ = nodeFunDec;
            funcSig.funcName = nodeID->stringVal;
            getParamNumAndType(NULL);
        }
    | ID LP error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Missing \")\"");
                struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
                nodeID->stringVal = $1;
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);
                struct Node* nodeFunDec = createNewNode("FunDec", NonTerm, @$.first_line);
                buildRel(nodeFunDec, 3, nodeID, nodeLP, nodeError);
                $$ = nodeFunDec;
            } 
        }
    | ID LP error RP {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error between ()");
                struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
                nodeID->stringVal = $1;
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);
                struct Node* nodeRP = createNewNode("RP", NonValToken, @4.first_line);
                struct Node* nodeFunDec = createNewNode("FunDec", NonTerm, @$.first_line);
                buildRel(nodeFunDec, 4, nodeID, nodeLP, nodeError, nodeRP);
                $$ = nodeFunDec;
            }
        }
    | ID error RP {
            if (isNewError(@2.first_line)) {
                printError('B', @2.first_line, "Missing \"(\"");
                struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
                nodeID->stringVal = $1;
                struct Node* nodeError = createNewNode("error", NonValToken, @2.first_line);
                struct Node* nodeRP = createNewNode("RP", NonValToken, @3.first_line);
                struct Node* nodeFunDec = createNewNode("FunDec", NonTerm, @$.first_line);
                buildRel(nodeFunDec, 3, nodeID, nodeError, nodeRP);
                $$ = nodeFunDec;
            }
        }
    ;
VarList : ParamDec COMMA VarList {
            struct Node* nodeCOMMA = createNewNode("COMMA", NonValToken, @2.first_line);
            struct Node* nodeVarList = createNewNode("VarList", NonTerm, @$.first_line);
            buildRel(nodeVarList, 3, $1, nodeCOMMA, $3);
            $$ = nodeVarList;
        }
    | ParamDec {
            struct Node* nodeVarList = createNewNode("VarList", NonTerm, @$.first_line);
            nodeVarList->firstChild = $1;
            $$ = nodeVarList;
        }
    ;
ParamDec : Specifier VarDec {
            struct Node* nodeParamDec = createNewNode("ParamDec", NonTerm, @$.first_line);
            buildRel(nodeParamDec, 2, $1, $2);
            $$ = nodeParamDec;
        }
    ;
%%
struct Node* createNewNode(char* nodeName, enum NodeType nodeType, int lineNum) {
    struct Node* newNode = (struct Node*)malloc(sizeof(struct Node));
    newNode->nodeName = nodeName;
    newNode->nodeType = nodeType;
    newNode->lineNum = lineNum;
    newNode->firstChild = NULL;
    newNode->nextSibling = NULL;
    return newNode;
}

void buildRel(struct Node* fatherNode, int childNodeNum, ...) {
    va_list valist;
    va_start(valist, childNodeNum);
    struct Node* firstChild = NULL;
    struct Node* lastChild = NULL;
    for (int i = 0; i < childNodeNum; i++) {
        struct Node* curNode = va_arg(valist, struct Node*);
        if (firstChild == NULL) {
            if (curNode != NULL) {
                firstChild = curNode;
                lastChild = firstChild;
            }
        } else {
            if (curNode != NULL) {
                lastChild->nextSibling = curNode;
                lastChild = curNode;
            }
        }
    }
    va_end(valist);
    fatherNode->firstChild = firstChild;
}

void _printSyntaxTree(struct Node* rootNode, int spaceNum) {
    if (rootNode == NULL)
        return;
    for (int i = 0; i < spaceNum; i++) {
        printf(" ");
    }
    switch (rootNode->nodeType) {
        case NonTerm:
            printf("%s (%d)\n", rootNode->nodeName, rootNode->lineNum);
            break;
        case NonValToken:
            printf("%s\n", rootNode->nodeName);
            break;
        case ValToken:
            printf("%s: ", rootNode->nodeName);
            if ((strcmp(rootNode->nodeName, "TYPE") == 0) || (strcmp(rootNode->nodeName, "ID") == 0)) {
                printf("%s\n", rootNode->stringVal);
            } else if (strcmp(rootNode->nodeName, "INT") == 0) {
                printf("%d\n", rootNode->intVal);
            } else if (strcmp(rootNode->nodeName, "FLOAT") == 0) {
                printf("%f\n", rootNode->floatVal);
            } else {
                printf("ERROR!!!");
            }
            break;
        default:
            printf("ERROR!!!");
    }
    spaceNum += 2;
    struct Node* firstChild = rootNode->firstChild;
    if (firstChild != NULL) {
        _printSyntaxTree(firstChild, spaceNum);
        struct Node* sibling = firstChild->nextSibling;
        while (sibling != NULL) {
            _printSyntaxTree(sibling, spaceNum);
            sibling = sibling->nextSibling;
        }
    }
}

void printSyntaxTree(struct Node* rootNode) {
    _printSyntaxTree(rootNode, 0);
}

void yyerror(const char* s) { }

void printError(char errorType, int lineno, char* msg) {
    fprintf(stderr, "\033[31mError type %c\033[0m at \033[31mLine %d\033[0m: %s.\n\033[0m", errorType, lineno, msg);
}

int isNewError(int errorLineno) {
    if (lastErrorLineno != errorLineno) {
        errorNum++;
        lastErrorLineno = errorLineno;
        return 1;
    } else {
        return 0;
    }
}

void destroySyntaxTree(struct Node* rootNode) {
    if (rootNode == NULL) {
        return;
    }
    struct Node* curNode = rootNode->firstChild;
    struct Node* nextNode = NULL;
    while (curNode != NULL) {
        nextNode = curNode->nextSibling;
        destroySyntaxTree(curNode);
        curNode = nextNode;
    }
    if ((strcmp(rootNode->nodeName, "TYPE") == 0) || (strcmp(rootNode->nodeName, "ID") == 0)) {
        free(rootNode->stringVal);
        rootNode->stringVal = NULL;
    }
    free(rootNode);
    rootNode = NULL;
}

void getParamNumAndType(struct Node* ValList) {  
    if (ValList == NULL) {
        funcSig.paramType = NULL;
        funcSig.paramNum = 0;
        return;
    }
    int paramNum = 0;
    char* paramTypeStr;
    struct Node* paramDec = ValList->firstChild;
    while (paramDec != NULL) {
        paramNum += 1;
        if (paramNum == 1) {
            paramTypeStr = strdup(paramDec->firstChild->firstChild->stringVal);
        } else {
            strcat(paramTypeStr, ",");
            strcat(paramTypeStr, strdup(paramDec->firstChild->firstChild->stringVal));
        }
        if (paramDec->nextSibling == NULL)
            paramDec = NULL;
        else
            paramDec = paramDec->nextSibling->nextSibling->firstChild;
    }
    funcSig.paramType = paramTypeStr;
    funcSig.paramNum = paramNum;
    return;
}
