# -*- coding: UTF-8 -*-
import mysql.connector
from configparser import ConfigParser
    
class DBUtil:
    def __init__(self):
        cfg = ConfigParser()
        cfg.read("../../db.conf")
        self.db_conn = mysql.connector.connect(host=cfg.get("db", "hostname"), 
                                               user=cfg.get("db", "user"), 
                                               passwd=cfg.get("db", "password"),
                                               database=cfg.get("db", "dbname"))
    
    def __exit__(self, exc_type, exc_value, traceback):
        if self.db_conn is not None and self.db_conn.is_connected():
            self.db_conn.close()