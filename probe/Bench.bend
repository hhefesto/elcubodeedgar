import Base
import ../Cube.bend as C
import ../Solve.bend as V
import ../Fast.bend as F

# Probe: the faster solver on scrambles, each checked.
#
#   bench <tables> <scramble> ..     (a scramble: moves as numbers, "3.10.17")
#
# prints, for each: the scramble's length, the solution and its length, the
# nodes, the milliseconds, and "ok" when the scramble then the solution
# leaves the cube solved.

def bh.count(ms: List<&2, U32>) -> U32:
  match ms:
    case Nil{}:
      0
    case Con{m, t}:
      U32.add(bh.count(t), 1)

def bh.say(+ms: List<&2, U32>, ans: V.Ans, +dt: Nat) -> String:
  match ans:
    case V.Ans{Some{+sol}, k, b}:
      +ok = C.cube.is_solved(C.cube.apply(sol, C.cube.apply(ms, C.cube.solved())))
      U32.show(bh.count(ms)) ++ " moves -> " ++ U32.show(bh.count(sol)) ++ ": " ++ C.cube.show(sol) ++ " | " ++ U32.show(k) ++ " nodes, " ++ Nat.show(dt) ++ " ms, " ++ Bool.pick(String, ok, "ok", "WRONG")
    case V.Ans{None{}, k, b}:
      U32.show(bh.count(ms)) ++ " moves -> none within 20 | " ++ U32.show(k) ++ " nodes, " ++ Nat.show(dt) ++ " ms"

def bh.read(+s: String) -> List<&2, U32>:
  Maybe.default(&2, List<&2, U32>, C.cube.read(s), Nil{})

@unsafe
def bh.one(r: Array<U32> & V.Ans, +ms: List<&2, U32>, +t0: Nat) -> IO(Array<U32>):
  (t, ans) = r
  do IO<Array<U32>>:
    +t1 : Nat <- IO.now()
    IO.print(bh.say(ms, ans, Nat.sub(t1, t0)))
    return t

@unsafe
def bh.all(xs: List<String>, t: Array<U32>) -> IO(Unit):
  match xs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{x, rest}:
      +ms = bh.read(x)
      do IO<Unit>:
        +t0 : Nat <- IO.now()
        t2 : Array<U32> <- bh.one(F.fs.solve(t, ms), ms, t0)
        bh.all(rest, t2)

@unsafe
def bh.main(xs: List<String>) -> IO(Unit):
  match xs:
    case Con{a, Con{path, rest}}:
      do IO<Unit>:
        +t0 : Nat <- IO.now()
        t : Array<U32> <- F.fs.load(path)
        +t1 : Nat <- IO.now()
        IO.print("tables read in " ++ Nat.show(Nat.sub(t1, t0)) ++ " ms")
        bh.all(rest, t)
    case _:
      IO.print("bench <tables> <scramble> ..")

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    bh.main(args)
