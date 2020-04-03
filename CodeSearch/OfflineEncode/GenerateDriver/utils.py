# -*- coding: UTF-8 -*-

import mysql.connector
import re
import os

hostname = "localhost"
user = "root"
password = "19980330"
dbname = "CodeQuery"

class DBUtil:
    def __init__(self):
        self.db_conn = mysql.connector.connect(host=hostname, 
                                               user=user, 
                                               passwd=password,
                                               database=dbname)
        
    def select_by_id(self, id):
        cursor = self.db_conn.cursor()
        cursor.execute("SELECT * FROM func_signature where id = " + id)
        result = cursor.fetchone()
        cursor.close()
        return result[1], result[2], result[3], result[4], result[5]
    
    def __exit__(self, exc_type, exc_value, traceback):
        if self.db_conn is not None and self.db_conn.is_connected():
            self.db_conn.close()

class CodeGenerator:
    @staticmethod
    def generate_param_code(param_num, param_type):
        if param_num == 0:
            return ""
        param_type_list = param_type.split(',')
        param_code = ""
        for i, type in enumerate(param_type_list):
            index = i
            if type == "int" or type == "double":
                param_code += "\t{type} p{index};\n\tklee_make_symbolic(&p{index}, sizeof(p{index}), \"?p{index}\");\n".format(type=type, index=index)
            elif type == "char":
                param_code += "\t{type} p{index};\n\tklee_make_symbolic(&p{index}, sizeof(p{index}), \"?p{index}\");\n".format(type=type, index=index)
                param_code += "\tklee_assume(p{index} >= 32 & p{index} <= 126);".format(index=index)  # 仅为可见字符
            elif type == "int*" or type == "double*":
                pass
            elif type == "char*":
                pass
            else:
                print("异常的数据类型！")
                return ""
        return param_code
    
    @staticmethod
    def generate_invoke_code(param_num, func_name):
        param = ["p{}".format(str(i)) for i in range(0, param_num)]
        param = ", ".join(param)
        return "{}({});".format(func_name, param)

    @staticmethod
    def generate_driver_filepath(filepath, func_id):
        tmp = re.split("/", filepath)
        filename = tmp[-1]
        return "{}/1_DriverCode/{}_{}".format(os.path.dirname(os.path.dirname(filepath)), func_id, filename)
        