# -*- coding: UTF-8 -*-

import mysql.connector
import re
import os
from ParamCode import ParamCode
from os.path import dirname, join

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
    def generate_param_code_tree(param_num, param_type):
        if param_num == 0:
            return None
        param_type_list = param_type.split(',')
        param_code_tree = None
        prev_param = None
        for i, type in enumerate(param_type_list):
            param = ParamCode(type, i)
            param.gen_param_code()
            if param_code_tree is None:
                param_code_tree = param
                prev_param = param
            else:
                temp = prev_param
                while temp is not None:
                    temp.child = param
                    temp = temp.sibling
                prev_param = param
        # param_code_tree.print_param_code()
        return param_code_tree
    
    @staticmethod
    def generate_invoke_code(param_num, func_name):
        param = ["p{}".format(str(i)) for i in range(0, param_num)]
        param = ", ".join(param)
        return "{}({});".format(func_name, param)

    @staticmethod
    def generate_driver_filepath(filepath, func_id, infix):
        tmp = re.split("/", filepath)
        filename = tmp[-1]
        if infix is None or infix == "":
            return "{}/1_DriverCode/{}_{}".format(os.path.dirname(os.path.dirname(filepath)), func_id, filename)
        else:
            return "{}/1_DriverCode/{}_{}_{}".format(os.path.dirname(os.path.dirname(filepath)), func_id, infix, filename)

    @staticmethod
    def generate_instance_code(func_code, param_code_tree, invoke_code, filepath, func_id):
        
        with open(join(dirname(__file__), "template"), "r") as f:
            template = f.read()
        
        def _gen(prev_code, param, infix):  # infix:中缀，如果有数组类型的参数，文件名将以index[length]作为中缀插入到func_id和filename中间
            if param is None:
                path = CodeGenerator.generate_driver_filepath(filepath, func_id, infix)
                with open(path, "w") as f:
                    instance_code = template % (func_code, prev_code, invoke_code)
                    f.write(instance_code)
            else:
                if param.sibling is None:
                    prev_code += ("\n\t" + "\n\t".join(param.code))
                    _gen(prev_code, param.child, infix)
                else:
                    p = param
                    length = 1
                    while p is not None:
                        if infix is None or infix == "":
                            new_infix = "{index}[{len}]".format(index=str(p.param_index), len=length)
                        else:
                            new_infix = infix + ",{index}[{len}]".format(index=str(p.param_index), len=length)
                        new_code = prev_code + ("\n\t" + "\n\t".join(p.code))
                        _gen(new_code, p.child, new_infix)
                        p = p.sibling
                        length += 1
                        
        _gen("", param_code_tree, None)
   