#include <my_global.h>
#include <mysql.h>

struct FuncSignature {
    char* funcName;
    char* filePath;
    char* retType;
    int paramNum;
    char* paramType;
    char* doc;
    char* keyword;
};

/* 返回db中的id */
int saveToDB(struct FuncSignature func);

int init_connection();
void finish_with_error(MYSQL* conn);