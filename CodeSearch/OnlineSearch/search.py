# -*- coding: UTF-8 -*-
import json
import sys
from TypeMatch.typeMatch import TypeMatcher

def search(query_stmt):
    candidate_func = TypeMatcher.match(query_stmt)

if __name__ == "__main__":
    if (len(sys.argv) != 2):
        print("参数个数错误")
        exit(1)
    
    query_json_filepath = sys.argv[1]
    with open(query_json_filepath, "r") as f:
        query = json.load(f)
    search(query)
