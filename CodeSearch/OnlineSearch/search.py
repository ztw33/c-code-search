# -*- coding: UTF-8 -*-
import sys
# import os
# BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# sys.path.append(BASE_DIR)

from TypeMatch.typeMatch import TypeMatcher
import json
from utils import db_conn
from Convert2SMT.SMTConverter import SMTConverter
from Convert2SMT.PCFileParser import PCFileParser
from CheckSAT.SMTSolver import SMTSolver
from z3 import sat, unsat, unknown
from utils.printUtil import printError
import re

from pprint import PrettyPrinter
pp = PrettyPrinter(indent=4)

def search(query_stmt):
    type_match_result = TypeMatcher.match(query_stmt)
    with open("./Test/type_match.json", "w") as f:
        json.dump(type_match_result, f)
        print("加载入json文件完成...")
    
    match_func_id = []
    for func_id, func_sign in type_match_result.items():
        func_id = int(func_id)
        smt_files_path = db_conn.select_smt_files_by_id(func_id)
        # print(smt_files_path)
        match_rel = func_sign.get("match_rel")  # 匹配关系

        for filepath in smt_files_path:
            dirNameInfix = filepath.split('/')[-2].split('_')[1]
            parse_result = None
            if re.match(r"^[0-9]+\[[0-9]+\]", dirNameInfix) is not None:  # 函数参数中包含数组的
                infix = dirNameInfix.split(',')
                array_param_length = {}
                for inf in infix:
                    match_obj = re.match(r"([0-9]+)\[([0-9]+)\]", inf)
                    param_index = match_obj.group(1)
                    array_length = match_obj.group(2)
                    array_param_length[int(param_index)] = int(array_length)
            else:
                parse_result = PCFileParser.parse(filepath, func_sign.get("ret_type"))

            for match_seq in match_rel:
                if parse_result is None:
                    func_param_type = func_sign.get("param_type")
                    input_param_val = func_sign.get("input_param_val")
                    flag = True
                    for i, f in enumerate(match_seq):
                        if func_param_type[f] == "char*" and array_param_length[f] != len(input_param_val[i]):
                            flag = False
                    if flag is False:
                        continue
                    parse_result = PCFileParser.parse(filepath, func_sign.get("ret_type"))

                constraints = SMTConverter.query_to_cons(match_seq, func_sign, query_stmt.get("ret_val"), parse_result)
                #print("constraints:\n", "\n".join(constraints))
                result = SMTSolver.check_sat(constraints)
                if result == sat:
                    match_func_id.append(func_id)
                    break
                elif result == unsat:
                    pass
                elif result == unknown:
                    pass
                else:
                    printError("unexpected result from SMTSolver")

    
    if len(match_func_id) == 0:
        print("无符合查询条件的函数！")
    else:
        print("func id:", match_func_id)
    

if __name__ == "__main__":
    if len(sys.argv) != 2:
        printError("参数个数错误")
        exit(1)
    
    query_json_filepath = sys.argv[1]
    with open(query_json_filepath, "r") as f:
        query = json.load(f)
    search(query)
    db_conn.db_close()
