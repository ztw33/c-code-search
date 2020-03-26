#include <my_global.h>
#include <mysql.h>

void finish_with_error(MYSQL *conn)
{
  fprintf(stderr, "%s\n", mysql_error(conn));
  mysql_close(conn);
  exit(1);        
}

int main(int argc, char **argv)
{
	printf("MySQL client version: %s\n", mysql_get_client_info());
	MYSQL *conn = mysql_init(NULL);
	if (conn == NULL) {
		fprintf(stderr, "%s\n", mysql_error(conn));
		exit(1);
	}
	if (mysql_real_connect(conn, "localhost", "root", "19980330", "CodeQuery", 0, NULL, 0) == NULL) {
		finish_with_error(conn);
	}
	if (mysql_query(conn, "INSERT INTO func_signature (func_name, file_path, ret_type, param_num, param_type, doc, keyword) VALUES ('get_sign', '/home/ztw/Graguation_project/C-code_search/CodeSearch/Offline_Encode/getSignature/Test/get_sign.c', 'int', 1, 'int', null, null)")) {
		finish_with_error(conn);
	}
	mysql_close(conn);
	return 0;
}
