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
        self.cursor = self.db_conn.cursor()
    
    def select_func_by_where_cond(self, where_cond):
        cursor = self.cursor
        cursor.execute("SELECT id, func_name, file_path, ret_type, param_num, param_type FROM func_signature WHERE " + where_cond)
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
        return result
    
    def select_smt_files_by_id(self, func_id):
        cursor = self.cursor
        cursor.execute("SELECT smt_filepath FROM pc WHERE func_id = " + str(func_id))
        result = []
        for smt_filepath in cursor:
            result.append(smt_filepath[0])
        return result
    
    def db_close(self):
        print("db close")
        if self.db_conn is not None and self.db_conn.is_connected():
            self.cursor.close()
            self.db_conn.close()
