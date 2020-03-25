%locations
%{
    #include <stdio.h>
    #include <string.h>
    #include <stdarg.h>
    #include "lex.yy.c"
    #include "database.h"

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
    int getParamNumAndType(struct Node* ValList);
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
%type <type_pnode> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier
%type <type_pnode> OptTag Tag VarDec FunDec VarList ParamDec CompSt
%type <type_pnode> StmtList Stmt DefList Def DecList Dec Exp Args

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
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
/* High-level Definitions */
Program : ExtDefList {
            struct Node* nodeProgram = createNewNode("Program", NonTerm, @$.first_line);
            buildRel(nodeProgram, 1, $1);
            $$ = nodeProgram;
            syntaxTreeRootNode = nodeProgram;
        }
    | ExtDefList error {
            if (isNewError(@2.first_line)) {
                printError('B', @2.first_line, "Unexpected character");
                struct Node* nodeError = createNewNode("error", NonValToken, @2.first_line);
                struct Node* nodeProgram = createNewNode("Program", NonTerm, @$.first_line);
                buildRel(nodeProgram, 2, $1, nodeError);
                $$ = nodeProgram;
                syntaxTreeRootNode = nodeProgram;
            }
        }
    ;
ExtDefList : ExtDef ExtDefList {
            struct Node* nodeExtDefList = createNewNode("ExtDefList", NonTerm, @$.first_line);
            buildRel(nodeExtDefList, 2, $1, $2);
            $$ = nodeExtDefList;
        }
    | /* empty */ {
            $$ = NULL;
        }
    ;
ExtDef : Specifier ExtDecList SEMI {
            struct Node* nodeSEMI = createNewNode("SEMI", NonValToken, @3.first_line);
            struct Node* nodeExtDef = createNewNode("ExtDef", NonTerm, @$.first_line);
            buildRel(nodeExtDef, 3, $1, $2, nodeSEMI);
            $$ = nodeExtDef;
        }
    | Specifier SEMI {
            struct Node* nodeSEMI = createNewNode("SEMI", NonValToken, @2.first_line);
            struct Node* nodeExtDef = createNewNode("ExtDef", NonTerm, @$.first_line);
            buildRel(nodeExtDef, 2, $1, nodeSEMI);
            $$ = nodeExtDef;
        }
    | Specifier FunDec CompSt {
            struct Node* nodeExtDef = createNewNode("ExtDef", NonTerm, @$.first_line);
            buildRel(nodeExtDef, 3, $1, $2, $3);
            $$ = nodeExtDef;
            printf("Function Return Type: %s\n", $1->firstChild->stringVal);
        }
    | Specifier error {
            if (isNewError(@2.first_line)) {
                printError('B', @2.first_line, "Missing \";\"");
                struct Node* nodeError = createNewNode("error", NonValToken, @2.first_line);
                struct Node* nodeExtDef = createNewNode("ExtDef", NonTerm, @$.first_line);
                buildRel(nodeExtDef, 2, $1, nodeError);
                $$ = nodeExtDef;
            }
        }
    ;
ExtDecList : VarDec {
            struct Node* nodeExtDecList = createNewNode("ExtDecList", NonTerm, @$.first_line);
            buildRel(nodeExtDecList, 1, $1);
            $$ = nodeExtDecList;
        }
    | VarDec COMMA ExtDecList {
            struct Node* nodeCOMMA = createNewNode("COMMA", NonValToken, @2.first_line);
            struct Node* nodeExtDecList = createNewNode("ExtDecList", NonTerm, @$.first_line);
            buildRel(nodeExtDecList, 3, $1, nodeCOMMA, $3);
            $$ = nodeExtDecList;
        }
    ;

/* Specifiers */
Specifier : TYPE {
            struct Node* nodeTYPE = createNewNode("TYPE", ValToken, @1.first_line);
            nodeTYPE->stringVal = $1;
            struct Node* nodeSpecifier = createNewNode("Specifier", NonTerm, @$.first_line);
            buildRel(nodeSpecifier, 1, nodeTYPE);
            $$ = nodeSpecifier;
        }
    | StructSpecifier {
            struct Node* nodeSpecifier = createNewNode("Specifier", NonTerm, @$.first_line);
            buildRel(nodeSpecifier, 1, $1);
            $$ = nodeSpecifier;
        }
    ;
StructSpecifier : STRUCT OptTag LC DefList RC {
            struct Node* nodeSTRUCT = createNewNode("STRUCT", NonValToken, @1.first_line);
            struct Node* nodeLC = createNewNode("LC", NonValToken, @3.first_line);
            struct Node* nodeRC = createNewNode("RC", NonValToken, @5.first_line);
            struct Node* nodeStructSpecifier = createNewNode("StructSpecifier", NonTerm, @$.first_line);           
            buildRel(nodeStructSpecifier, 5, nodeSTRUCT, $2, nodeLC, $4, nodeRC);          
            $$ = nodeStructSpecifier;
        }
    | STRUCT Tag {
            struct Node* nodeSTRUCT = createNewNode("STRUCT", NonValToken, @1.first_line);           
            struct Node* nodeStructSpecifier = createNewNode("StructSpecifier", NonTerm, @$.first_line);
            buildRel(nodeStructSpecifier, 2, nodeSTRUCT, $2);
            $$ = nodeStructSpecifier;
        }
    | STRUCT OptTag LC DefList error {
            if (isNewError(@5.first_line)) {
                printError('B', @5.first_line, "Missing \"}\"");
                struct Node* nodeSTRUCT = createNewNode("STRUCT", NonValToken, @1.first_line);
                struct Node* nodeLC = createNewNode("LC", NonValToken, @3.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @5.first_line);
                struct Node* nodeStructSpecifier = createNewNode("StructSpecifier", NonTerm, @$.first_line);           
                buildRel(nodeStructSpecifier, 5, nodeSTRUCT, $2, nodeLC, $4, nodeError);          
                $$ = nodeStructSpecifier;
            }
        }
    ;
OptTag : ID {
            struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
            nodeID->stringVal = $1;
            struct Node* nodeOptTag = createNewNode("OptTag", NonTerm, @$.first_line);
            buildRel(nodeOptTag, 1, nodeID);
            $$ = nodeOptTag;
        }
    | /* empty */ {
            $$ = NULL;
        }
    ;
Tag : ID {
            struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
            nodeID->stringVal = $1;
            struct Node* nodeTag = createNewNode("Tag", NonTerm, @$.first_line);
            buildRel(nodeTag, 1, nodeID);
            $$ = nodeTag;
        }
    ;

/* Declarators */
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
            int paramNum = getParamNumAndType($3);
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

/* Statements */
CompSt : LC DefList StmtList RC {
            struct Node* nodeLC = createNewNode("LC", NonValToken, @1.first_line);
            struct Node* nodeRC = createNewNode("RC", NonValToken, @4.first_line);
            struct Node* nodeCompSt = createNewNode("CompSt", NonTerm, @$.first_line);
            buildRel(nodeCompSt, 4, nodeLC, $2, $3, nodeRC);
            $$ = nodeCompSt;
        }
    | error DefList StmtList RC {
            if (isNewError(@1.first_line)) {
                printError('B', @1.first_line, "Missing \"{\"");
                struct Node* nodeError = createNewNode("error", NonValToken, @1.first_line);
                struct Node* nodeRC = createNewNode("LC", NonValToken, @4.first_line);
                struct Node* nodeCompSt = createNewNode("CompSt", NonTerm, @$.first_line);
                buildRel(nodeCompSt, 4, nodeError, $2, $3, nodeRC);
                $$ = nodeCompSt;
            }
        }
    ;
StmtList : Stmt StmtList {
            struct Node* nodeStmtList = createNewNode("StmtList", NonTerm, @$.first_line);
            buildRel(nodeStmtList, 2, $1, $2);
            $$ = nodeStmtList;
        }
    | /* empty */ {
            $$ = NULL;
        }
    ;
Stmt : Exp SEMI {
            struct Node* nodeSEMI = createNewNode("SEMI", NonValToken, @2.first_line);
            struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
            buildRel(nodeStmt, 2, $1, nodeSEMI);
            $$ = nodeStmt;
        }
    | CompSt {
            struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
            nodeStmt->firstChild = $1;
            $$ = nodeStmt;
        }
    | RETURN Exp SEMI {
            struct Node* nodeRETURN = createNewNode("RETURN", NonValToken, @1.first_line);
            struct Node* nodeSEMI = createNewNode("SEMI", NonValToken, @3.first_line);
            struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
            buildRel(nodeStmt, 3, nodeRETURN, $2, nodeSEMI);
            $$ = nodeStmt;
        }
    | IF LP Exp RP Stmt %prec LOWER_THAN_ELSE {
            struct Node* nodeIF = createNewNode("IF", NonValToken, @1.first_line);
            struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
            struct Node* nodeRP = createNewNode("RP", NonValToken, @4.first_line);
            struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
            buildRel(nodeStmt, 5, nodeIF, nodeLP, $3, nodeRP, $5);
            $$ = nodeStmt;
        }
    | IF LP Exp RP Stmt ELSE Stmt {
            struct Node* nodeIF = createNewNode("IF", NonValToken, @1.first_line);
            struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
            struct Node* nodeRP = createNewNode("RP", NonValToken, @4.first_line);
            struct Node* nodeELSE = createNewNode("ELSE", NonValToken, @6.first_line);
            struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
            buildRel(nodeStmt, 7, nodeIF, nodeLP, $3, nodeRP, $5, nodeELSE, $7);
            $$ = nodeStmt;
        }
    | WHILE LP Exp RP Stmt {
            struct Node* nodeWHILE = createNewNode("WHILE", NonValToken, @1.first_line);
            struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
            struct Node* nodeRP = createNewNode("RP", NonValToken, @4.first_line);
            struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
            buildRel(nodeStmt, 5, nodeWHILE, nodeLP, $3, nodeRP, $5);
            $$ = nodeStmt;
        }
    | Exp error {
            if (isNewError(@2.first_line)) {
                printError('B', @2.first_line, "Missing \";\"");
                struct Node* nodeError = createNewNode("error", NonValToken, @2.first_line);
                struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);                
                buildRel(nodeStmt, 2, $1, nodeError);
                $$ = nodeStmt;
            }
        }
    | RETURN Exp error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Missing \";\"");
                struct Node* nodeRETURN = createNewNode("RETURN", NonValToken, @1.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);
                struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);                
                buildRel(nodeStmt, 3, nodeRETURN, $2, nodeError);
                $$ = nodeStmt;
            }
        }
    | error SEMI {
            if (isNewError(@1.first_line)) {
                printError('B', @1.first_line, "Syntax error in Exp");
                struct Node* nodeError = createNewNode("error", NonValToken, @1.first_line);                
                struct Node* nodeSEMI = createNewNode("SEMI", NonValToken, @2.first_line);
                struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
                buildRel(nodeStmt, 2, nodeError, nodeSEMI);
                $$ = nodeStmt;
            }
        }
    | IF LP error RP Stmt %prec LOWER_THAN_ELSE {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeIF = createNewNode("IF", NonValToken, @1.first_line);
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);                
                struct Node* nodeRP = createNewNode("RP", NonValToken, @4.first_line);
                struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
                buildRel(nodeStmt, 5, nodeIF, nodeLP, nodeError, nodeRP, $5);
                $$ = nodeStmt;
            }
        }
    | IF LP Exp error Stmt %prec LOWER_THAN_ELSE {
            if (isNewError(@4.first_line)) {
                printError('B', @4.first_line, "Missing \")\"");
                struct Node* nodeIF = createNewNode("IF", NonValToken, @1.first_line);
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @4.first_line);                
                struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
                buildRel(nodeStmt, 5, nodeIF, nodeLP, $3, nodeError, $5);
                $$ = nodeStmt;
            }
        }
    | IF LP error RP Stmt ELSE Stmt {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeIF = createNewNode("IF", NonValToken, @1.first_line);
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);                
                struct Node* nodeRP = createNewNode("RP", NonValToken, @4.first_line);
                struct Node* nodeELSE = createNewNode("ELSE", NonValToken, @6.first_line);
                struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
                buildRel(nodeStmt, 7, nodeIF, nodeLP, nodeError, nodeRP, $5, nodeELSE, $7);
                $$ = nodeStmt;
            }
        }
    | IF LP Exp error Stmt ELSE Stmt {
            if (isNewError(@4.first_line)) {
                printError('B', @4.first_line, "Missing \")\"");
                struct Node* nodeIF = createNewNode("IF", NonValToken, @1.first_line);
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @4.first_line);                
                struct Node* nodeELSE = createNewNode("ELSE", NonValToken, @6.first_line);
                struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
                buildRel(nodeStmt, 7, nodeIF, nodeLP, $3, nodeError, $5, nodeELSE, $7);
                $$ = nodeStmt;
            }
        }
    | WHILE LP error RP Stmt {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeWHILE = createNewNode("WHILE", NonValToken, @1.first_line);
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);
                struct Node* nodeRP = createNewNode("RP", NonValToken, @4.first_line);
                struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
                buildRel(nodeStmt, 5, nodeWHILE, nodeLP, nodeError, nodeRP, $5);
                $$ = nodeStmt;
            }
        }
    | WHILE LP Exp error Stmt {
            if (isNewError(@4.first_line)) {
                printError('B', @4.first_line, "Missing \")\"");
                struct Node* nodeWHILE = createNewNode("WHILE", NonValToken, @1.first_line);
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @4.first_line);
                struct Node* nodeStmt = createNewNode("Stmt", NonTerm, @$.first_line);
                buildRel(nodeStmt, 5, nodeWHILE, nodeLP, $3, nodeError, $5);
                $$ = nodeStmt;
            }
        }
    ;

/* Local Definitions */
DefList : Def DefList {
            struct Node* nodeDefList = createNewNode("DefList", NonTerm, @$.first_line);
            buildRel(nodeDefList, 2, $1, $2);
            $$ = nodeDefList;
        }
    | /* empty */ {
            $$ = NULL;
        }
    ;
Def : Specifier DecList SEMI {
            struct Node* nodeSEMI = createNewNode("SEMI", NonValToken, @3.first_line);
            struct Node* nodeDef = createNewNode("Def", NonTerm, @$.first_line);
            buildRel(nodeDef, 3, $1, $2, nodeSEMI);
            $$ = nodeDef;
        }
    | Specifier error SEMI {
            if (isNewError(@2.first_line)) {
                printError('B', @2.first_line, "Syntax error in DecList");
                struct Node* nodeError = createNewNode("error", NonValToken, @2.first_line);
                struct Node* nodeSEMI = createNewNode("SEMI", NonValToken, @3.first_line);
                struct Node* nodeDef = createNewNode("Def", NonTerm, @$.first_line);
                buildRel(nodeDef, 3, $1, nodeError, nodeSEMI);
                $$ = nodeDef;
            }
        }
    ;
DecList : Dec {
            struct Node* nodeDecList = createNewNode("DecList", NonTerm, @$.first_line);
            nodeDecList->firstChild = $1;
            $$ = nodeDecList;
        }
    | Dec COMMA DecList {
            struct Node* nodeCOMMA = createNewNode("COMMA", NonValToken, @2.first_line);
            struct Node* nodeDecList = createNewNode("DecList", NonTerm, @$.first_line);
            buildRel(nodeDecList, 3, $1, nodeCOMMA, $3);
            $$ = nodeDecList;
        }
    ;
Dec : VarDec {
            struct Node* nodeDec = createNewNode("Dec", NonTerm, @$.first_line);
            nodeDec->firstChild = $1;
            $$ = nodeDec;
        }
    | VarDec ASSIGNOP Exp {
            struct Node* nodeASSIGNOP = createNewNode("ASSIGNOP", NonValToken, @2.first_line);
            struct Node* nodeDec = createNewNode("Dec", NonTerm, @$.first_line);
            buildRel(nodeDec, 3, $1, nodeASSIGNOP, $3);
            $$ = nodeDec;
        }
    | VarDec ASSIGNOP error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeASSIGNOP = createNewNode("ASSIGNOP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);
                struct Node* nodeDec = createNewNode("Dec", NonTerm, @$.first_line);
                buildRel(nodeDec, 3, $1, nodeASSIGNOP, nodeError);
                $$ = nodeDec;
            }
        }
    ;

/* Expressions */
Exp : Exp ASSIGNOP Exp {
            struct Node* nodeASSIGNOP = createNewNode("ASSIGNOP", NonValToken, @2.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, $1, nodeASSIGNOP, $3);
            $$ = nodeExp;
        }
    | Exp AND Exp {
            struct Node* nodeAND = createNewNode("AND", NonValToken, @2.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, $1, nodeAND, $3);
            $$ = nodeExp;
        }
    | Exp OR Exp {
            struct Node* nodeOR = createNewNode("OR", NonValToken, @2.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, $1, nodeOR, $3);
            $$ = nodeExp;
        }
    | Exp RELOP Exp {
            struct Node* nodeRELOP = createNewNode("RELOP", NonValToken, @2.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, $1, nodeRELOP, $3);
            $$ = nodeExp;
        }
    | Exp PLUS Exp {
            struct Node* nodePLUS = createNewNode("PLUS", NonValToken, @2.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, $1, nodePLUS, $3);
            $$ = nodeExp;
        }
    | Exp MINUS Exp {
            struct Node* nodeMINUS = createNewNode("MINUS", NonValToken, @2.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, $1, nodeMINUS, $3);
            $$ = nodeExp;
        }
    | Exp STAR Exp {
            struct Node* nodeSTAR = createNewNode("STAR", NonValToken, @2.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, $1, nodeSTAR, $3);
            $$ = nodeExp;
        }
    | Exp DIV Exp {
            struct Node* nodeDIV = createNewNode("DIV", NonValToken, @2.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, $1, nodeDIV, $3);
            $$ = nodeExp;
        }
    | LP Exp RP {
            struct Node* nodeLP = createNewNode("LP", NonValToken, @1.first_line);
            struct Node* nodeRP = createNewNode("RP", NonValToken, @3.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, nodeLP, $2, nodeRP);
            $$ = nodeExp;
        }
    | MINUS Exp {
            struct Node* nodeMINUS = createNewNode("MINUS", NonValToken, @1.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 2, nodeMINUS, $2);
            $$ = nodeExp;
        }
    | NOT Exp {
            struct Node* nodeNOT = createNewNode("NOT", NonValToken, @1.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 2, nodeNOT, $2);
            $$ = nodeExp;
        }
    | ID LP Args RP {
            struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
            nodeID->stringVal = $1;
            struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
            struct Node* nodeRP = createNewNode("RP", NonValToken, @4.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 4, nodeID, nodeLP, $3, nodeRP);
            $$ = nodeExp;
        }
    | ID LP RP {
            struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
            nodeID->stringVal = $1;
            struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
            struct Node* nodeRP = createNewNode("RP", NonValToken, @3.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, nodeID, nodeLP, nodeRP);
            $$ = nodeExp;
        }
    | Exp LB Exp RB {
            struct Node* nodeLB = createNewNode("LB", NonValToken, @2.first_line);
            struct Node* nodeRB = createNewNode("RB", NonValToken, @4.first_line);
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 4, $1, nodeLB, $3, nodeRB);
            $$ = nodeExp;
        }
    | Exp DOT ID {
            struct Node* nodeDOT = createNewNode("DOT", NonValToken, @2.first_line);
            struct Node* nodeID = createNewNode("ID", ValToken, @3.first_line);
            nodeID->stringVal = $3;
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            buildRel(nodeExp, 3, $1, nodeDOT, nodeID);
            $$ = nodeExp;
        }
    | ID {
            struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
            nodeID->stringVal = $1;
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            nodeExp->firstChild = nodeID;
            $$ = nodeExp;
        }
    | INT {
            struct Node* nodeINT = createNewNode("INT", ValToken, @1.first_line);
            nodeINT->intVal = $1;
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            nodeExp->firstChild = nodeINT;
            $$ = nodeExp;
        }
    | FLOAT {
            struct Node* nodeFLOAT = createNewNode("FLOAT", ValToken, @1.first_line);
            nodeFLOAT->floatVal = $1;
            struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
            nodeExp->firstChild = nodeFLOAT;
            $$ = nodeExp;
        }
    | Exp LB error RB {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error between \"[]\"");
                struct Node* nodeLB = createNewNode("LB", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);
                struct Node* nodeRB = createNewNode("RB", NonValToken, @4.first_line);
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 4, $1, nodeLB, nodeError, nodeRB);
                $$ = nodeExp;
            }
        }
    | error RP {
            if (isNewError(@1.first_line)) {
                printError('B', @1.first_line, "Missing \"(\"");
                struct Node* nodeError = createNewNode("error", NonValToken, @1.first_line);
                struct Node* nodeRP = createNewNode("RP", NonValToken, @2.first_line);
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 2, nodeError, nodeRP);
                $$ = nodeExp;
            }
        }
    | ID LP Args error {
            if (isNewError(@4.first_line)) {
                printError('B', @4.first_line, "Missing \")\"");
                struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
                nodeID->stringVal = $1;
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @4.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 4, nodeID, nodeLP, $3, nodeError);
                $$ = nodeExp;
            }
        }
    | ID LP error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Missing \")\"");
                struct Node* nodeID = createNewNode("ID", ValToken, @1.first_line);
                nodeID->stringVal = $1;
                struct Node* nodeLP = createNewNode("LP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, nodeID, nodeLP, nodeError);
                $$ = nodeExp;
            }
        }
    | Exp ASSIGNOP error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeASSIGNOP = createNewNode("ASSIGNOP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, $1, nodeASSIGNOP, nodeError);
                $$ = nodeExp;
            }
        }
    | Exp AND error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeAND = createNewNode("AND", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, $1, nodeAND, nodeError);
                $$ = nodeExp;
            }
        }
    | Exp OR error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeOR = createNewNode("OR", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, $1, nodeOR, nodeError);
                $$ = nodeExp;
            }
        }
    | Exp RELOP error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeRELOP = createNewNode("RELOP", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, $1, nodeRELOP, nodeError);
                $$ = nodeExp;
            }
        }
    | Exp PLUS error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodePLUS = createNewNode("PLUS", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, $1, nodePLUS, nodeError);
                $$ = nodeExp;
            }
        }
    | Exp MINUS error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeMINUS = createNewNode("MINUS", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, $1, nodeMINUS, nodeError);
                $$ = nodeExp;
            }
        }
    | Exp STAR error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeSTAR = createNewNode("STAR", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, $1, nodeSTAR, nodeError);
                $$ = nodeExp;
            }
        }
    | Exp DIV error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Syntax error in Exp");
                struct Node* nodeDIV = createNewNode("DIV", NonValToken, @2.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, $1, nodeDIV, nodeError);
                $$ = nodeExp;
            }
        }
    | MINUS error {
            if (isNewError(@2.first_line)) {
                printError('B', @2.first_line, "Syntax error in Exp");
                struct Node* nodeMINUS = createNewNode("MINUS", NonValToken, @1.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @2.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 2, nodeMINUS, nodeError);
                $$ = nodeExp;
            }
        }
    | NOT error {
            if (isNewError(@2.first_line)) {
                printError('B', @2.first_line, "Syntax error in Exp");
                struct Node* nodeNOT = createNewNode("NOT", NonValToken, @1.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @2.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 2, nodeNOT, nodeError);
                $$ = nodeExp;
            }
        }
    | LP Exp error {
            if (isNewError(@3.first_line)) {
                printError('B', @3.first_line, "Missing \")\"");
                struct Node* nodeLP = createNewNode("LP", NonValToken, @1.first_line);
                struct Node* nodeError = createNewNode("error", NonValToken, @3.first_line);              
                struct Node* nodeExp = createNewNode("Exp", NonTerm, @$.first_line);
                buildRel(nodeExp, 3, nodeLP, $2, nodeError);
                $$ = nodeExp;
            }
        }
    ;
Args : Exp COMMA Args {
            struct Node* nodeCOMMA = createNewNode("COMMA", NonValToken, @2.first_line);
            struct Node* nodeArgs = createNewNode("Args", NonTerm, @$.first_line);
            buildRel(nodeArgs, 3, $1, nodeCOMMA, $3);
            $$ = nodeArgs;
        }
    | Exp {
            struct Node* nodeArgs = createNewNode("Args", NonTerm, @$.first_line);
            nodeArgs->firstChild = $1;
            $$ = nodeArgs;
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

int getParamNumAndType(struct Node* ValList) {
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
    return paramNum;
}
