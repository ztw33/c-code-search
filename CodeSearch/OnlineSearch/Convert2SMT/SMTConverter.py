class SMTConverter:
    # 构造SMT assert语句: assert(?p{param_index} == param_val)
    @staticmethod
    def _param_assert(param_index, param_type, param_val):
        if param_type == "int":
            unsigned_val = str(param_val&0xffffffff)
            return "(assert (=  (_ bv{unsigned_val} 32) (concat  (select  ?p{index} (_ bv3 32) ) (concat  (select  ?p{index} (_ bv2 32) ) (concat  (select  ?p{index} (_ bv1 32) ) (select  ?p{index} (_ bv0 32) ) ) ) ) ) )".format(unsigned_val=unsigned_val, index=str(param_index))
        else:
            print("ERROR: 不支持的数据类型{}".format(param_type))

    # 定义一个变量
    @staticmethod
    def define_var(var_name):
        return "(declare-fun {var_name} () (Array (_ BitVec 32) (_ BitVec 8) ) )".format(var_name=var_name)

    @staticmethod
    def ret_assert(ret_type, ret_val, smt_format):
        if ret_type == "int":
            if smt_format:
                return "(assert (=  {ret_smt_val} (concat  (select  ?ret (_ bv3 32) ) (concat  (select  ?ret (_ bv2 32) ) (concat  (select  ?ret (_ bv1 32) ) (select  ?ret (_ bv0 32) ) ) ) ) ) )".format(ret_smt_val=ret_val)
            else:
                return "(assert (=  (_ bv{ret_val} 32) (concat  (select  ?ret (_ bv3 32) ) (concat  (select  ?ret (_ bv2 32) ) (concat  (select  ?ret (_ bv1 32) ) (select  ?ret (_ bv0 32) ) ) ) ) ) )".format(ret_val=ret_val&0xffffffff)
        else:
            print("ERROR: 不支持的数据类型{}".format(ret_type))

    @staticmethod
    def query_to_cons(match_seq, func_sign, query_ret_val, defined_param_index):  # eg. match_seq:[3, 0, 1], 表示用户输入的三个查询值依次对应当前函数的p3,p0,p1
        query_cons = []  # 查询语句转换的约束
        param_type = func_sign.get("param_type")
        input_param_val = func_sign.get("input_param_val")
        for qi, pi in enumerate(match_seq):
            if pi in defined_param_index:
                query_cons.append(SMTConverter._param_assert(pi, param_type[pi], input_param_val[qi]))
        ret_type = func_sign.get("ret_type")
        query_cons.append(SMTConverter.ret_assert(ret_type, query_ret_val, smt_format=False))
        return query_cons
