#!/usr/bin/python
# -*- coding: UTF-8 -*-

import sys
from utils import DBUtil, CodeGenerator
from os.path import dirname, join

if __name__ == "__main__":
    if (len(sys.argv) != 2):
        print("参数个数错误")
        exit()
    func_id = sys.argv[1]

    dbutil = DBUtil()
    func_name, filepath, ret_type, param_num, param_type = dbutil.select_by_id(func_id)
    with open(join(dirname(__file__), "template"), "r") as f:
        template = f.read()
    with open(filepath, "r") as f:
        func_code = f.read()

    param_code = CodeGenerator.generate_param_code(param_num, param_type)
    invoke_code = CodeGenerator.generate_invoke_code(param_num, func_name)
    instance_code = template % (func_code, param_code, invoke_code)
    # print(instance_code)
    temp = filepath.split('.')
    temp.insert(1, "_driver.")
    outputpath = "".join(temp)
    # print(outputpath)
    with open(outputpath, "w") as f:
        f.write(instance_code)
