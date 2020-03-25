#!/usr/bin/python
# -*- coding: UTF-8 -*-

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
    param = ["p{}".format(str(i)) for i in (1, param_num)]
    param = ",".join(param)
    return "{}({});".format(func_name, param)

if __name__ == "__main__":
    filepath = "../test.c"
    with open("template", "r") as f:
        template = f.read()
    with open(filepath, "r") as f:
        func_code = f.read()
    
    param_num = 2
    param_type = "int,char" 
    param_code = generate_param_code(param_num, param_type)

    func_name = "get_sign"
    invoke_code = generate_invoke_code(param_num, func_name)

    instance_code = template % (func_code, param_code, invoke_code)
    print(instance_code)