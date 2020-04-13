# -*- coding: UTF-8 -*-

from z3 import Solver
from utils.printUtil import printError

class SMTSolver:
    @staticmethod
    def check_sat(constraints):
        solver = Solver()
        try:
            solver.from_string("\n".join(constraints))
            return solver.check()
        except Exception as e:
            printError("solve SMT 时出错")
            printError(str(e))
