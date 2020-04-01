# -*- coding: UTF-8 -*-
import mysql.connector
from configparser import ConfigParser
    
class DBUtil:
    def __init__(self):
        cfg = ConfigParser()
        cfg.read("../db.conf")
        self.db_conn = mysql.connector.connect(host=cfg.get("db", "hostname"), 
                                               user=cfg.get("db", "user"), 
                                               passwd=cfg.get("db", "password"),
                                               database=cfg.get("db", "dbname"))
    
    def __exit__(self, exc_type, exc_value, traceback):
        if self.db_conn is not None and self.db_conn.is_connected():
            self.db_conn.close()
    
    def select_by_where_cond(self, where_cond):
        cursor = self.db_conn.cursor()
        cursor.execute("SELECT id, func_name, file_path, ret_type, param_num, param_type FROM func_signature where " + where_cond)
        result = []
        for (id, func_name, file_path, ret_type, param_num, param_type) in cursor:
            result.append({
                "func_id": id,
                "func_name": func_name,
                "file_path": file_path,
                "ret_type": ret_type,
                "param_num": param_num,
                "param_type": param_type
            })
        cursor.close()
        return result
