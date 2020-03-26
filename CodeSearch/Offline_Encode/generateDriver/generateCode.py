#!/usr/bin/python
# -*- coding: UTF-8 -*-

import sys
import mysql.connector

# input = 3
# output = 0
# paramNum = 1


# for i in range(paramNum):
#     pname = "p"+str(i+1)
#     s += "\tint "+pname+";\n"
#     s += "\tklee_make_symbolic(&"+pname+",sizeof("+pname+"),\"?"+pname+"\");\n"
# s += "\tint ret=get_sign(p1);\n\treturn 0;\n}"
# print(s)
# f = open('get_sign_main.c','w')
# f.write(s)
# f.close()

def generate_param_code(param_num, param_type):
    param_type_list = param_type.split(',')
    return ""

def generate_invoke_code(param_num, func_name):
    param = ["p{}".format(str(i)) for i in range(1, param_num+1)]
    param = ",".join(param)
    return "{}({});".format(func_name, param)

if __name__ == "__main__":
    if (len(sys.argv) != 2):
        print("参数个数错误")
        exit()
    funcID = sys.argv[1]

    mydb = mysql.connector.connect(host="localhost", user="root", passwd="19980330", database="CodeQuery")
    cursor = mydb.cursor()
    cursor.execute("SELECT * FROM func_signature where id = " + funcID)
    result = cursor.fetchone()
    print(result)
    func_name, filepath, ret_type, param_num, param_type = result[1], result[2], result[3], result[4], result[5]
    with open("template", "r") as f:
        template = f.read()
    with open(filepath, "r") as f:
        func_code = f.read()

    param_code = generate_param_code(param_num, param_type)
    invoke_code = generate_invoke_code(param_num, func_name)
    instance_code = template % (func_code, param_code, invoke_code)
    print(instance_code)