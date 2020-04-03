from z3 import Solver

class SMTSolver:
    @staticmethod
    def check_sat(constraints):
        solver = Solver()
        solver.from_string("\n".join(constraints))
        return solver.check()
