# -*- coding: UTF-8 -*-

import mysql.connector
import sys
import os

hostname = "localhost"
user = "root"
password = "19980330"
dbname = "CodeQuery"

def init_conn():
    db_conn = mysql.connector.connect(host=hostname, 
                                        user=user, 
                                        passwd=password,
                                        database=dbname)
    return db_conn

def getFiles(dir, suffix): 
    res = []
    for root, directory, files in os.walk(dir):
        for filename in files:
            name, suf = os.path.splitext(filename)
            if suf == suffix:
                res.append(os.path.join(os.path.abspath(root), filename))
    return res

def db_insert(func_id, filepath):
    cursor = db_conn.cursor()
    sql = "INSERT INTO pc (func_id, smt_filepath) VALUES (%s, %s)"
    val = (func_id, filepath)
    cursor.execute(sql, val)
    db_conn.commit()

if __name__ == "__main__":
    if (len(sys.argv) != 3):
        print("参数个数错误")
        exit(1)
    
    func_id = sys.argv[1]
    smt_dir = sys.argv[2]

    try:
        db_conn = init_conn()
        for file in getFiles(smt_dir, '.smt2'):
            print(file)
            db_insert(func_id, file)
    except:
        print("执行数据库操作时出错，请检查数据库配置是否正确")
        exit(1)
