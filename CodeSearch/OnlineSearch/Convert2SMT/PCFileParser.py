# -*- coding: UTF-8 -*-

import re
from Convert2SMT.SMTConverter import SMTConverter
from utils.printUtil import printWarning, printError

class PCFileParser:
    
    """解析路径约束文件, 将返回值整合到路径约束语句中.
    Args:
        pc_filepath: 路径约束文件路径.
        pc_ret_type: 返回值类型.
    Returns:
        dict类型. 举例说明:
            {
                "set_stmts": ["(set ..."],  # set-option/set-logic等
                "array_declarations": ["...", "..."],  # 包括?ret的声明
                "assert_stmts": ["..."]  # 整合了?ret的assert语句
                "defined_param_index": [1, 2, ..]  # 在原始smt文件中定义过的参数下标集合
            }
    """
    @staticmethod
    def parse(pc_filepath, pc_ret_type):
        set_stmts = []
        array_declarations = []
        assert_stmt = ""
        defined_param_index = set()  
        with open(pc_filepath, "r") as f:
            for line in f.readlines():
                line = line.strip()
                if line.startswith("(set"):   # (set
                    set_stmts.append(line)
                elif line.startswith("(declare-fun ?p"):  # (declare-fun ?p{i} ()
                    dec_fun = re.match(r"^\(declare-fun \?p([0-9]+) \(\)", line)
                    param_index = dec_fun.group(1)
                    defined_param_index.add(int(param_index))
                    array_declarations.append(line)
                elif line.startswith("(assert"):  # (assert
                    if assert_stmt != "":
                        printWarning("不止一个assert语句!\n语句内容: {}".format(line))
                    else:
                        assert_stmt = line
                elif line.startswith(";return value:"):  # ;return value:
                    ret = re.match(r"^;return value:(.*)\n?", line)
                    ret_val = ret.group(1)
                    array_declarations.append(SMTConverter.define_var("?ret"))

                    if len(ret_val) > 0:
                        # 将返回值整合到assert语句中
                        assert_content, let_stmt = PCFileParser._parse_assert(assert_stmt)
                        if assert_content is None:
                            printError("解析assert语句时出错")
                            return None
                        and_exp = "(and  {origin_assert_content} {ret_equal_exp} )".format(
                            origin_assert_content=assert_content, 
                            ret_equal_exp=SMTConverter.equal_exp("?ret", pc_ret_type, ret_val))
                        if let_stmt is None:
                            assert_stmt = "(assert {exp} )".format(exp=and_exp)
                        else:
                            assert_stmt = "(assert ( {let_stmt} {exp} ) )".format(let_stmt=let_stmt, exp=and_exp)
                    else:
                        printWarning("返回值为空")
                elif len(line) > 0:
                    printWarning("未知类型的SMT语句!\n语句内容: {}".format(line))
                else:
                    pass

        return {
            "set_stmts": set_stmts,
            "array_declarations": array_declarations,
            "assert_stmts": [assert_stmt],
            "defined_param_index": defined_param_index
        }

    """解析assert语句.
    Args:
        assert_stmt: assert语句(assert ... )
    Returns:
        assert_content: 实际assert的内容
        let_stmt: let语句, 若无则返回None
    """
    @staticmethod
    def _parse_assert(assert_stmt):
        assert_match = re.match(r"\(assert (.*) \)", assert_stmt)
        if assert_match is None:
            printError("解析assert语句时检测到assert语句格式错误")
            return None, None
        else:
            assert_exp = assert_match.group(1)
            # print(assert_exp)
            if assert_exp.startswith("("):
                if assert_exp.startswith("(let"):
                    let_LP_index = next_char_index(assert_exp, 3)
                    if assert_exp[let_LP_index] != "(":
                        printError("解析assert语句时下一个不为空的字符不为\"(\"")
                        return None, None
                    let_RP_index = match_parentheses(assert_exp, let_LP_index)
                    if let_RP_index is None:
                        printError("解析assert语句中的let语句时括号不匹配")
                        return None, None

                    let_stmt = assert_exp[1:let_RP_index+1]
                    exp_LP_index = next_char_index(assert_exp, let_RP_index)
                    if assert_exp[exp_LP_index] != "(":
                        printError("解析assert语句时下一个不为空的字符不为\"(\"")
                        return None, None
                    exp_RP_index = match_parentheses(assert_exp, exp_LP_index)
                    if exp_RP_index is None:
                        printError("解析assert语句中的assert表达式时括号不匹配")
                        return None, None

                    assert_content = assert_exp[exp_LP_index:exp_RP_index+1]
                    return assert_content, let_stmt
                else:
                    return assert_exp, None
            else:
                if assert_exp == "true" or assert_stmt == "false":
                    return assert_exp, None
                else:
                    printWarning("解析assert语句时\"(assert \"后出现未知内容")
                    return assert_exp, None
                    
"""括号匹配.
给出字符串及指定的左括号下标, 返回匹配的右括号下标. 若不匹配则返回None.
"""
def match_parentheses(string, LP_index):
    if LP_index is None or LP_index < 0 or string[LP_index] != "(":
        printError("匹配括号时指定的左括号下标有误或其并不为左括号...")
        return None

    unmatched_LP_count = 1  # 还未匹配的左括号数
    i = LP_index + 1
    while unmatched_LP_count > 0 and i < len(string):
        if string[i] == "(":
            unmatched_LP_count += 1
        elif string[i] == ")":
            unmatched_LP_count -= 1
            if unmatched_LP_count == 0:
                return i
        i += 1
 
    return None

"""下一个不为空的字符下标.
"""
def next_char_index(string, index):
    index += 1
    if index >= len(string):
        printError("取下一个不为空的字符下标时越界")
        return None
    while index < len(string):
        if not (string[index] == " " or string[index] == "\n" or string[index] == "\t" or string[index] == "\r"):
            return index
        index += 1
