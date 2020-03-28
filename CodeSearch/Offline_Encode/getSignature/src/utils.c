#include "utils.h"

MYSQL* connection;
const char* hostname = "localhost";
const char* username = "root";
const char* password = "19980330";
const char* DBname = "CodeQuery";

int saveToDB(struct FuncSignature func) {
    if (init_connection(connection) == -1) {
        return -1;
    }
    char sql[1024];
    sprintf(sql, "INSERT INTO func_signature (func_name, file_path, ret_type, param_num, param_type, doc, keyword) "
                 "VALUES ('%s', '%s', '%s', %d, '%s', null, null)", \
                 func.funcName, func.filePath, func.retType, func.paramNum, func.paramType);
    if (mysql_query(connection, sql)) {
		finish_with_error(connection);
        return -1;
	}
    int id = mysql_insert_id(connection);
    mysql_close(connection);
    return id;
}

/* 成功返回0，失败返回-1 */
int init_connection() {
    if (connection == NULL) {
        connection = mysql_init(NULL);
        if (connection == NULL) {
            fprintf(stderr, "%s\n", mysql_error(connection));
            return -1;
        }
    }
    if (mysql_real_connect(connection, hostname, username, password, DBname, 0, NULL, 0) == NULL) {
		finish_with_error(connection);
        return -1;
	}
    return 0;
}

void finish_with_error(MYSQL* conn)
{
    fprintf(stderr, "%s\n", mysql_error(conn));
    mysql_close(conn);
}