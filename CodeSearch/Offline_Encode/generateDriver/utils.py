import mysql.connector

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
        return result[1], result[2], result[3], result[4], result[5]

class CodeGenerator:
    @staticmethod
    def generate_param_code(param_num, param_type):
        param_type_list = param_type.split(',')
        param_code = ""
        for i, type in enumerate(param_type_list):
            index = i + 1
            if type == "int" or type == "double" or type == "char":
                param_code += "    {type} p{index};\n    klee_make_symbolic(&p{index}, sizeof(p{index}), \"?p{index}\");\n".format(type=type, index=index)
            elif type == "int*":
                pass
            elif type == "double*":
                pass
            elif type == "char*":
                pass
            else:
                print("异常的数据类型！")
                return ""
        return param_code
    
    @staticmethod
    def generate_invoke_code(param_num, func_name):
        param = ["p{}".format(str(i)) for i in range(1, param_num+1)]
        param = ", ".join(param)
        return "{}({});".format(func_name, param)
