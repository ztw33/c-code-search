#!/usr/bin/python
# -*- coding: UTF-8 -*-

import sys
import os
from utils import DBUtil, CodeGenerator
from os.path import dirname, join

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

    try:
        with open(join(dirname(__file__), "template"), "r") as f:
            template = f.read()
        with open(filepath, "r") as f:
            func_code = f.read()

        param_code = CodeGenerator.generate_param_code(param_num, param_type)
        invoke_code = CodeGenerator.generate_invoke_code(param_num, func_name)
        instance_code = template % (func_code, param_code, invoke_code)
        print(instance_code)
        driver_filepath = CodeGenerator.generate_driver_filepath(filepath, func_id)

        with open(driver_filepath, "w") as f:
            f.write(instance_code)
    except:
        print("生成代码时出错，请检查文件路径")
        exit(1)
