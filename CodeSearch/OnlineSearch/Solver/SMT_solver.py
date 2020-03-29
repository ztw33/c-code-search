from z3 import Solver
s = Solver()
s.from_file("test.smt2")
print(s.check())