# -*- coding: UTF-8 -*-

from z3 import Solver
from utils.printUtil import printError
import traceback

class SMTSolver:
    @staticmethod
    def check_sat(constraints):
        solver = Solver()
        try:
            solver.from_string("\n".join(constraints))
            return solver.check()
        except Exception as e:
            print(e)
            printError("solve SMT 时出错\n"+"\n".join(constraints))
