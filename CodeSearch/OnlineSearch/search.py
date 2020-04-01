# -*- coding: UTF-8 -*-
import sys
# import os
# BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# sys.path.append(BASE_DIR)

from TypeMatch.typeMatch import TypeMatcher
import json


def search(query_stmt):
    type_match_result = TypeMatcher.match(query_stmt)
    print(type_match_result)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("参数个数错误")
        exit(1)
    
    query_json_filepath = sys.argv[1]
    with open(query_json_filepath, "r") as f:
        query = json.load(f)
    search(query)
