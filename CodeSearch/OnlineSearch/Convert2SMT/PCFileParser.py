import re
from Convert2SMT.SMTConverter import SMTConverter

class PCFileParser:
    '''解析路径约束文件'''
    @staticmethod
    def parse(pc_filepath, pc_ret_type):
        original_cons = []  # 原始smt文件中的约束
        ret_val = ""  # 返回值
        defined_param_index = set()  # 在原始smt文件中定义过的参数下标集合
        with open(pc_filepath, "r") as f:
            for line in f.readlines():
                line = line.strip()
                dec_fun = re.match(r"^\(declare-fun \?p([0-9]+) \(\)", line)
                if dec_fun: # 此句为参数定义
                    param_index = dec_fun.group(1)
                    defined_param_index.add(int(param_index))
                    original_cons.append(line)
                else:
                    ret = re.match(r"^;return value:(.*)\n?", line)
                    if ret:  # 此句为返回值
                        ret_val = ret.group(1)
                        original_cons.append(SMTConverter.define_var("?ret"))
                        original_cons.append(SMTConverter.ret_assert(pc_ret_type, ret_val, smt_format=True))
                    elif len(line) > 0:
                        original_cons.append(line)

        return original_cons, defined_param_index
