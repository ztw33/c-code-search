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
            original_cons, defined_param_index = PCFileParser.parse(filepath, func_sign.get("ret_type"))
            # print("original cons:\n", " ".join(original_cons))
            for match_seq in match_rel:
                query_cons = SMTConverter.query_to_cons(match_seq, func_sign, query_stmt.get("ret_val"), defined_param_index)
                # print("query cons:\n", query_cons)
                constraints = original_cons + query_cons
                # print("constraints:\n", "\n".join(constraints))
                result = SMTSolver.check_sat(constraints)
                if result == sat:
                    match_func_id.append(func_id)
                    break
                elif result == unsat:
                    pass
                elif result == unknown:
                    pass
                else:
                    print("Error: unexpected result from SMTSolver")
            # print("\n")
    
    if len(match_func_id) == 0:
        print("无符合查询条件的函数！")
    else:
        print("func id:", match_func_id)
    

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("参数个数错误")
        exit(1)
    
    query_json_filepath = sys.argv[1]
    with open(query_json_filepath, "r") as f:
        query = json.load(f)
    search(query)
    db_conn.db_close()
