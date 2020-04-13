# -*- coding: UTF-8 -*-

from utils.printUtil import printError

class SMTConverter:
    # 构造SMT assert语句: assert(?p{param_index} == param_val)
    @staticmethod
    def _param_assert(param_index, param_type, param_val):
        if param_type == "int":
            smt_val = "(_ bv{} 32)".format(str(param_val&0xffffffff))
            return "(assert {exp} )".format(exp=SMTConverter.equal_exp("?p{}".format(param_index), param_type, smt_val))
        elif param_type == "char":
            smt_val = "(_ bv{} 8)".format(ord(param_val))
            return "(assert {exp} )".format(exp=SMTConverter.equal_exp("?p{}".format(param_index), param_type, smt_val))
        else:
            printError("暂不支持的数据类型{}".format(param_type))

    # 定义一个变量
    @staticmethod
    def define_var(var_name):
        return "(declare-fun {var_name} () (Array (_ BitVec 32) (_ BitVec 8) ) )".format(var_name=var_name)

    @staticmethod
    def ret_assert(ret_type, ret_val, smt_format):
        smt_val = ""
        if smt_format:
            smt_val = ret_val
        else:
            if ret_type == "int":
                smt_val = "(_ bv{val} 32)".format(val=ret_val&0xffffffff)
            elif ret_type == "char":
                smt_val = "(_ bv{val} 8)".format(val=ord(ret_val))
            else:
                printError("暂不支持的数据类型{}".format(ret_type))
        
        return "(assert {exp} )".format(exp=SMTConverter.equal_exp("?ret", ret_type, smt_val))

    
    """构造smt格式的等式 (= {smt_val} {var_name})
    """
    @staticmethod
    def equal_exp(var_name, var_type, smt_val):
        if var_type == "int":
            return "(=  {smt_val} (concat  (select  {var_name} (_ bv3 32) ) (concat  (select  {var_name} (_ bv2 32) ) (concat  (select  {var_name} (_ bv1 32) ) (select  {var_name} (_ bv0 32) ) ) ) ) )".format(smt_val=smt_val, var_name=var_name)
        elif var_type == "char":
            return "(=  {smt_val} (select  {var_name} (_ bv0 32) ) )".format(smt_val=smt_val, var_name=var_name)
        else:
            printError("暂不支持的数据类型{}".format(var_type))

    @staticmethod
    def query_to_cons(match_seq, func_sign, query_ret_val, parse_result):  # eg. match_seq:[3, 0, 1], 表示用户输入的三个查询值依次对应当前函数的p3,p0,p1
        query_decs = []
        query_asserts = []

        param_num = int(func_sign.get("param_num"))
        defined_param_index = parse_result["defined_param_index"]
        for i in range(0, param_num):
            if i not in defined_param_index:  # 将原smt中未定义的变量声明加入约束语句中
                query_decs.append(SMTConverter.define_var("?p{}".format(i)))
        
        param_type = func_sign.get("param_type")
        input_param_val = func_sign.get("input_param_val")
        for qi, pi in enumerate(match_seq):
            query_asserts.append(SMTConverter._param_assert(pi, param_type[pi], input_param_val[qi]))
        ret_type = func_sign.get("ret_type")
        query_asserts.append(SMTConverter.ret_assert(ret_type, query_ret_val, smt_format=False))
        
        constraints = parse_result["set_stmts"] + \
                      parse_result["array_declarations"] + query_decs + \
                      parse_result["assert_stmts"] + query_asserts
        
        return constraints
