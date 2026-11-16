import Base
import ../Cube.bend as C

# Probe: whether a solution solves a scramble (both in the wire form,
# "3.10.17"), by Cube.bend, apart from the solver's own check:
#
#   check <scramble> <solution>
#
# prints "solves N" (N its moves) or "DOES NOT SOLVE"

def ck.len(xs: List<&2, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case Con{x, t}:
      U32.add(ck.len(t), 1)

def ck.say(+ms: List<&2, U32>, +sol: List<&2, U32>) -> String:
  Bool.pick(String, C.cube.is_solved(C.cube.apply(sol, C.cube.apply(ms, C.cube.solved()))),
    "solves " ++ U32.show(ck.len(sol)), "DOES NOT SOLVE")

def ck.read(+s: String) -> List<&2, U32>:
  Maybe.default(&2, List<&2, U32>, C.cube.read(s), [99])

def ck.main(xs: List<String>) -> IO(Unit):
  match xs:
    case Con{a, Con{s, Con{z, t}}}:
      IO.print(ck.say(ck.read(s), ck.read(z)))
    case Con{a, Con{s, Nil{}}}:
      IO.print(ck.say(ck.read(s), Nil{}))
    case _:
      IO.print("check <scramble> <solution>")

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    ck.main(args)
