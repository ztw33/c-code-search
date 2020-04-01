# -*- coding: UTF-8 -*-
from TypeMatch.dbUtil import DBUtil
import itertools

class TypeMatcher:
    @staticmethod
    def match(query):
        db = DBUtil()
        # 1.选出参数个数>=query中参数个数 & 返回值类型相匹配的作为候选项
        where_cond = "param_num >= {} and ret_type = '{}'".format(query.get("param_num"), query.get("ret_type"))
        candidates = db.select_by_where_cond(where_cond)
        # print(candidates)

        query_param_type = query.get("param_type")
        query_param_num = int(query.get("param_num"))
        type_match = dict()
        for cand in candidates:
            func_param_num = int(cand.get("param_num"))
            fi_list = [i for i in range(0, func_param_num)]
            func_param_type = (cand.get("param_type")).split(",")
            match_rel = []  # 参数匹配关系
            for fi in itertools.permutations(fi_list, query_param_num):
                if TypeMatcher._equal_type(query_param_type, fi, query_param_num, func_param_type):
                    match_rel.append(list(fi))
            if len(match_rel) > 0:
                type_match[cand.get("func_id")] = {
                    "ret_type": query.get("ret_type"),
                    "param_num": func_param_num,
                    "param_type": func_param_type,
                    "match_rel": match_rel,
                    "input_param_val": query.get("param_val")
                }
        return type_match

    @staticmethod
    # query_type, func_type_index
    def _equal_type(q_list, fi_list, param_num, func_param_type):
        for index in range(0, param_num):
            if not q_list[index] == func_param_type[fi_list[index]]:
                if not (q_list[index] == "int" and func_param_type[fi_list[index]] == "double"):
                    return False
        return True
            
