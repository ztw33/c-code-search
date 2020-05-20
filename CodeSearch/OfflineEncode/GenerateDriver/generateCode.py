#!/usr/bin/python
# -*- coding: UTF-8 -*-

import sys
import os
from utils import DBUtil, CodeGenerator

if __name__ == "__main__":
    if (len(sys.argv) != 2):
        print("参数个数错误")
        exit(1)
    func_id = sys.argv[1]
    print("func_id: {}".format(func_id))
    try:
        dbutil = DBUtil()
        func_name, filepath, ret_type, param_num, param_type = dbutil.select_by_id(func_id)
    except:
        print("数据库查询时出错，请检查数据库参数以及是否输入了正确的func ID")
        exit(1)

    # print(func_name, filepath, ret_type, param_num, param_type)
    try:
        with open(filepath, "r") as f:
            func_code = f.read()

        param_code_tree = CodeGenerator.generate_param_code_tree(param_num, param_type)
        invoke_code = CodeGenerator.generate_invoke_code(param_num, func_name)
        CodeGenerator.generate_instance_code(func_code, param_code_tree, invoke_code, filepath, func_id)
    except Exception as e:
        print(str(e))
        print("生成代码时出错，请检查文件路径")
        exit(1)
