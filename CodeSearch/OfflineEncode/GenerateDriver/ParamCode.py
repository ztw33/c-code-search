class ParamCode:
    def __init__(self, param_type, index):
        self.param_type = param_type
        self.param_index = index
        self.code = []
        self.child = None
        self.sibling = None
    
    def gen_param_code(self):
        if self.param_type == "int" or self.param_type == "char":
            self.code.append("{type} p{index};".format(type=self.param_type, index=self.param_index))
            self.code.append("klee_make_symbolic(&p{index}, sizeof(p{index}), \"?p{index}\");".format(index=self.param_index))
        elif self.param_type == "char*":
            def _gen_char_array_code(index, length):
                code = []
                code.append("char p{index}[{length}];".format(index=index, length=length))
                code.append("klee_make_symbolic(p{index}, sizeof(p{index}), \"?p{index}\");".format(index=index))
                code.append("p{index}[{len}] = \'\\0\';".format(index=index, len=length-1))
                code.append("for (int i = 0; i < {len}; i++)".format(len=length-1))
                code.append("\tklee_assume(p{index}[i] != \'\\0\');".format(index=index))
                return code
            
            self.code = _gen_char_array_code(self.param_index, 2)
            temp_p = self
            for i in range(3, 7):  # 数组长度2-6
                new_param = ParamCode(self.param_type, self.param_index)
                new_param.code = _gen_char_array_code(self.param_index, i)
                temp_p.sibling = new_param
                temp_p = new_param
            
        else:
            print("暂不支持的数据类型")
            exit(1)

